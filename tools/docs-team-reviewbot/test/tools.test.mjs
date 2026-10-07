import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, symlink, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { execFileSync } from "node:child_process";
import { runTool, cleanEnv } from "../src/tools.mjs";

let root;
before(async () => {
  root = await mkdtemp(join(tmpdir(), "rb-"));
  await mkdir(join(root, "app"));
  await mkdir(join(root, "secrets"));
  await writeFile(join(root, "app", "a.md"), "alpha\nbeta needle\ngamma\n");
  await writeFile(join(root, "secrets", "s.txt"), "top secret");
  await writeFile(join(root, "app", ".env"), "KEY=1");
  await symlink(join(root, "secrets", "s.txt"), join(root, "app", "link.md"));
  execFileSync("git", ["init", "-q"], { cwd: root });
  execFileSync("git", ["add", "-A"], { cwd: root });
});
after(() => rm(root, { recursive: true, force: true }));

test("read_file returns numbered lines and honours ranges", async () => {
  assert.match(await runTool(root, "read_file", { path: "app/a.md" }), /2: beta needle/);
  assert.equal(await runTool(root, "read_file", { path: "app/a.md", start_line: 3, end_line: 3 }), "3: gamma");
});
test("blocks traversal, other roots, symlink escapes, dotenv, null bytes", async () => {
  for (const p of ["../etc/passwd", "app/../secrets/s.txt", "secrets/s.txt", "app/link.md", "app/.env", "/etc/passwd", "app/a.md\0"]) {
    await assert.rejects(runTool(root, "read_file", { path: p }), undefined, p);
  }
});
test("grep finds matches, passes the pattern as data, and does not run a shell", async () => {
  assert.match(await runTool(root, "grep", { pattern: "needle" }), /app\/a\.md:2:/);
  assert.equal(await runTool(root, "grep", { pattern: "$(touch /tmp/pwned)" }), "(no matches)");
  await assert.rejects(runTool(root, "grep", { pattern: "x", path: "secrets" }));
});
test("child processes get no secrets in their environment", () => {
  process.env.ANTHROPIC_API_KEY = "sk-test";
  process.env.GITHUB_TOKEN = "ghs_test";
  process.env.POST_TOKEN = "ghs_post";
  assert.deepEqual(Object.keys(cleanEnv()).sort(), ["HOME", "LC_ALL", "PATH"]);
});
test("list_dir works inside roots only", async () => {
  assert.match(await runTool(root, "list_dir", { path: "app" }), /a\.md/);
  await assert.rejects(runTool(root, "list_dir", { path: "." }));
});
