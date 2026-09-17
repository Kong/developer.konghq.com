import test from "node:test";
import assert from "node:assert/strict";
import Ajv from "ajv";
import { hardenSchema } from "../lib/crds.js";

const schema = {
  type: "object",
  properties: {
    spec: {
      type: "object",
      properties: {
        level1: {
          type: "object",
          properties: {
            level2: {
              type: "object",
              properties: {
                known: { type: "string" },
              },
            },
          },
        },
        permissive: {
          type: "object",
          "x-kubernetes-preserve-unknown-fields": true,
          properties: {
            known: { type: "string" },
          },
        },
      },
    },
  },
};

test("an unknown field nested three levels deep is rejected", () => {
  const ajv = new Ajv({ allErrors: true, strict: false });
  const validate = ajv.compile(hardenSchema(schema));

  const valid = validate({
    spec: { level1: { level2: { known: "ok", unknown: "nope" } } },
  });

  assert.equal(valid, false);
});

test("an unknown field under a preserve-unknown node is accepted", () => {
  const ajv = new Ajv({ allErrors: true, strict: false });
  const validate = ajv.compile(hardenSchema(schema));

  const valid = validate({
    spec: { permissive: { known: "ok", unknown: "fine" } },
  });

  assert.equal(valid, true);
});
