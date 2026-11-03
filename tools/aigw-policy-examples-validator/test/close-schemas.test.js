import test from "node:test";
import assert from "node:assert/strict";
import { findAllofMembers, closeObjectSchemas } from "../index.js";

test("an object schema with properties and no additionalProperties is closed", () => {
  const schema = {
    type: "object",
    properties: {
      config: {
        type: "object",
        properties: {
          known: { type: "string" },
        },
      },
    },
  };

  closeObjectSchemas(schema, findAllofMembers(schema));

  assert.equal(schema.additionalProperties, false);
  assert.equal(schema.properties.config.additionalProperties, false);
});

test("an explicit additionalProperties: true survives", () => {
  const schema = {
    type: "object",
    properties: {
      passthrough: {
        type: "object",
        properties: {
          known: { type: "string" },
        },
        additionalProperties: true,
      },
    },
  };

  closeObjectSchemas(schema, findAllofMembers(schema));

  assert.equal(schema.additionalProperties, false);
  assert.equal(schema.properties.passthrough.additionalProperties, true);
});

test("oneOf branches close as normal", () => {
  const schema = {
    oneOf: [
      {
        type: "object",
        properties: {
          literal: { type: "string" },
        },
      },
      {
        type: "object",
        properties: {
          expression: { type: "string" },
        },
      },
    ],
  };

  closeObjectSchemas(schema, findAllofMembers(schema));

  for (const branch of schema.oneOf) {
    assert.equal(branch.additionalProperties, false);
  }
});

test("allOf members stay open so their siblings' keys validate", () => {
  const member = {
    type: "object",
    properties: {
      base: { type: "string" },
    },
  };
  const schema = {
    allOf: [
      member,
      {
        type: "object",
        properties: {
          extra: { type: "string" },
        },
      },
    ],
  };

  closeObjectSchemas(schema, findAllofMembers(schema));

  assert.equal(member.additionalProperties, undefined);
  assert.equal(schema.allOf[1].additionalProperties, undefined);
  assert.equal(schema.additionalProperties, undefined);
});
