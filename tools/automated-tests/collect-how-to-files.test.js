import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import fs from "fs/promises";
import os from "os";
import path from "path";
import { collectHowToFiles } from "./collect-how-to-files.mjs";

const FIXTURES = path.join(import.meta.dirname, "fixtures/how-tos");

let tmpRoot;

before(async () => {
  tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), "collect-how-to-files-"));
  await fs.cp(FIXTURES, path.join(tmpRoot, "app/_how-tos"), {
    recursive: true,
  });
});

after(async () => {
  await fs.rm(tmpRoot, { recursive: true, force: true });
});

test("it returns repo-relative paths for every how-to file", () => {
  const { product, root, files } = collectHowToFiles("event-gateway", {
    repoRoot: tmpRoot,
  });

  assert.equal(product, "event-gateway");
  assert.equal(root, path.join(tmpRoot, "app/_how-tos/event-gateway"));
  assert.deepEqual(files, [
    "../../app/_how-tos/event-gateway/no-permalink.md",
    "../../app/_how-tos/event-gateway/other-product.md",
    "../../app/_how-tos/event-gateway/series-first.md",
    "../../app/_how-tos/event-gateway/series-second.md",
    "../../app/_how-tos/event-gateway/testable.md",
    "../../app/_how-tos/event-gateway/tests-disabled.md",
    "../../app/_how-tos/event-gateway/todo.md",
    "../../app/_how-tos/event-gateway/unpublished.md",
    "../../app/_how-tos/event-gateway/untagged.md",
  ]);
});

test("it excludes frozen version folders", () => {
  const { files } = collectHowToFiles("event-gateway", { repoRoot: tmpRoot });

  assert.equal(
    files.some((file) => file.includes("/v1/")),
    false,
  );
});

test("a nonexistent product folder is an error", () => {
  assert.throws(
    () => collectHowToFiles("nope", { repoRoot: tmpRoot }),
    /No such directory/,
  );
});
