import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import { resolveRelease, MissingCrdDirectoryError } from "../lib/release.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../..");

test("an override picks a different release's CRD directory", () => {
  const { release, crdsDir } = resolveRelease(ROOT, "2.10");
  assert.equal(release, "2.10");
  assert.equal(crdsDir, path.join(ROOT, "app/assets/mesh/2.10.x/raw/crds"));
});

test("throws a named error when the CRD directory is absent", () => {
  assert.throws(
    () => resolveRelease(ROOT, "999.0"),
    (err) => {
      assert.ok(err instanceof MissingCrdDirectoryError);
      assert.match(err.message, /999\.0/);
      return true;
    },
  );
});
