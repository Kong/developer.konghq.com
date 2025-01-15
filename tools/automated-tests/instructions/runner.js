import fs from "fs/promises";
import yaml from "js-yaml";
import debug from "debug";
import { processPrereqs } from "./prereqs.js";
import { processSteps } from "./step.js";
import { validate, ValidationError } from "./validations.js";
import { executeCommand } from "../docker-helper.js";

const log = debug("tests:runner");

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

async function runPrereqs(prereqs, container) {
  log("Running prereqs...");
  if (prereqs) {
    const config = await processPrereqs(prereqs);
    await runConfig(config, container);
    log(`   prereq ✅ .`);
  }
}

async function runSteps(steps, container) {
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
            await new Promise((resolve) => setTimeout(resolve, 4000));
            await validate(command);
          }
        }
      }
    }
  } catch (error) {
    throw error;
  }
}

export async function runInstructions(instructions, container) {
  try {
    await runPrereqs(instructions.prereqs, container);

    await runSteps(instructions.steps, container);
  } catch (err) {
    if (err instanceof ValidationError) {
      console.error(err.message);
    } else {
      console.error("Error: ", err);
    }
    if (!process.env.CONTINUE_ON_ERROR) {
      process.exit(1);
    }
  }
}

export async function runInstructionsFile(file, container) {
  log(`Running file: ${file}`);
  const fileContent = await fs.readFile(file, "utf8");
  const instructions = yaml.load(fileContent);
  await runInstructions(instructions, container);
}
