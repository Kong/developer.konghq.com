import test from "node:test";
import assert from "node:assert/strict";
import { checkPreconditions } from "../lib/preconditions.js";

const SOURCES = [
  "app/_mesh_policies/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
  "app/_mesh_policies/external-services/examples/zone-egress.yml",
];

const BOTH_TREES_SOURCES = [
  ...SOURCES,
  "app/_mesh_policies/v2/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
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

test("a complete build with both URL shapes passes", () => {
  const built = [
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
    "dist/mesh/policies/external-services/examples/zone-egress/index.html",
    "dist/mesh/v2/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  ];
  const result = checkPreconditions(built, BOTH_TREES_SOURCES);
  assert.deepEqual(result, { ok: true });
});

test("a v2 source example with no v2 built page fails", () => {
  const built = [
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
    "dist/mesh/policies/external-services/examples/zone-egress/index.html",
  ];
  const result = checkPreconditions(built, BOTH_TREES_SOURCES);
  assert.equal(result.ok, false);
  assert.match(
    result.message,
    /app\/_mesh_policies\/v2\/meshcircuitbreaker\/examples\/basic-circuit-breaker\.yaml/,
  );
});

test("the totals count both URL shapes", () => {
  const built = [
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
    "dist/mesh/v2/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  ];
  const result = checkPreconditions(built, BOTH_TREES_SOURCES);
  assert.equal(result.ok, false);
  assert.match(result.message, /Built 2 mesh policy example pages/);
  assert.match(result.message, /found 3 source examples/);
});
