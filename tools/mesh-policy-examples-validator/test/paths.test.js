import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import { builtPageToSourcePath } from "../lib/paths.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../..");
const FIXTURE_ROOT = path.resolve(__dirname, "fixtures/paths-root");

test("maps a built page to a .yaml source", () => {
  const source = builtPageToSourcePath(
    ROOT,
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  );
  assert.equal(
    source,
    path.join(
      ROOT,
      "app/_mesh_policies/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
    ),
  );
});

test("maps a v2 built page to a .yml source (external-services)", () => {
  const source = builtPageToSourcePath(
    ROOT,
    "dist/mesh/v2/policies/external-services/examples/zone-egress/index.html",
  );
  assert.equal(
    source,
    path.join(
      ROOT,
      "app/_mesh_policies/v2/external-services/examples/zone-egress.yml",
    ),
  );
});

test("maps a v2 built page to the v2 source tree", () => {
  const source = builtPageToSourcePath(
    FIXTURE_ROOT,
    "dist/mesh/v2/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  );
  assert.equal(
    source,
    path.join(
      FIXTURE_ROOT,
      "app/_mesh_policies/v2/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
    ),
  );
});

test("maps a v2 built page to a .yml source (external-services)", () => {
  const source = builtPageToSourcePath(
    FIXTURE_ROOT,
    "dist/mesh/v2/policies/external-services/examples/zone-egress/index.html",
  );
  assert.equal(
    source,
    path.join(
      FIXTURE_ROOT,
      "app/_mesh_policies/v2/external-services/examples/zone-egress.yml",
    ),
  );
});

test("maps an unversioned built page against the fixture root", () => {
  const source = builtPageToSourcePath(
    FIXTURE_ROOT,
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  );
  assert.equal(
    source,
    path.join(
      FIXTURE_ROOT,
      "app/_mesh_policies/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
    ),
  );
});
