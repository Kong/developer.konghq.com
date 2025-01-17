import fs from "fs/promises";
import yaml from "js-yaml";
import Dockerode from "dockerode";
import minimist from "minimist";
import { logResult, logResults } from "./reporting.js";
import { ExitOnFailure, runInstructionsFile } from "./instructions/runner.js";
import {
  setupRuntime,
  cleanupRuntime,
  resetRuntime,
  getRuntimeConfig,
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
  try {
    const testsConfig = await loadConfig();
    if (args.files) {
      files = Array.isArray(args.files) ? args.files : [args.files];
    } else {
      files = await instructionFileFromConfig(testsConfig);
    }
    const filesByRuntime = await groupInstructionFilesByRuntime(files);

    for (const [runtime, instructionFiles] of Object.entries(filesByRuntime)) {
      if (process.env.RUNTIME && process.env.RUNTIME !== runtime) {
        continue;
      }

      const runtimeConfig = await getRuntimeConfig(runtime);
      console.log(`Running ${runtime} tests...`);

      container = await setupRuntime(runtimeConfig, docker);

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
    await stopContainer(container);
    await removeContainer(container);
  } catch (error) {
    if (typeof error !== ExitOnFailure) {
      console.error(error);
    }

    await stopContainer(container);
    await removeContainer(container);

    await logResults(results);
    process.exit(1);
  }
  await logResults(results);

  if (results.filter((r) => r.status === "failed").length > 0) {
    process.exit(1);
  } else {
    return 0;
  }
})();
