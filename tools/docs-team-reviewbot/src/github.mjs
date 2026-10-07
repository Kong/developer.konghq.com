// Minimal GitHub REST client (fetch). Only ever creates COMMENT reviews.
const API = "https://api.github.com";

async function gh(token, method, path, body) {
  for (let attempt = 0; attempt < 2; attempt++) {
    const res = await fetch(API + path, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "docs-team-reviewbot",
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(30_000),
    });
    if (res.status >= 500 && attempt === 0) continue;
    const text = await res.text();
    const json = text ? JSON.parse(text) : null;
    if (!res.ok) {
      const err = new Error(`GitHub ${method} ${path} -> ${res.status}: ${json?.message ?? text.slice(0, 200)}`);
      err.status = res.status;
      throw err;
    }
    return json;
  }
}

export const getPR = (token, repo, n) => gh(token, "GET", `/repos/${repo}/pulls/${n}`);

export async function listReviewComments(token, repo, n) {
  const all = [];
  for (let page = 1; page <= 10; page++) {
    const batch = await gh(token, "GET", `/repos/${repo}/pulls/${n}/comments?per_page=100&page=${page}`);
    all.push(...batch);
    if (batch.length < 100) break;
  }
  return all;
}

export function toApiComment(c) {
  const out = { path: c.path, line: c.line, side: "RIGHT", body: c.body };
  if (c.start_line != null && c.start_line < c.line) {
    out.start_line = c.start_line;
    out.start_side = "RIGHT";
  }
  return out;
}

// Always event COMMENT: the bot never approves or requests changes.
export async function postComments(token, repo, n, headSha, comments) {
  const review = {
    commit_id: headSha,
    event: "COMMENT",
    body: "docs-team-reviewbot: advisory suggestions only. This is not an approval or a request for changes.",
    comments: comments.map(toApiComment),
  };
  try {
    await gh(token, "POST", `/repos/${repo}/pulls/${n}/reviews`, review);
    return { posted: comments.length, failed: [] };
  } catch (e) {
    if (e.status !== 422) throw e;
  }
  // One bad anchor rejects the whole review: fall back to one comment each.
  let posted = 0;
  const failed = [];
  for (const c of comments) {
    try {
      await gh(token, "POST", `/repos/${repo}/pulls/${n}/comments`, { ...toApiComment(c), commit_id: headSha });
      posted++;
    } catch (e) {
      failed.push({ path: c.path, line: c.line, error: String(e.message).slice(0, 200) });
    }
  }
  return { posted, failed };
}
