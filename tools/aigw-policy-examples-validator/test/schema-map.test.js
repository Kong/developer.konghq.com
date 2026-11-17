import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import { buildSchemaMap, schemaForFolder } from "../index.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const FIXTURE_SCHEMAS = path.join(__dirname, "fixtures", "schemas");

test("resolves a policy folder slug to its schema, dash-stripped and case-insensitive", () => {
  const map = buildSchemaMap(FIXTURE_SCHEMAS);

  const { schemaPath } = schemaForFolder(map, "ai-sanitizer");

  assert.equal(schemaPath, path.join(FIXTURE_SCHEMAS, "AiSanitizer.json"));
});

test("a policy folder with no schema yields a finding naming the folder and the expected location", () => {
  const map = buildSchemaMap(FIXTURE_SCHEMAS);

  const result = schemaForFolder(map, "ai-no-schema");

  assert.ok(result.findings, "expected a finding");
  assert.equal(result.findings.length, 1);
  assert.match(result.findings[0].message, /ai-no-schema/);
  assert.match(result.findings[0].message, new RegExp(FIXTURE_SCHEMAS));
});
