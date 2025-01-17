import fs from "fs/promises";
import yaml from "js-yaml";
import path from "path";
import fastGlob from "fast-glob";
import Dockerode from "dockerode";

import { runInstructionsFile } from "./instructions/runner.js";
import {
  setupRuntime,
  cleanupRuntime,
  resetRuntime,
  getRuntimeConfig,
} from "./runtimes.js";

const docker = new Dockerode({
  socketPath: "/var/run/docker.sock",
});

export async function loadConfig() {
  const configFile = "./config/tests.yaml";

  const fileContent = await fs.readFile(configFile, "utf8");
  const config = yaml.load(fileContent);

  return config;
}

async function groupInstructionFilesByRuntime(config) {
  const groupedFiles = {};

  const files = await fastGlob("**/*", { cwd: config.instructionsDir });
  if (files.length === 0) {
    console.error(
      `The platform couldn't find any instructions files to run in ${config.instructionsDir}.`
    );
    console.error(
      `Please run \`DEBUG='tests:extractor' npm run generate-instruction-files\` first`
    );
    process.exit(1);
  }

  for (const file of files) {
    const runtime = path.basename(file, path.extname(file));
    groupedFiles[runtime] = groupedFiles[runtime] || [];
    groupedFiles[runtime].push(path.join(config.instructionsDir, file));
  }

  return groupedFiles;
}

async function stopContainer(container) {
  if (container) {
    await container.stop();
  }
}

async function removeContainer(container) {
  if (container) {
    await container.remove();
  }
}

function logResult(result) {
  switch (result.status) {
    case "passed":
      process.stdout.write("✅");
      break;
    case "failed":
      process.stdout.write("❌");
      break;
    case "skipped":
      process.stdout.write("⚠️");
      break;
    default:
      process.stdout.write("🤔");
  }
}

async function logResults(results) {
  const passed = results.filter((r) => r.status === "passed");
  const failed = results.filter((r) => r.status === "failed");
  const skipped = results.filter((r) => r.status === "skipped");
  console.log();

  if (failed.length > 0) {
    for (const failure of failed) {
      console.log(`Test: ${failure.file} failed.`);
      console.log(failure.assertions);
    }
  }

  console.log(
    `Summary: ${results.length} total. ${passed.length} passed, ${failed.length} failed, ${skipped.length} skipped.`
  );

  console.log("Tests result logged to ./testReport.json");
  await fs.writeFile(
    "testReport.json",
    JSON.stringify(results, null, 2),
    "utf-8"
  );
}

(async function main() {
  let container;
  let results = [];
  try {
    const testsConfig = await loadConfig();
    const filesByRuntime = await groupInstructionFilesByRuntime(testsConfig);

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
    console.error(error);

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
