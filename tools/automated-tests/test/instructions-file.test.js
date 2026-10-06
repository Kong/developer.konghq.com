import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import {
  testeableUrlsFromFiles,
  selectRunnableGroups,
} from "../instructions-file.js";

const config = {
  baseUrl: "http://localhost:8888",
  productionUrl: "http://localhost:8888",
};

// testeableUrlsFromFiles writes its skipped list to .automated-tests in the
// process cwd. Run each of these tests from a throwaway directory so the
// package's own .automated-tests file survives the suite.
async function inTempDir(fn) {
  const previousCwd = process.cwd();
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "automated-tests-"));
  process.chdir(dir);
  try {
    return await fn(dir);
  } finally {
    process.chdir(previousCwd);
    await fs.rm(dir, { recursive: true, force: true });
  }
}

async function writeHowTo(dir, name, frontmatter, body = "") {
  const file = path.join(dir, name);
  await fs.writeFile(file, `---\n${frontmatter}\n---\n${body}\n`);
  return file;
}

test("an operator how-to with no exclusion is testable", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "operator-dataplane.md",
      ["title: Operator how-to", "products:", "  - operator", "permalink: /operator/how-to/test/"].join(
        "\n",
      ),
    );

    const urls = await testeableUrlsFromFiles(config, [file]);

    assert.deepEqual(urls, ["http://localhost:8888/operator/how-to/test/"]);
  });
});

test("an operator how-to tagged automated_tests=false is skipped", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "operator-skipped.md",
      [
        "title: Skipped operator how-to",
        "products:",
        "  - operator",
        "automated_tests: false",
        "permalink: /operator/how-to/skipped/",
      ].join("\n"),
    );

    const urls = await testeableUrlsFromFiles(config, [file]);

    assert.deepEqual(urls, []);
    const skipped = await fs.readFile(".automated-tests", "utf8");
    assert.match(skipped, /\/operator\/how-to\/skipped\//);
    assert.match(skipped, /operator/);
    assert.match(skipped, /Tagged with automated_tests=false/);
  });
});

test("selectRunnableGroups returns only groups matching both filters", () => {
  const groups = {
    "on-prem": { gateway: ["on-prem/gateway.yaml"], operator: ["on-prem/operator.yaml"] },
    konnect: { gateway: ["konnect/gateway.yaml"], operator: ["konnect/operator.yaml"] },
  };

  const selected = selectRunnableGroups(groups, ["operator"], "on-prem");

  assert.deepEqual(selected, {
    "on-prem": { operator: ["on-prem/operator.yaml"] },
  });
});

test("selectRunnableGroups keeps every deployment model when none is set", () => {
  const groups = {
    "on-prem": { gateway: ["on-prem/gateway.yaml"], operator: ["on-prem/operator.yaml"] },
    konnect: { gateway: ["konnect/gateway.yaml"] },
  };

  const selected = selectRunnableGroups(groups, ["gateway"], undefined);

  assert.deepEqual(selected, {
    "on-prem": { gateway: ["on-prem/gateway.yaml"] },
    konnect: { gateway: ["konnect/gateway.yaml"] },
  });
});

test("selectRunnableGroups returns an empty result the caller can detect when nothing matches", () => {
  const groups = {
    konnect: { gateway: ["konnect/gateway.yaml"] },
  };

  const selected = selectRunnableGroups(groups, ["operator"], "on-prem");

  assert.deepEqual(Object.keys(selected), []);
});
