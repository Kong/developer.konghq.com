import test from "node:test";
import assert from "node:assert/strict";
import { placeholderForSchema, replaceVariables } from "../index.js";

test("a ${...} variable takes the schema's example first", () => {
  const schema = {
    type: "string",
    example: "example-value",
    default: "default-value",
    enum: ["enum-value"],
  };

  assert.equal(placeholderForSchema(schema), "example-value");
});

test("a ${...} variable falls back to the schema's default", () => {
  const schema = { type: "integer", default: 42 };

  assert.equal(placeholderForSchema(schema), 42);
});

test("a ${...} variable falls back to the first enum value", () => {
  const schema = { type: "string", enum: ["second", "first"] };

  assert.equal(placeholderForSchema(schema), "second");
});

test("a ${...} variable falls back to a placeholder that matches the type", () => {
  assert.equal(placeholderForSchema({ type: "number" }), 0);
  assert.equal(placeholderForSchema({ type: "boolean" }), false);
  assert.deepEqual(placeholderForSchema({ type: "array" }), []);
  assert.deepEqual(placeholderForSchema({ type: "object" }), {});
  assert.equal(placeholderForSchema({ type: "string" }), "__placeholder__");
  assert.equal(placeholderForSchema(undefined), "__placeholder__");
});

test("replaceVariables substitutes ${...} values in config fields", () => {
  const configSchema = {
    type: "object",
    properties: {
      rejection_mode: { type: "string", default: "return_error" },
    },
  };

  const result = replaceVariables(
    { rejection_mode: "${REJECTION_MODE}" },
    configSchema,
  );

  assert.deepEqual(result, { rejection_mode: "return_error" });
});

test("replaceVariables strips a null the schema does not allow", () => {
  const configSchema = {
    type: "object",
    properties: {
      port: { type: "integer" },
      rejection_mode: { type: "string" },
    },
  };

  const result = replaceVariables(
    { port: null, rejection_mode: "return_error" },
    configSchema,
  );

  assert.deepEqual(result, { rejection_mode: "return_error" });
});

test("replaceVariables keeps a null on a key the schema does not declare", () => {
  const configSchema = {
    type: "object",
    properties: {
      rejection_mode: { type: "string" },
    },
  };

  const result = replaceVariables(
    { rejection_mode: "return_error", tresholds: null },
    configSchema,
  );

  assert.deepEqual(result, { rejection_mode: "return_error", tresholds: null });
});

test("replaceVariables keeps a null on a nullable field", () => {
  const configSchema = {
    type: "object",
    properties: {
      port: { type: ["integer", "null"] },
    },
  };

  const result = replaceVariables({ port: null }, configSchema);

  assert.deepEqual(result, { port: null });
});

test("replaceVariables substitutes inside arrays and nested objects", () => {
  const configSchema = {
    type: "object",
    properties: {
      categories: {
        type: "array",
        items: { type: "string", example: "email" },
      },
      nested: {
        type: "object",
        properties: {
          url: { type: "string", default: "https://example.com" },
        },
      },
    },
  };

  const result = replaceVariables(
    {
      categories: ["${CATEGORY}", "phone"],
      nested: { url: "${UPSTREAM_URL}" },
    },
    configSchema,
  );

  assert.deepEqual(result, {
    categories: ["email", "phone"],
    nested: { url: "https://example.com" },
  });
});
