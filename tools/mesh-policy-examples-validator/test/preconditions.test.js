import test from "node:test";
import assert from "node:assert/strict";
import { checkPreconditions } from "../lib/preconditions.js";

const SOURCES = [
  "app/_mesh_policies/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
  "app/_mesh_policies/external-services/examples/zone-egress.yml",
];

test("an empty build fails with a build-first diagnostic", () => {
  const result = checkPreconditions([], SOURCES);
  assert.equal(result.ok, false);
  assert.match(result.message, /build the site for production first/i);
});

test("a partial build names the counts and the missing example", () => {
  const built = [
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  ];
  const result = checkPreconditions(built, SOURCES);
  assert.equal(result.ok, false);
  assert.match(result.message, /Built 1 mesh policy example pages/);
  assert.match(result.message, /found 2 source examples/);
  assert.match(
    result.message,
    /app\/_mesh_policies\/external-services\/examples\/zone-egress\.yml/,
  );
});

test("a complete build passes", () => {
  const built = [
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
    "dist/mesh/policies/external-services/examples/zone-egress/index.html",
  ];
  const result = checkPreconditions(built, SOURCES);
  assert.deepEqual(result, { ok: true });
});
