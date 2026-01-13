import fs from "fs/promises";
import yaml from "js-yaml";
import debug from "debug";
import { processPrereqs } from "./prereqs.js";
import { processCleanup } from "./cleanup.js";
import { processSteps } from "./step.js";
import { validate, ValidationError } from "./validations.js";
import { executeCommand } from "../docker-helper.js";
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
  if (v2 === "next") {
    return true;
  }
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

async function checkSetup(setup, runtimeConfig, container) {
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

async function runPrereqs(prereqs, container, runtimeConfig) {
  log("Running prereqs...");
  if (prereqs) {
    const config = await processPrereqs(prereqs);

    if (config.commands) {
      for (const command of config.commands) {
        if (typeof command === "string") {
          await executeCommand(container, command);
        } else {
          await validate(container, command, runtimeConfig);
        }
      }
      log(`   prereq ✅ .`);
    }
  }
}

async function runCleanup(cleanup, container) {
  log("Running cleanup...");
  if (cleanup) {
    const config = await processCleanup(cleanup);
    await runConfig(config, container);
    log(`   cleanup ✅ .`);
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
            const result = await validate(container, command, runtimeConfig);
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
  let result = { name: instructions.name };
  const { rbac, wasm } = await getSetupConfig(instructions.setup);
  try {
    const check = await checkSetup(
      instructions.setup,
      runtimeConfig,
      container
    );

    if (!check) {
      result["status"] = "skipped";
      return result;
    }

    if (rbac) {
      for (const command of runtimeConfig.gateway.setup.rbac.commands) {
        await executeCommand(container, command);
      }
    }
    if (wasm) {
      for (const command of runtimeConfig.gateway.setup.wasm.commands) {
        await executeCommand(container, command);
      }
    }

    await runPrereqs(instructions.prereqs, container, runtimeConfig);

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

  if (rbac || wasm) {
    for (const command of runtimeConfig.gateway.setup.commands) {
      await executeCommand(container, command);
    }
  }

  await runCleanup(instructions.cleanup, container);

  return result;
}

export async function runInstructionsFile(file, runtimeConfig, container) {
  const start = Date.now();
  log(`Running file: ${file}`);
  const fileContent = await fs.readFile(file, "utf8");
  const instructions = yaml.load(fileContent);
  const { status, assertions, name } = await runInstructions(
    instructions,
    runtimeConfig,
    container
  );

  const duration = Date.now() - start;
  const result = { file, status, assertions, duration, name };
  if (result.status === "error" && !process.env.CONTINUE_ON_ERROR) {
    logResult(result);
    throw new ExitOnFailure();
  }
  return result;
}
