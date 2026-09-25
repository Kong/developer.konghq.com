import test from "node:test";
import assert from "node:assert/strict";
import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";
import { resolveRelease, MissingCrdDirectoryError } from "../lib/release.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../..");

test("major 3 resolves the biggest 3.x release and its label names the CRD directory", () => {
  const { release, crdsDir } = resolveRelease(ROOT, 3);
  assert.equal(release, "3.0");
  assert.equal(crdsDir, path.join(ROOT, "app/assets/mesh/dev/raw/crds"));
});

test("major 2 resolves the biggest 2.x release", () => {
  const { release, crdsDir } = resolveRelease(ROOT, 2);
  assert.equal(release, "2.14");
  assert.equal(crdsDir, path.join(ROOT, "app/assets/mesh/2.14.x/raw/crds"));
});

test("a release entry without a label falls back to the <release>.x directory", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "mesh-policy-release-"));
  fs.mkdirSync(path.join(root, "app/_data/products"), { recursive: true });
  fs.writeFileSync(
    path.join(root, "app/_data/products/mesh.yml"),
    "releases:\n  - release: '4.0'\n    latest: true\n",
  );
  fs.mkdirSync(path.join(root, "app/assets/mesh/4.0.x/raw/crds"), {
    recursive: true,
  });

  const { release, crdsDir } = resolveRelease(root, 4);
  assert.equal(release, "4.0");
  assert.equal(crdsDir, path.join(root, "app/assets/mesh/4.0.x/raw/crds"));
});

test("a release with no vendored schemas raises the missing-CRD error", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "mesh-policy-release-"));
  fs.mkdirSync(path.join(root, "app/_data/products"), { recursive: true });
  fs.writeFileSync(
    path.join(root, "app/_data/products/mesh.yml"),
    "releases:\n  - release: '2.1'\n",
  );

  assert.throws(
    () => resolveRelease(root, 2),
    (err) => {
      assert.ok(err instanceof MissingCrdDirectoryError);
      assert.match(err.message, /2\.1/);
      assert.match(err.message, /app\/assets\/mesh\/2\.1\.x\/raw\/crds/);
      return true;
    },
  );
});

test("a major with no release in mesh.yml raises a diagnostic", () => {
  assert.throws(
    () => resolveRelease(ROOT, 999),
    /No release for mesh major 999/,
  );
});
