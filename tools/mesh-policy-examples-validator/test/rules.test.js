import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import { parse } from "yaml";
import Ajv from "ajv";
import { findNullValues, findMarkerFields, checkSchema } from "../lib/rules.js";
import { loadCrds } from "../lib/crds.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../..");
const REAL_CRDS_DIR = path.join(ROOT, "app/assets/mesh/2.14.x/raw/crds");

const WIDGET_SCHEMA = {
  type: "object",
  properties: {
    apiVersion: { type: "string" },
    kind: { type: "string" },
    metadata: { type: "object" },
    spec: {
      type: "object",
      properties: {
        name: { type: "string" },
        replicas: { type: "integer" },
      },
      required: ["name"],
    },
  },
};

function widgetCrds() {
  return new Map([["Widget", { schema: WIDGET_SCHEMA }]]);
}

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

test("a surviving marker field is reported", () => {
  const doc = parse(`
type: MeshMultiZoneService
spec:
  conf:
    _port: 8080
`);
  assert.deepEqual(findMarkerFields(doc), ["/spec/conf/_port"]);
});

test("a document with no marker fields reports no findings", () => {
  const doc = parse(`
type: MeshTimeout
spec:
  targetRef:
    kind: Dataplane
`);
  assert.deepEqual(findMarkerFields(doc), []);
});

test("a field with the wrong type is reported", () => {
  const ajv = new Ajv({ allErrors: true, strict: false });
  const block = {
    panel: "universal",
    value: { type: "Widget", spec: { name: "w", replicas: "not-a-number" } },
  };
  const { findings, hasCoverage } = checkSchema(block, widgetCrds(), ajv);
  assert.equal(hasCoverage, true);
  assert.ok(findings.some((f) => f.pointer === "/replicas"));
});

test("a missing required field is reported", () => {
  const ajv = new Ajv({ allErrors: true, strict: false });
  const block = {
    panel: "universal",
    value: { type: "Widget", spec: {} },
  };
  const { findings } = checkSchema(block, widgetCrds(), ajv);
  assert.ok(findings.some((f) => f.message.includes("name")));
});

test("a field not in the schema is reported", () => {
  const ajv = new Ajv({ allErrors: true, strict: false });
  const block = {
    panel: "universal",
    value: { type: "Widget", spec: { name: "w", extra: "nope" } },
  };
  const { findings } = checkSchema(block, widgetCrds(), ajv);
  assert.ok(findings.some((f) => f.message.includes("extra")));
});

test("an unresolved kind is reported", () => {
  const ajv = new Ajv({ allErrors: true, strict: false });
  const block = {
    panel: "universal",
    value: { type: "Nonexistent", spec: {} },
  };
  const { findings, hasCoverage } = checkSchema(block, widgetCrds(), ajv);
  assert.equal(hasCoverage, false);
  assert.ok(findings.some((f) => f.message.includes("Nonexistent")));
});

test("an ExternalService block reports no schema finding but still reports its null finding", () => {
  const ajv = new Ajv({ allErrors: true, strict: false });
  const crds = loadCrds(REAL_CRDS_DIR);
  const value = {
    apiVersion: "kuma.io/v1alpha1",
    kind: "ExternalService",
    metadata: { name: "example" },
    spec: null,
  };
  const block = { panel: "kubernetes", value };

  const { findings, hasCoverage } = checkSchema(block, crds, ajv);
  assert.deepEqual(findings, []);
  assert.equal(hasCoverage, false);
  assert.deepEqual(findNullValues(value), ["/spec"]);
});
