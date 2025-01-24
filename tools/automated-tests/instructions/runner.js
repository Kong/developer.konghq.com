import fs from "fs/promises";
import yaml from "js-yaml";
import debug from "debug";
import { processPrereqs } from "./prereqs.js";
import { processSteps } from "./step.js";
import { validate, ValidationError } from "./validations.js";
import { executeCommand, removeContainer } from "../docker-helper.js";
import { getSetupConfig } from "./setup.js";
import { logResult } from "../reporting.js";

const log = debug("tests:runner");

export class ExitOnFailure extends Error {
  constructor(message) {
    super(message);
    this.name = "ExitOnFailure";
  }
}

function compareVersions(v1, v2) {
  const v1Parts = v1.split(".");
  const v2Parts = v2.split(".");

  for (let i = 0; i < Math.max(v1Parts.length, v2Parts.length); i++) {
    const part1 = parseInt(v1Parts[i] || 0);
    const part2 = parseInt(v2Parts[i] || 0);

    if (part1 > part2) {
      return 1; // v1 is greater
    } else if (part1 < part2) {
      return -1; // v2 is greater
    }
  }

  return 0; // Versions are equal
}

async function runConfig(config, container) {
  try {
    if (config.commands) {
      for (const command of config.commands) {
        await executeCommand(container, command);
      }
    }
  } catch (error) {
    throw error;
  }
}

async function checkSetup(setup, runtimeConfig) {
  const { runtime, version: minVersion } = await getSetupConfig(setup);
  if (runtime !== runtimeConfig.runtime) {
    throw new Error(
      "The instructions files setup does not match the current runtime."
    );
  }

  if (minVersion && runtimeConfig.version) {
    // The version specified in the instructions file is the min_version supported.
    // Given that we generate the file once and run it against different versions,
    // we need to skip the case when the min_version is greater than the current version
    // that we are running.
    if (compareVersions(minVersion, runtimeConfig.version) === 1) {
      log(
        `⚠️ Skipping test. The version ${minVersion} in 'setup' is greater than ${runtimeConfig.version}`
      );
      return false;
    }
  }
  return true;
}

async function runPrereqs(prereqs, container) {
  log("Running prereqs...");
  if (prereqs) {
    const config = await processPrereqs(prereqs);
    await runConfig(config, container);
    log(`   prereq ✅ .`);
  }
}

async function runSteps(steps, runtimeConfig, container) {
  let assertions = [];
  try {
    log("Running steps...");
    if (steps) {
      const config = await processSteps(steps);
      if (config.commands) {
        for (const command of config.commands) {
          if (typeof command === "string") {
            await executeCommand(container, command);
            log(`   step ✅ .`);
          } else {
            // XXX: Sleep needed here because we need to wait for the iterator
            // rebuilding in Gateway.
            await new Promise((resolve) => setTimeout(resolve, 5000));
            const result = await validate(command, runtimeConfig);
            assertions.push(...result);
          }
        }
      }
    }
  } catch (error) {
    if (error instanceof ValidationError) {
      assertions.push(...error.assertions);
    } else {
      assertions.push(error.message);
    }

    throw error;
  }
  return assertions;
}

export async function runInstructions(instructions, runtimeConfig, container) {
  let result = {};
  try {
    const check = await checkSetup(instructions.setup, runtimeConfig);

    if (!check) {
      result["status"] = "skipped";
      return result;
    }

    await runPrereqs(instructions.prereqs, container);

    const assertions = await runSteps(
      instructions.steps,
      runtimeConfig,
      container
    );

    result["assertions"] = assertions;
    result["status"] = "passed";
  } catch (err) {
    result["status"] = "failed";
    if (err instanceof ValidationError) {
      result["assertions"] = err.assertions;
    } else {
      result["assertions"] = [err.message];
    }
  }
  return result;
}

export async function runInstructionsFile(file, runtimeConfig, container) {
  log(`Running file: ${file}`);
  const fileContent = await fs.readFile(file, "utf8");
  const instructions = yaml.load(fileContent);
  const { status, assertions } = await runInstructions(
    instructions,
    runtimeConfig,
    container
  );

  const result = { file, status, assertions };
  if (result.status === "error" && !process.env.CONTINUE_ON_ERROR) {
    logResult(result);
    throw new ExitOnFailure();
  }
  return result;
}
