import fs from "fs/promises";
import yaml from "js-yaml";
import Dockerode from "dockerode";
import minimist from "minimist";
import { logResult, logResults, isFailureExpected } from "./reporting.js";
import { ExitOnFailure, runInstructionsFile } from "./instructions/runner.js";
import {
  setupRuntime,
  cleanupRuntime,
  resetRuntime,
  getRuntimeConfig,
  afterAll,
  beforeAll,
} from "./runtimes.js";
import { stopContainer, removeContainer } from "./docker-helper.js";
import {
  instructionFileFromConfig,
  groupInstructionFilesByRuntime,
} from "./instructions-file.js";

const docker = new Dockerode({
  socketPath: "/var/run/docker.sock",
});

export async function loadConfig() {
  const configFile = "./config/tests.yaml";

  const fileContent = await fs.readFile(configFile, "utf8");
  const config = yaml.load(fileContent);

  return config;
}

(async function main() {
  let container;
  let results = [];
  let files = [];
  const args = minimist(process.argv.slice(2));
  const testsConfig = await loadConfig();
  const start = Date.now();
  try {
    if (args.files) {
      files = Array.isArray(args.files) ? args.files : [args.files];
    } else {
      files = await instructionFileFromConfig(testsConfig);
    }
    if (!process.env.KONG_LICENSE_DATA) {
      console.error("Missing env variable KONG_LICENSE_DATA");
      process.exit(1);
    }
    const filesByRuntime = await groupInstructionFilesByRuntime(files);

    for (const [runtime, instructionFiles] of Object.entries(filesByRuntime)) {
      if (process.env.RUNTIME && process.env.RUNTIME !== runtime) {
        continue;
      }

      const runtimeConfig = await getRuntimeConfig(runtime);
      console.log(`Running ${runtime} tests...`);

      container = await setupRuntime(runtimeConfig, docker);

      await beforeAll(testsConfig, container);

      for (const instructionFile of instructionFiles) {
        await resetRuntime(runtimeConfig, container);
        const result = await runInstructionsFile(
          instructionFile,
          runtimeConfig,
          container
        );
        logResult(result);
        results.push(result);
      }

      await cleanupRuntime(runtimeConfig, container);
    }
    await afterAll(testsConfig, container);
    await stopContainer(container);
    await removeContainer(container);
  } catch (error) {
    if (typeof error !== ExitOnFailure) {
      console.error(error);
    }

    await afterAll(testsConfig, container);
    await stopContainer(container);
    await removeContainer(container);

    await logResults(results, start, Date.now());
    process.exit(1);
  }
  await logResults(results, start, Date.now());

  const failedTests = results.filter(
    (r) => r.status === "failed" && !isFailureExpected(r)
  );
  if (failedTests.length > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
})();
