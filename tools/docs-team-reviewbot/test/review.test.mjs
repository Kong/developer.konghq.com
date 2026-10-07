import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { reviewPR, extractJson } from "../src/review.mjs";
import { planComments } from "../run.mjs";
import { postComments, toApiComment } from "../src/github.mjs";
import { renderBody } from "../src/render.mjs";

const usage = { input_tokens: 10, output_tokens: 5 };
function fakeClient(responses) {
  const calls = [];
  return {
    calls,
    beta: { messages: { create: async (p) => { calls.push(structuredClone(p)); return responses.shift(); } } },
  };
}
const text = (t, stop = "end_turn") => ({ stop_reason: stop, content: [{ type: "text", text: t }], usage, model: "m" });

test("extractJson tolerates surrounding text", () => {
  assert.deepEqual(extractJson('here: {"a":1} done'), { a: 1 });
  assert.equal(extractJson("no json"), null);
});

test("tool loop: runs tools, returns all results in one user message, echoes assistant content", async () => {
  const root = await mkdtemp(join(tmpdir(), "rb-"));
  await mkdir(join(root, "app"));
  await writeFile(join(root, "app", "a.md"), "hello\n");
  const toolTurn = {
    stop_reason: "tool_use",
    usage,
    content: [
      { type: "thinking", thinking: "", signature: "sig" },
      { type: "tool_use", id: "t1", name: "read_file", input: { path: "app/a.md" } },
      { type: "tool_use", id: "t2", name: "read_file", input: { path: "../nope" } },
    ],
  };
  const client = fakeClient([toolTurn, text('{"findings":[]}')]);
  const r = await reviewPR({ client, system: "s", userContent: "u", repoRoot: root });
  assert.equal(r.status, "ok");
  assert.equal(r.toolCalls, 2);
  const second = client.calls[1].messages;
  assert.deepEqual(second[1].content, toolTurn.content);
  assert.equal(second[2].content.length, 2);
  assert.equal(second[2].content[0].content, "1: hello\n2: ");
  assert.equal(second[2].content[1].is_error, true);
  assert.ok(client.calls[0].tools.every((t) => ["read_file", "grep", "list_dir"].includes(t.name)));
  assert.equal(client.calls[0].tool_choice, undefined);
});

test("refusal and max_tokens end the run without findings", async () => {
  assert.equal((await reviewPR({ client: fakeClient([text("", "refusal")]), system: "s", userContent: "u", repoRoot: "." })).status, "refused");
  assert.equal((await reviewPR({ client: fakeClient([text("", "max_tokens")]), system: "s", userContent: "u", repoRoot: "." })).status, "max_tokens");
});

test("one repair attempt for bad JSON, then give up", async () => {
  const ok = await reviewPR({ client: fakeClient([text("oops"), text('{"findings":[]}')]), system: "s", userContent: "u", repoRoot: "." });
  assert.equal(ok.status, "ok");
  const bad = await reviewPR({ client: fakeClient([text("oops"), text("still no")]), system: "s", userContent: "u", repoRoot: "." });
  assert.equal(bad.status, "bad_json");
});

test("planComments skips fingerprints that were already posted", () => {
  const f = { file: "app/a.md", line: 2, rule: "r", comment: "c", suggestion: "x", tier: "always_flag" };
  const first = planComments([f], new Set(), "abc1234");
  assert.equal(first.comments.length, 1);
  const again = planComments([f], new Set([first.comments[0].fp]), "def5678");
  assert.equal(again.comments.length, 0);
});

test("postComments only ever submits a COMMENT review", async () => {
  const sent = [];
  const realFetch = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    sent.push({ url, body: JSON.parse(init.body) });
    return new Response("{}", { status: 200 });
  };
  try {
    const f = { file: "app/a.md", line: 3, start_line: 2, rule: "r", comment: "c", suggestion: "x" };
    await postComments("tok", "o/r", 7, "abc", [{ path: f.file, line: 3, start_line: 2, body: renderBody(f, "abc") }]);
  } finally {
    globalThis.fetch = realFetch;
  }
  assert.equal(sent.length, 1);
  assert.equal(sent[0].body.event, "COMMENT");
  assert.equal(sent[0].body.comments[0].start_side, "RIGHT");
  assert.ok(!JSON.stringify(sent).includes("APPROVE"));
  assert.ok(!JSON.stringify(sent).includes("REQUEST_CHANGES"));
  assert.deepEqual(toApiComment({ path: "p", line: 5, body: "b" }), { path: "p", line: 5, side: "RIGHT", body: "b" });
});

test("a 422 falls back to individual comments and reports the failures", async () => {
  const realFetch = globalThis.fetch;
  let n = 0;
  globalThis.fetch = async (url) => {
    n++;
    if (url.endsWith("/reviews")) return new Response('{"message":"bad"}', { status: 422 });
    return n === 2 ? new Response("{}", { status: 200 }) : new Response('{"message":"line"}', { status: 422 });
  };
  try {
    const r = await postComments("t", "o/r", 1, "abc", [{ path: "a", line: 1, body: "x" }, { path: "b", line: 2, body: "y" }]);
    assert.equal(r.posted, 1);
    assert.equal(r.failed.length, 1);
  } finally {
    globalThis.fetch = realFetch;
  }
});
