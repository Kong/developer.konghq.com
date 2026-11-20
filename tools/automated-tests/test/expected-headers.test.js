import test from "node:test";
import assert from "node:assert/strict";

import { expectedHeaderChecks } from "../instructions/expected-headers.js";

// expectedHeaderChecks builds the assertion functions the request
// validations (request-check, konnect-api-request, control_plane_request,
// rate-limit-check) run against a fetch Response. Each expected_headers
// entry comes from the writer-facing YAML of a request block: either
// "Name: value" (assert the value) or a bare "Name" (assert presence).
// The check reads the header through the standard Headers accessor, so
// header-name case never matters.

const response = (headers) => ({ headers: new Headers(headers) });

test("returns no checks when expected_headers is absent", () => {
  assert.deepEqual(expectedHeaderChecks(undefined, "request to /echo"), []);
  assert.deepEqual(expectedHeaderChecks(null, "request to /echo"), []);
  assert.deepEqual(expectedHeaderChecks([], "request to /echo"), []);
});

test("a Name: value entry passes when the response carries that value", () => {
  const [check] = expectedHeaderChecks(
    ["myheader: my-first-plugin"],
    "request to /echo",
  );
  const result = check(response({ myheader: "my-first-plugin" }));

  assert.equal(result.assert, true);
  assert.equal(
    result.message,
    "Expected: request to /echo to have header 'myheader: my-first-plugin', got: 'my-first-plugin'.",
  );
});

test("a Name: value entry fails on a different value", () => {
  const [check] = expectedHeaderChecks(
    ["myheader: my-first-plugin"],
    "request to /echo",
  );
  const result = check(response({ myheader: "my-second-plugin" }));

  assert.equal(result.assert, false);
  assert.match(result.message, /got: 'my-second-plugin'/);
});

test("a Name: value entry fails when the header is absent", () => {
  const [check] = expectedHeaderChecks(["X-Missing: value"], "request to /echo");
  const result = check(response({}));

  assert.equal(result.assert, false);
  assert.match(result.message, /got: 'null'/);
});

test("a bare Name entry passes on presence and fails on absence", () => {
  const [present, absent] = expectedHeaderChecks(
    ["RateLimit-Remaining", "RateLimit-Reset"],
    "request 6",
  );

  assert.equal(present(response({ "ratelimit-remaining": "0" })).assert, true);
  assert.equal(absent(response({ "ratelimit-remaining": "0" })).assert, false);
});

test("header names match case-insensitively", () => {
  const [check] = expectedHeaderChecks(["X-Custom-Header: v"], "request to /echo");
  const result = check(response({ "x-custom-header": "v" }));

  assert.equal(result.assert, true);
});

test("only the first colon splits name from value", () => {
  const [check] = expectedHeaderChecks(
    ["Authorization: Bearer abc.def.ghi"],
    "request to /echo",
  );
  const result = check(response({ Authorization: "Bearer abc.def.ghi" }));

  assert.equal(result.assert, true);
});

test("every entry yields its own check, in order", () => {
  const checks = expectedHeaderChecks(
    ["a-header: 1", "b-header: 2", "c-header"],
    "request to /echo",
  );
  const result = checks.map((check) =>
    check(response({ "a-header": "1", "b-header": "2", "c-header": "x" })).assert,
  );

  assert.deepEqual(result, [true, true, true]);
});
