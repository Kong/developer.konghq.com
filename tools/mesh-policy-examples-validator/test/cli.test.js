import test from "node:test";
import assert from "node:assert/strict";
import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";
import { spawnSync } from "child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const INDEX_JS = path.resolve(__dirname, "../index.js");

const WIDGET_CRD = `
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
spec:
  names:
    kind: Widget
  versions:
    - name: v1
      schema:
        openAPIV3Schema:
          type: object
          properties:
            apiVersion:
              type: string
            kind:
              type: string
            metadata:
              type: object
              x-kubernetes-preserve-unknown-fields: true
            spec:
              type: object
              properties:
                name:
                  type: string
`;

function tabGroup(panels) {
  return `<div data-tab-group="policy-yaml x">${panels}</div>`;
}

function panel(name, codes) {
  return `<div data-panel="${name}">${codes}</div>`;
}

function code(id, text) {
  return `<code id="${id}">${text}</code>`;
}

function fixture(name) {
  return fs.readFileSync(path.join(__dirname, "fixtures", name), "utf-8");
}

const TERRAFORM_AVAILABLE =
  spawnSync("terraform", ["version"], { encoding: "utf-8" }).status === 0;

function builtPage(kubernetesYaml, universalYaml) {
  return tabGroup(
    panel("kubernetes", code("k", kubernetesYaml)) +
      panel("universal", code("u", universalYaml)),
  );
}

// Builds a fixture root laid out like a repo, with the minimal set of files
// the CLI reads: product release data, one vendored CRD per major, and a built
// page paired with its source example for each of the given examples. Pass
// `policies` (an array of `{ policy, examples, skipBuiltPage, major }`)
// instead of `policy`/`examples` to lay out more than one policy;
// `skipBuiltPage` omits the built page for that policy's examples, to
// exercise `--skip`; `major: 2` lays the policy out in the v2 source tree and
// under the /mesh/v2/ URL segment; `crds` names the vendored release
// directories to lay out (pass fewer to leave a major without schemas).
function buildFixtureRoot({
  policy = "widget",
  examples,
  policies,
  crds = ["2.1.x", "3.0.x"],
}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "mesh-policy-cli-"));

  fs.mkdirSync(path.join(root, "app/_data/products"), { recursive: true });
  fs.writeFileSync(
    path.join(root, "app/_data/products/mesh.yml"),
    "releases:\n  - release: '2.1'\n  - release: '3.0'\n    latest: true\n",
  );

  for (const dir of crds) {
    const crdsDir = path.join(root, "app/assets/mesh", dir, "raw/crds");
    fs.mkdirSync(crdsDir, { recursive: true });
    fs.writeFileSync(path.join(crdsDir, "widget.yaml"), WIDGET_CRD);
  }

  const policyList = policies ?? [{ policy, examples, skipBuiltPage: false }];

  for (const {
    policy: policyName,
    examples: policyExamples,
    skipBuiltPage,
    major,
  } of policyList) {
    const versionParts = major === 2 ? ["v2"] : [];
    for (const { name, kubernetesYaml, universalYaml, pageHtml } of policyExamples) {
      const examplesDir = path.join(
        root,
        "app/_mesh_policies",
        ...versionParts,
        policyName,
        "examples",
      );
      fs.mkdirSync(examplesDir, { recursive: true });
      fs.writeFileSync(path.join(examplesDir, `${name}.yaml`), "config: {}\n");

      if (skipBuiltPage) continue;

      const pageDir = path.join(
        root,
        "dist/mesh",
        ...versionParts,
        "policies",
        policyName,
        "examples",
        name,
      );
      fs.mkdirSync(pageDir, { recursive: true });
      fs.writeFileSync(
        path.join(pageDir, "index.html"),
        pageHtml ?? builtPage(kubernetesYaml, universalYaml),
      );
    }
  }

  return root;
}

function runCli(root, extraArgs = []) {
  return spawnSync("node", [INDEX_JS, "--root", root, ...extraArgs], {
    encoding: "utf-8",
  });
}

test("a clean run exits zero and reports pages and blocks checked", () => {
  const root = buildFixtureRoot({
    examples: [
      {
        name: "clean",
        kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
        universalYaml: "type: Widget\nspec:\n  name: ok\n",
      },
    ],
  });

  const result = runCli(root);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 1 pages, 2 blocks/);
  assert.match(result.stdout, /0 finding\(s\)/);
});

test("a failing run exits non-zero and reports the finding and the source file", () => {
  const root = buildFixtureRoot({
    examples: [
      {
        name: "broken",
        kubernetesYaml: "kind: Widget\nspec:\n  name:\n",
        universalYaml: "type: Widget\nspec:\n  name: ok\n",
      },
    ],
  });

  const result = runCli(root);

  assert.equal(result.status, 1);
  assert.match(
    result.stdout,
    /app\/_mesh_policies\/widget\/examples\/broken\.yaml \[kubernetes\] \/spec\/name: value is null/,
  );
  assert.match(result.stdout, /Checked 1 pages, 2 blocks/);
  assert.match(result.stdout, /[1-9]\d* finding\(s\)/);
});

test("--skip excludes a policy with no built page from the precondition check", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    policies: [
      { policy: "widget", examples: [cleanExample], skipBuiltPage: false },
      {
        policy: "broken-policy",
        examples: [cleanExample],
        skipBuiltPage: true,
      },
    ],
  });

  const result = runCli(root, ["--skip", "broken-policy"]);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 1 pages, 2 blocks/);
  assert.match(result.stdout, /Skipped: broken-policy\./);
});

