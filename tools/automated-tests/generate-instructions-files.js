import debug from "debug";
import yaml from "js-yaml";
import fs from "fs/promises";
import { generateInstructionFiles } from "./instructions/extractor.js";

const log = debug("tests:extractor");

(async function main() {
  try {
    const fileContent = await fs.readFile("./config.yaml", "utf8");
    const testsConfig = yaml.load(fileContent);

    log("Generating instruction files...");
    await generateInstructionFiles(testsConfig);

    log("done.");
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
