import fs from "fs/promises";
import yaml from "js-yaml";
import debug from "debug";
import path from "path";
import fastGlob from "fast-glob";
import Dockerode from "dockerode";
import { generateInstructionFiles } from "./instructions/extractor.js";
import { runInstructionsFile } from "./instructions/runner.js";
import {
  setupRuntime,
  cleanupRuntime,
  resetRuntime,
  getRuntimeConfig,
} from "./runtimes.js";

const log = debug("tests");

const docker = new Dockerode({
  socketPath: "/var/run/docker.sock",
});

async function loadConfig() {
  const configFile = "./config.yaml";

  const fileContent = await fs.readFile(configFile, "utf8");
  const config = yaml.load(fileContent);

  return config;
}

async function groupInstructionFilesByRuntime(config) {
  const groupedFiles = {};

  const files = await fastGlob("**/*", { cwd: config.outputDir });

  for (const file of files) {
    const runtime = path.basename(file, path.extname(file));
    groupedFiles[runtime] = groupedFiles[runtime] || [];
    groupedFiles[runtime].push(path.join(config.outputDir, file));
  }

  return groupedFiles;
}

async function stopContainer(container) {
  if (container) {
    await container.stop();
    log("Container stopped.");
  }
}

async function removeContainer(container) {
  if (container) {
    await container.remove();
    log("Container removed.");
  }
}

(async function main() {
  let container;
  try {
    const testsConfig = await loadConfig();

    if (!process.env.SKIP_INSTRUCTIONS_EXTRACTION) {
      log("Generating instruction files...");
      await generateInstructionFiles(testsConfig);
    } else {
      log(`Skipping extraction...`);
    }

    const filesByRuntime = await groupInstructionFilesByRuntime(testsConfig);

    for (const [runtime, instructionFiles] of Object.entries(filesByRuntime)) {
      if (process.env.RUNTIME && process.env.RUNTIME !== runtime) {
        continue;
      }

      const runtimeConfig = await getRuntimeConfig(testsConfig, runtime);
      log(`Running ${runtime} tests...`);

      container = await setupRuntime(runtimeConfig, docker);

      for (const instructionFile of instructionFiles) {
        await resetRuntime(runtimeConfig, container);
        await runInstructionsFile(instructionFile, runtimeConfig, container);
      }

      await cleanupRuntime(runtimeConfig, container);
    }
    await stopContainer(container);
    await removeContainer(container);
  } catch (error) {
    console.error(error);

    await stopContainer(container);
    await removeContainer(container);

    process.exit(1);
  }
})();
