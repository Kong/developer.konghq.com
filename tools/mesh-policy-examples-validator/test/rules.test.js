import test from "node:test";
import assert from "node:assert/strict";
import { parse } from "yaml";
import { findNullValues } from "../lib/rules.js";

test("a mis-indented nested block reports the empty key", () => {
  const doc = parse(`
type: MeshTimeout
spec:
  rules:
    - default:
      idleTimeout: 60s
`);
  const findings = findNullValues(doc);
  assert.deepEqual(findings, ["/spec/rules/0/default"]);
});

test("an empty top-level spec reports its own pointer", () => {
  const doc = parse(`
type: ExternalService
spec:
`);
  const findings = findNullValues(doc);
  assert.deepEqual(findings, ["/spec"]);
});

test("a document with no empty keys reports no findings", () => {
  const doc = parse(`
type: MeshTimeout
spec:
  targetRef:
    kind: Dataplane
`);
  assert.deepEqual(findNullValues(doc), []);
});
