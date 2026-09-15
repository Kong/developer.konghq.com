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

function builtPage(kubernetesYaml, universalYaml) {
  return tabGroup(
    panel("kubernetes", code("k", kubernetesYaml)) +
      panel("universal", code("u", universalYaml)),
  );
}

// Builds a fixture root laid out like a repo, with the minimal set of files
// the CLI reads: product release data, one vendored CRD, and a built page
// paired with its source example for each of the given examples.
function buildFixtureRoot({ policy = "widget", examples }) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "mesh-policy-cli-"));

  fs.mkdirSync(path.join(root, "app/_data/products"), { recursive: true });
  fs.writeFileSync(
    path.join(root, "app/_data/products/mesh.yml"),
    "releases:\n  - release: '1.0'\n    latest: true\n",
  );

  const crdsDir = path.join(root, "app/assets/mesh/1.0.x/raw/crds");
  fs.mkdirSync(crdsDir, { recursive: true });
  fs.writeFileSync(path.join(crdsDir, "widget.yaml"), WIDGET_CRD);

  for (const { name, kubernetesYaml, universalYaml } of examples) {
    const examplesDir = path.join(root, "app/_mesh_policies", policy, "examples");
    fs.mkdirSync(examplesDir, { recursive: true });
    fs.writeFileSync(path.join(examplesDir, `${name}.yaml`), "config: {}\n");

    const pageDir = path.join(root, "dist/mesh/policies", policy, "examples", name);
    fs.mkdirSync(pageDir, { recursive: true });
    fs.writeFileSync(
      path.join(pageDir, "index.html"),
      builtPage(kubernetesYaml, universalYaml),
    );
  }

  return root;
}

function runCli(root) {
  return spawnSync("node", [INDEX_JS, "--root", root], { encoding: "utf-8" });
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