test("--skip accepts a comma-separated list and excludes every named policy", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    policies: [
      { policy: "widget", examples: [cleanExample], skipBuiltPage: false },
      {
        policy: "broken-policy-a",
        examples: [cleanExample],
        skipBuiltPage: true,
      },
      {
        policy: "broken-policy-b",
        examples: [cleanExample],
        skipBuiltPage: true,
      },
    ],
  });

  const result = runCli(root, [
    "--skip",
    "broken-policy-a,broken-policy-b",
  ]);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 1 pages, 2 blocks/);
  assert.match(
    result.stdout,
    /Skipped: broken-policy-a, broken-policy-b\./,
  );
});

test("--skip naming an unmatched policy is a no-op", () => {
  const root = buildFixtureRoot({
    examples: [
      {
        name: "clean",
        kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
        universalYaml: "type: Widget\nspec:\n  name: ok\n",
      },
    ],
  });

  const result = runCli(root, ["--skip", "no-such-policy"]);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 1 pages, 2 blocks/);
  assert.match(result.stdout, /0 finding\(s\)/);
});

test("the run covers built pages of both URL shapes and source examples of both trees", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    policies: [
      { policy: "widget", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample], major: 2 },
    ],
  });

  const result = runCli(root);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 2 pages, 4 blocks/);
  assert.match(result.stdout, /0 finding\(s\)/);
  assert.match(result.stdout, /major 2 -> 2\.1, major 3 -> 3\.0/);
});

test("--skip <policy>@v2 excludes the policy only in the v2 tree", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    policies: [
      { policy: "other", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample], major: 2 },
    ],
  });

  const result = runCli(root, ["--skip", "widget@v2"]);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 2 pages, 4 blocks/);
  assert.match(result.stdout, /Skipped: widget@v2\./);
});

test("--skip <policy>@v3 excludes the policy only in the latest tree", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    policies: [
      { policy: "other", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample], major: 2 },
    ],
  });

  const result = runCli(root, ["--skip", "widget@v3"]);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 2 pages, 4 blocks/);
  assert.match(result.stdout, /Skipped: widget@v3\./);
});

test("--skip without a version qualifier still excludes the policy in both majors", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    policies: [
      { policy: "other", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample], major: 2 },
    ],
  });

  const result = runCli(root, ["--skip", "widget"]);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /Checked 1 pages, 2 blocks/);
  assert.match(result.stdout, /Skipped: widget\./);
});

test("skipping every page of a major avoids resolving that major's release", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    crds: ["3.0.x"],
    policies: [
      { policy: "widget", examples: [cleanExample] },
      { policy: "widget", examples: [cleanExample], major: 2 },
    ],
  });

  const result = runCli(root, ["--skip", "widget@v2"]);

  assert.equal(result.status, 0);
  assert.match(result.stdout, /major 3 -> 3\.0/);
  assert.doesNotMatch(result.stdout, /major 2/);
  assert.match(result.stdout, /Skipped: widget@v2\./);
});

test("an invalid --skip version qualifier exits non-zero with a diagnostic", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    examples: [cleanExample],
  });

  const result = runCli(root, ["--skip", "widget@banana"]);

  assert.equal(result.status, 1);
  assert.match(result.stderr, /Invalid --skip entry "widget@banana"/);
});

test("--version exits non-zero with a diagnostic", () => {
  const cleanExample = {
    name: "clean",
    kubernetesYaml: "kind: Widget\nspec:\n  name: ok\n",
    universalYaml: "type: Widget\nspec:\n  name: ok\n",
  };
  const root = buildFixtureRoot({
    examples: [cleanExample],
  });

  const result = runCli(root, ["--version", "2.1"]);

  assert.equal(result.status, 1);
  assert.match(result.stderr, /--version is no longer supported/);
});

test(
  "a valid terraform panel is extracted as raw text and receives no schema, empty-value, marker, or YAML finding",
  { skip: !TERRAFORM_AVAILABLE },
  () => {
    const root = buildFixtureRoot({
      examples: [
        { name: "terraform-valid", pageHtml: fixture("terraform-valid.html") },
      ],
    });

    const result = runCli(root);

    assert.equal(result.status, 0);
    assert.match(result.stdout, /Checked 1 pages, 2 blocks/);
    assert.match(result.stdout, /1 terraform block\(s\)/);
    assert.match(result.stdout, /0 finding\(s\)/);
    assert.doesNotMatch(result.stdout, /\[terraform\]/);
  },
);

test(
  "a terraform panel with the empty-key defect reports a gating finding naming the source example file",
  { skip: !TERRAFORM_AVAILABLE },
  () => {
    const root = buildFixtureRoot({
      examples: [
        { name: "terraform-broken", pageHtml: fixture("terraform-invalid.html") },
      ],
    });

    const result = runCli(root);

    assert.equal(result.status, 1);
    assert.match(
      result.stdout,
      /app\/_mesh_policies\/widget\/examples\/terraform-broken\.yaml \[terraform\]/,
    );
    assert.match(result.stdout, /terraform fmt/);
    assert.match(result.stdout, /[1-9]\d* finding\(s\)/);
  },
);
