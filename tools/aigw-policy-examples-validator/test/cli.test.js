import test from "node:test";
import assert from "node:assert/strict";
import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";
import { spawnSync } from "child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const INDEX_JS = path.resolve(__dirname, "../index.js");

const SCHEMA = {
  properties: {
    config: {
      type: "object",
      properties: {
        rejection_mode: { type: "string" },
      },
    },
  },
};

// Builds a fixture root laid out like the repo, with one schema and the given
// example files under one policy folder.
function buildFixtureRoot({ slug = "ai-sanitizer", examples }) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "aigw-policy-cli-"));

  const schemasDir = path.join(root, "app/_schemas/ai-gateway/policies");
  fs.mkdirSync(schemasDir, { recursive: true });
  fs.writeFileSync(
    path.join(schemasDir, "AiSanitizer.json"),
    JSON.stringify(SCHEMA),
  );

  const examplesDir = path.join(
    root,
    "app/_ai_gateway_policies",
    slug,
    "examples",
  );
  fs.mkdirSync(examplesDir, { recursive: true });
  for (const { name, config } of examples) {
    fs.writeFileSync(
      path.join(examplesDir, `${name}.yml`),
      `title: ${name}\ntype: ${slug}\nconfig:\n${config}`,
    );
  }

  return root;
}

function runCli(root) {
  return spawnSync("node", [INDEX_JS, "--root", root], { encoding: "utf-8" });
}

test("exits zero over valid fixtures", () => {
  const root = buildFixtureRoot({
    examples: [
      { name: "clean", config: "  rejection_mode: return_error\n" },
    ],
  });

  const result = runCli(root);

  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /1 example file/);
});

test("exits one and names the invalid file and key in the output", () => {
  const root = buildFixtureRoot({
    examples: [
      { name: "clean", config: "  rejection_mode: return_error\n" },
      { name: "broken", config: "  tresholds: 90\n" },
    ],
  });

  const result = runCli(root);

  assert.equal(result.status, 1);
  assert.match(result.stdout, /broken\.yml/);
  assert.match(result.stdout, /tresholds/);
});
