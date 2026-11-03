import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { buildSchemaMap, validateFile } from "../index.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const FIXTURES = path.join(__dirname, "fixtures");
const EXAMPLES = path.join(FIXTURES, "app/_ai_gateway_policies/ai-sanitizer/examples");
const ORPHAN_EXAMPLES = path.join(FIXTURES, "app/_ai_gateway_policies/ai-no-schema/examples");

function context() {
  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  return {
    schemaMap: buildSchemaMap(path.join(FIXTURES, "schemas")),
    ajv,
    compiled: new Map(),
  };
}

test("a valid example yields no findings", () => {
  const result = validateFile(path.join(EXAMPLES, "valid.yml"), context());

  assert.deepEqual(result, []);
});

test("a config that is not an object yields a finding naming the file", () => {
  const file = path.join(EXAMPLES, "non-object-config.yml");

  const result = validateFile(file, context());

  assert.equal(result.length, 1);
  assert.equal(result[0].file, file);
  assert.equal(result[0].errors.length, 1);
  assert.equal(result[0].errors[0].instancePath, "/config");
  assert.match(result[0].errors[0].message, /config.*object/);
});

test("a type that differs from the policy folder yields a finding naming file, type, and folder", () => {
  const file = path.join(EXAMPLES, "bad-type.yml");

  const result = validateFile(file, context());

  assert.equal(result.length, 1);
  assert.equal(result[0].file, file);
  assert.equal(result[0].errors.length, 1);
  assert.equal(result[0].errors[0].instancePath, "/type");
  assert.match(result[0].errors[0].message, /ai-semantic-cache/);
  assert.match(result[0].errors[0].message, /ai-sanitizer/);
});

test("a misspelled config key yields a finding naming the file and the key", () => {
  const file = path.join(EXAMPLES, "misspelled-key.yml");

  const result = validateFile(file, context());

  assert.equal(result.length, 1);
  assert.equal(result[0].file, file);
  const unknownKey = result[0].errors.find(
    (error) => error.params && error.params.additionalProperty === "tresholds",
  );
  assert.ok(unknownKey, "expected an unknown-key finding for tresholds");
  assert.equal(unknownKey.instancePath, "");
});

test("every finding error carries an instancePath", () => {
  const files = [
    path.join(EXAMPLES, "non-object-config.yml"),
    path.join(EXAMPLES, "bad-type.yml"),
    path.join(EXAMPLES, "misspelled-key.yml"),
  ];

  for (const file of files) {
    const result = validateFile(file, context());
    for (const finding of result) {
      for (const error of finding.errors) {
        assert.ok("instancePath" in error, `finding in ${file} lacks instancePath`);
      }
    }
  }
});

test("a policy folder with no schema yields a finding naming the folder", () => {
  const file = path.join(ORPHAN_EXAMPLES, "orphan.yml");

  const result = validateFile(file, context());

  assert.equal(result.length, 1);
  assert.equal(result[0].file, file);
  assert.match(result[0].errors[0].message, /ai-no-schema/);
});
