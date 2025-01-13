import fs from "fs/promises";
import yaml from "js-yaml";

async function extractCleanup(setupConfig) {
  const fileContent = await fs.readFile("./config/cleanup.yaml", "utf8");
  const cleanupConfig = yaml.load(fileContent);

  const instructions = [];

  let config = cleanupConfig[setupConfig.product];
  if (config) {
    instructions.push(...config.commands);
  }

  return instructions;
}

export async function processCleanup(setupConfig) {
  let commands = [];
  const cleanup = await extractCleanup(setupConfig);
  for (const command of cleanup) {
    if (typeof command === "object") {
      // TODO: process cleanup of type object
      console.warn("Unsupported: Cleanup of type object");
    } else {
      commands.push(command);
    }
  }
  return { commands };
}
