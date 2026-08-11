import fs from "fs/promises";
import yaml from "js-yaml";
import Dockerode from "dockerode";
import minimist from "minimist";
import { logResult, logResults, isFailureExpected } from "./reporting.js";
import { ExitOnFailure, runInstructionsFile } from "./instructions/runner.js";
import { getSetupConfig } from "./instructions/setup.js";
import {
  setupRuntime,
  startBaseline,
  cleanupRuntime,
  resetRuntime,
  getRuntimeConfig,
  afterAll,
  beforeAll,
} from "./runtimes.js";
import { stopContainer, removeContainer } from "./docker-helper.js";
import {
  instructionFileFromConfig,
  groupInstructionFilesByDeploymentModelAndProduct,
} from "./instructions-file.js";
import "@dotenvx/dotenvx/config";

const docker = new Dockerode({
  socketPath: "/var/run/docker.sock",
});

function checkEnvVariables() {
  if (!process.env.KONG_LICENSE_DATA) {
    console.error("Missing env variable KONG_LICENSE_DATA");
    process.exit(1);
  }
  if (!process.env.PRODUCTS) {
    console.error("Missing env variable PRODUCTS");
    process.exit(1);
  }
}

export async function loadConfig() {
  const configFile = "./config/tests.yaml";

  const fileContent = await fs.readFile(configFile, "utf8");
  const config = yaml.load(fileContent);

  return config;
}

// Tests that provision their own gateway (e.g. via `docker compose`) can't
// run alongside the shared baseline gateway without a port conflict. Rather
// than stop/restart the baseline per file (expensive — it takes a while to
// boot), we run every standalone-gateway file first, before the baseline
// ever starts, then boot it once for the rest of the batch as usual.
async function usesStandaloneGateway(file) {
  const fileContent = await fs.readFile(file, "utf8");
  const instructions = yaml.load(fileContent);
  const { standaloneGateway } = await getSetupConfig(instructions.setup);
  return Boolean(standaloneGateway);
}

async function partitionByStandaloneGateway(instructionFiles) {
  const standalone = [];
  const standard = [];
  for (const file of instructionFiles) {
    if (await usesStandaloneGateway(file)) {
      standalone.push(file);
    } else {
      standard.push(file);
    }
  }
  return { standalone, standard };
}

// resetRuntime/runInstructionsFile can reject on infra-level failures (e.g. a
// flaky `deck gateway reset -f`) outside the per-test try/catch. Uncaught,
// that would abort every remaining file in the batch regardless of
// CONTINUE_ON_ERROR. With the flag set, record it as a failure and move on.
async function runFile(instructionFile, runtimeConfig, container, { reset }) {
  try {
    if (reset) {
      await resetRuntime(runtimeConfig, container);
    }
    return await runInstructionsFile(instructionFile, runtimeConfig, container);
  } catch (error) {
    if (!process.env.CONTINUE_ON_ERROR) {
      throw error;
    }
    console.error(error);
    return {
      file: instructionFile,
      status: "failed",
      assertions: [error.message || String(error)],
      duration: 0,
      name: instructionFile,
    };
  }
}

(async function main() {
  let productTestConfig = {};
  let container;
  let results = [];
  let files = [];
  const args = minimist(process.argv.slice(2));
  const testsConfig = await loadConfig();
  const start = Date.now();
  const products = process.env.PRODUCTS.split(",");
  try {
    if (args.files) {
      files = Array.isArray(args.files) ? args.files : [args.files];
    } else {
      files = await instructionFileFromConfig(testsConfig);
    }

    checkEnvVariables();

    const filesByDeploymentModelAndProduct =
      await groupInstructionFilesByDeploymentModelAndProduct(files);

    for (const [deploymentModel, instructionFilesByProduct] of Object.entries(
      filesByDeploymentModelAndProduct
    )) {
      if (
        process.env.DEPLOYMENT_MODEL &&
        process.env.DEPLOYMENT_MODEL !== deploymentModel
      ) {
        continue;
      }

      for (const [product, instructionFiles] of Object.entries(
        instructionFilesByProduct
      )) {
        if (!products.includes(product)) {
          continue;
        }

        productTestConfig = testsConfig.products[product] || {};

        const runtimeConfig = await getRuntimeConfig(deploymentModel, product);
        console.log(
          `Running ${product} tests on ${deploymentModel}...`
        );

        container = await setupRuntime(runtimeConfig, docker);

        await beforeAll(productTestConfig, container);

        const { standalone, standard } =
          await partitionByStandaloneGateway(instructionFiles);

        for (const instructionFile of standalone) {
          const result = await runFile(instructionFile, runtimeConfig, container, {
            reset: false,
          });
          logResult(result);
          results.push(result);
        }

        if (standard.length > 0) {
          await startBaseline(runtimeConfig, container);
          for (const instructionFile of standard) {
            const result = await runFile(instructionFile, runtimeConfig, container, {
              reset: true,
            });
            logResult(result);
            results.push(result);
          }
          await cleanupRuntime(runtimeConfig, container);
        }
        await afterAll(productTestConfig, container);
      }
    }
    await stopContainer(container);
    await removeContainer(container);
  } catch (error) {
    if (typeof error !== ExitOnFailure) {
      console.error(error);
    }

    await afterAll(productTestConfig, container);
    await stopContainer(container);
    await removeContainer(container);

    await logResults(results, start, Date.now(), products);
    process.exit(1);
  }
  await logResults(results, start, Date.now(), products);

  const failedTests = results.filter(
    (r) => r.status === "failed" && !isFailureExpected(r)
  );
  if (failedTests.length > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
})();
