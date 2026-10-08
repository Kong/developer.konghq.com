import test from "node:test";
import assert from "node:assert/strict";
import { licenseRequired } from "../runtimes.js";

test("licenseRequired is true for every combination except konnect operator", () => {
  const deploymentModels = ["on-prem", "konnect"];
  const products = [
    "gateway",
    "ai-gateway",
    "event-gateway",
    "operator",
    "kic",
  ];

  for (const deploymentModel of deploymentModels) {
    for (const product of products) {
      const expected = !(deploymentModel === "konnect" && product === "operator");

      assert.equal(
        licenseRequired(deploymentModel, product),
        expected,
        `licenseRequired('${deploymentModel}', '${product}')`
      );
    }
  }
});
