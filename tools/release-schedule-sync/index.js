import { execFileSync } from "child_process";

// Keeps the "Release Schedule" view on the Dev site sprints project in sync
// with the repo's milestones. Every open milestone with a due date gets one
// draft item titled "Release: <milestone>" with the Release date field set to
// the due date. Items whose milestone is closed, deleted, or has no due date
// are archived.
//
// Items are matched to milestones by the milestone link in their description,
// so renaming a milestone updates the existing item. Draft items without a
// milestone link are left alone.

const OWNER = process.env.OWNER || "Kong";
const REPO = process.env.REPO || "developer.konghq.com";
const PROJECT_NUMBER = Number(process.env.PROJECT_NUMBER || 59);
const DATE_FIELD = process.env.DATE_FIELD || "Release date";
const DRY_RUN = process.argv.includes("--dry-run") || process.env.DRY_RUN === "1";

const MILESTONE_URL = `https://github.com/${OWNER}/${REPO}/milestone`;
const MILESTONE_LINK = new RegExp(`${MILESTONE_URL}/(\\d+)`);

function getToken() {
  if (process.env.GH_TOKEN) return process.env.GH_TOKEN;
  // Local runs fall back to the gh CLI login.
  return execFileSync("gh", ["auth", "token"], { encoding: "utf8" }).trim();
}

const TOKEN = getToken();

async function request(url, options = {}) {
  const res = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      Accept: "application/vnd.github+json",
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) {
    throw new Error(`${res.status} ${res.statusText} from ${url}: ${await res.text()}`);
  }
  return res;
}

async function graphql(query, variables = {}) {
  const res = await request("https://api.github.com/graphql", {
    method: "POST",
    body: JSON.stringify({ query, variables }),
  });
  const json = await res.json();
  if (json.errors) {
    throw new Error(json.errors.map((e) => e.message).join("\n"));
  }
  return json.data;
}

async function getProject() {
  const data = await graphql(
    `query($owner: String!, $number: Int!, $field: String!) {
      organization(login: $owner) {
        projectV2(number: $number) {
          id
          field(name: $field) { ... on ProjectV2Field { id } }
        }
      }
    }`,
    { owner: OWNER, number: PROJECT_NUMBER, field: DATE_FIELD },
  );
  const project = data.organization.projectV2;
  if (!project?.field?.id) {
    throw new Error(`Field "${DATE_FIELD}" not found on project ${PROJECT_NUMBER}`);
  }
  return { projectId: project.id, fieldId: project.field.id };
}

async function getMilestones() {
  const milestones = [];
  for (let page = 1; ; page++) {
    const res = await request(
      `https://api.github.com/repos/${OWNER}/${REPO}/milestones?state=open&per_page=100&page=${page}`,
    );
    const batch = await res.json();
    milestones.push(...batch);
    if (batch.length < 100) break;
  }
  return milestones
    .filter((m) => m.due_on)
    .map((m) => ({ number: String(m.number), title: m.title, due: m.due_on.slice(0, 10) }));
}

async function getReleaseItems() {
  const items = [];
  let cursor = null;
  do {
    const data = await graphql(
      `query($owner: String!, $number: Int!, $field: String!, $cursor: String) {
        organization(login: $owner) {
          projectV2(number: $number) {
            items(first: 100, after: $cursor) {
              pageInfo { hasNextPage endCursor }
              nodes {
                id
                type
                date: fieldValueByName(name: $field) {
                  ... on ProjectV2ItemFieldDateValue { date }
                }
                content { ... on DraftIssue { id title body } }
              }
            }
          }
        }
      }`,
      { owner: OWNER, number: PROJECT_NUMBER, field: DATE_FIELD, cursor },
    );
    const page = data.organization.projectV2.items;
    for (const node of page.nodes) {
      if (node.type !== "DRAFT_ISSUE") continue;
      const match = (node.content.body || "").match(MILESTONE_LINK);
      if (!match) continue;
      items.push({
        milestone: match[1],
        itemId: node.id,
        draftId: node.content.id,
        title: node.content.title,
        date: node.date?.date || "",
      });
    }
    cursor = page.pageInfo.hasNextPage ? page.pageInfo.endCursor : null;
  } while (cursor);
  return items;
}

function bodyFor(milestone) {
  return `Release marker for milestone [${milestone.title}](${MILESTONE_URL}/${milestone.number}). Due ${milestone.due}.`;
}

async function main() {
  const { projectId, fieldId } = await getProject();
  const [milestones, items] = await Promise.all([getMilestones(), getReleaseItems()]);
  const itemsByMilestone = new Map(items.map((i) => [i.milestone, i]));
  let changes = 0;

  // Logs the change, and applies it unless this is a dry run.
  async function change(message, apply) {
    changes++;
    console.log(message);
    if (DRY_RUN) {
      console.log("  (dry run, skipped)");
      return;
    }
    await apply();
  }

  const setDate = (itemId, date) =>
    graphql(
      `mutation($project: ID!, $item: ID!, $field: ID!, $date: Date!) {
        updateProjectV2ItemFieldValue(input: { projectId: $project, itemId: $item, fieldId: $field, value: { date: $date } }) {
          projectV2Item { id }
        }
      }`,
      { project: projectId, item: itemId, field: fieldId, date },
    );

  for (const milestone of milestones) {
    const title = `Release: ${milestone.title}`;
    const item = itemsByMilestone.get(milestone.number);

    if (!item) {
      await change(`Create: ${title} (${milestone.due})`, async () => {
        const data = await graphql(
          `mutation($project: ID!, $title: String!, $body: String!) {
            addProjectV2DraftIssue(input: { projectId: $project, title: $title, body: $body }) {
              projectItem { id }
            }
          }`,
          { project: projectId, title, body: bodyFor(milestone) },
        );
        await setDate(data.addProjectV2DraftIssue.projectItem.id, milestone.due);
      });
      continue;
    }

    if (item.title !== title) {
      await change(`Rename: ${item.title} -> ${title}`, () =>
        graphql(
          `mutation($draft: ID!, $title: String!, $body: String!) {
            updateProjectV2DraftIssue(input: { draftIssueId: $draft, title: $title, body: $body }) {
              draftIssue { id }
            }
          }`,
          { draft: item.draftId, title, body: bodyFor(milestone) },
        ),
      );
    }

    if (item.date !== milestone.due) {
      await change(`Move: ${title} ${item.date || "unset"} -> ${milestone.due}`, () =>
        setDate(item.itemId, milestone.due),
      );
    }
  }

  const open = new Set(milestones.map((m) => m.number));
  for (const item of items) {
    if (open.has(item.milestone)) continue;
    await change(
      `Archive: ${item.title} (milestone ${item.milestone} is closed, deleted, or has no due date)`,
      () =>
        graphql(
          `mutation($project: ID!, $item: ID!) {
            archiveProjectV2Item(input: { projectId: $project, itemId: $item }) { item { id } }
          }`,
          { project: projectId, item: item.itemId },
        ),
    );
  }

  console.log(`Done. ${changes} change(s)${DRY_RUN ? ", dry run" : ""}.`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
