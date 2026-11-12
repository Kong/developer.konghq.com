import test from "node:test";
import assert from "node:assert/strict";
import { licenseRequired } from "../runtimes.js";

test("on-prem runs require a gateway license", () => {
  assert.equal(licenseRequired("on-prem"), true);
});

test("konnect runs require no gateway license", () => {
  assert.equal(licenseRequired("konnect"), false);
});
