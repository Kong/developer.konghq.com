import { test } from "node:test";
import assert from "node:assert/strict";
import { parseDiff, annotate } from "../src/diff.mjs";
import { isReviewable } from "../src/config.mjs";

const PATCH = `diff --git a/app/a.md b/app/a.md
index 1..2 100644
--- a/app/a.md
+++ b/app/a.md
@@ -1,3 +1,4 @@
 line one
-old two
+new two
+added three
 line four
\\ No newline at end of file
diff --git a/app/gone.md b/app/gone.md
deleted file mode 100644
--- a/app/gone.md
+++ /dev/null
@@ -1,1 +0,0 @@
-bye
`;

test("added lines use new-file numbering", () => {
  const f = parseDiff(PATCH);
  assert.deepEqual([...f.get("app/a.md").added], [2, 3]);
  assert.equal(f.has("app/gone.md"), false);
});

test("annotate prefixes new-file line numbers", () => {
  const out = annotate(parseDiff(PATCH), ["app/a.md"]);
  assert.match(out, /L2: \+ new two/);
  assert.match(out, /L4:   line four/);
  assert.match(out, /^ {5}- old two/m);
});

test("reviewable path rules", () => {
  assert.equal(isReviewable("app/_how-tos/x.md"), true);
  assert.equal(isReviewable("app/_landing_pages/a.yaml"), true);
  assert.equal(isReviewable("app/_kong_plugins/cors/examples/x.yaml"), true);
  assert.equal(isReviewable("app/_kong_plugins/cors/schema.json"), false);
  assert.equal(isReviewable("app/_references/x.md"), false);
  assert.equal(isReviewable("app/_support/x.md"), false);
  assert.equal(isReviewable("app/_changelogs/x.md"), false);
  assert.equal(isReviewable("tools/x.md"), false);
});
