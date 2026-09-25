import test from "node:test";
import assert from "node:assert/strict";
import { runtimeEnvironment } from "../runtimes.js";

const ENV_KEYS = [
  "KONNECT_DOMAIN",
  "KONGCTL_DEFAULT_KONNECT_ENVIRONMENT",
  "TESTS_KONNECT_CONTROL_PLANE_URL",
];

function withEnv(vars, fn) {
  const previous = {};
  for (const key of ENV_KEYS) {
    previous[key] = process.env[key];
    delete process.env[key];
  }
  Object.assign(process.env, vars);

  return Promise.resolve()
    .then(fn)
    .finally(() => {
      for (const key of ENV_KEYS) {
        if (previous[key] === undefined) {
          delete process.env[key];
        } else {
          process.env[key] = previous[key];
        }
      }
    });
}

function baseRuntimeConfig() {
  return { deploymentModel: "konnect", product: "ai-gateway", env: {} };
}

test("KONNECT_DOMAIN passes through with no prefix change", async () => {
  await withEnv({ KONNECT_DOMAIN: "konghq.tech" }, async () => {
    const environment = await runtimeEnvironment(baseRuntimeConfig());
    assert.equal(environment.KONNECT_DOMAIN, "konghq.tech");
    assert.equal(environment.DECK_KONNECT_DOMAIN, undefined);
  });
});

test("an unset KONNECT_DOMAIN leaves the container environment without the key", async () => {
  await withEnv({}, async () => {
    const environment = await runtimeEnvironment(baseRuntimeConfig());
    assert.equal("KONNECT_DOMAIN" in environment, false);
  });
});

test("KONNECT_DOMAIN=konghq.tech derives the control plane URL, its DECK_ twin, and the kongctl environment", async () => {
  await withEnv({ KONNECT_DOMAIN: "konghq.tech" }, async () => {
    const environment = await runtimeEnvironment(baseRuntimeConfig());
    assert.equal(environment.KONNECT_CONTROL_PLANE_URL, "https://us.api.konghq.tech");
    assert.equal(environment.DECK_KONNECT_CONTROL_PLANE_URL, "https://us.api.konghq.tech");
    assert.equal(environment.KONGCTL_DEFAULT_KONNECT_ENVIRONMENT, "tech");
  });
});

test("KONNECT_DOMAIN=konghq.com derives no kongctl environment", async () => {
  await withEnv({ KONNECT_DOMAIN: "konghq.com" }, async () => {
    const environment = await runtimeEnvironment(baseRuntimeConfig());
    assert.equal("KONGCTL_DEFAULT_KONNECT_ENVIRONMENT" in environment, false);
  });
});

test("an explicit TESTS_KONNECT_CONTROL_PLANE_URL wins over the derived value", async () => {
  await withEnv(
    {
      KONNECT_DOMAIN: "konghq.tech",
      TESTS_KONNECT_CONTROL_PLANE_URL: "https://eu.api.konghq.tech",
    },
    async () => {
      const environment = await runtimeEnvironment(baseRuntimeConfig());
      assert.equal(environment.KONNECT_CONTROL_PLANE_URL, "https://eu.api.konghq.tech");
      assert.equal(environment.DECK_KONNECT_CONTROL_PLANE_URL, "https://eu.api.konghq.tech");
    }
  );
});
