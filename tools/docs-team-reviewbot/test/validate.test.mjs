import { test } from "node:test";
import assert from "node:assert/strict";
import { parseDiff } from "../src/diff.mjs";
import { validateFindings, computeVerdictIfLive } from "../src/validate.mjs";
import { renderBody, fingerprint, parseMarker } from "../src/render.mjs";

const files = parseDiff(`diff --git a/app/a.md b/app/a.md
--- a/app/a.md
+++ b/app/a.md
@@ -1,1 +1,4 @@
 ctx
+one
+two
+three
`);

const base = { file: "app/a.md", line: 2, rule: "r", tier: "always_flag", severity: "should_fix", confidence: 0.9, comment: "c", suggestion: "x" };
const run = (findings, reasoning_checks = []) => validateFindings({ findings, reasoning_checks }, files);
const reasons = (r) => r.dropped.map((d) => d.reason);

test("keeps a valid finding", () => assert.equal(run([base]).kept.length, 1));
test("drops low confidence", () => assert.deepEqual(reasons(run([{ ...base, confidence: 0.79 }])), ["confidence below threshold"]));
test("drops lines that are not added lines", () => {
  assert.deepEqual(reasons(run([{ ...base, line: 1 }])), ["line is not an added line"]);
  assert.deepEqual(reasons(run([{ ...base, line: 99 }])), ["line is not an added line"]);
});
test("drops files outside the diff or not reviewable", () => {
  assert.deepEqual(reasons(run([{ ...base, file: "app/b.md" }])), ["file not in diff"]);
  assert.deepEqual(reasons(run([{ ...base, file: "app/_references/x.md" }])), ["file not reviewable"]);
});
test("requires a suggestion for always_flag and flag_softly", () => {
  assert.equal(run([{ ...base, suggestion: null }]).kept.length, 0);
  assert.equal(run([{ ...base, tier: "flag_softly", suggestion: " " }]).kept.length, 0);
});
test("rejects suggestions that contain a code fence", () => {
  assert.deepEqual(reasons(run([{ ...base, suggestion: "a\n```\nb" }])), ["suggestion contains a code fence"]);
});
test("optional and human_only never carry a suggestion", () => {
  const opt = run([{ ...base, tier: "optional", severity: "optional", suggestion: "x" }]).kept[0];
  assert.equal(opt.suggestion, null);
});
test("human_only needs all four fields", () => {
  const ho = { ...base, tier: "human_only", suggestion: null, what_to_check: "a", why: "b", where_to_verify: "c" };
  assert.equal(run([ho]).kept.length, 0);
  assert.equal(run([{ ...ho, inconsistency: "a.md:2 vs b.md:9" }]).kept.length, 1);
});
test("multi-line range must be all added lines", () => {
  assert.equal(run([{ ...base, start_line: 2, line: 4 }]).kept.length, 1);
  assert.deepEqual(reasons(run([{ ...base, start_line: 1, line: 3 }])), ["range includes unchanged line"]);
});
test("blocking without a confirmed check is downgraded", () => {
  assert.equal(run([{ ...base, severity: "blocking" }]).kept[0].severity, "should_fix");
  const ok = run([{ ...base, severity: "blocking" }], [{ check: "x", files: ["app/a.md"], result: "confirmed" }]);
  assert.equal(ok.kept[0].severity, "blocking");
});
test("caps: 1 human_only, 3 soft+optional, 8 total", () => {
  const ho = (line) => ({ ...base, line, rule: `h${line}`, tier: "human_only", suggestion: null, what_to_check: "a", why: "b", where_to_verify: "c", inconsistency: "d" });
  assert.equal(run([ho(2), ho(3), ho(4)]).kept.length, 1);
  const soft = [2, 3, 4].flatMap((l) => [0, 1].map((i) => ({ ...base, line: l, rule: `s${l}${i}`, tier: "flag_softly", severity: "optional" })));
  assert.equal(run(soft).kept.length, 3);
});
test("duplicates dropped", () => assert.deepEqual(reasons(run([base, base])), ["duplicate"]));
test("verdict_if_live logic", () => {
  assert.equal(computeVerdictIfLive([]), "approve");
  assert.equal(computeVerdictIfLive([{ severity: "blocking", tier: "always_flag" }]), "request_changes");
  assert.equal(computeVerdictIfLive([{ severity: "optional", tier: "human_only", impact: "high" }]), "needs_human");
  assert.equal(computeVerdictIfLive(Array(4).fill({ severity: "should_fix", tier: "always_flag" })), "comment");
});
test("render includes suggestion block and a parseable marker; fingerprint is stable", () => {
  const body = renderBody(base, "abcdef1234");
  assert.match(body, /```suggestion\nx\n```/);
  const m = parseMarker(body);
  assert.equal(m.rule, "r");
  assert.equal(m.fp, fingerprint(base));
  assert.equal(m.run, "abcdef1");
  assert.equal(fingerprint({ ...base, line: 50 }), fingerprint(base)); // line shifts do not change it
});
