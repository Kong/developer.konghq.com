import yaml from "js-yaml";
import fs from "fs/promises";
import minimist from "minimist";
import { generateInstructionFiles } from "./instructions/extractor.js";
import { testeableUrlsFromFiles } from "./instructions-file.js";

(async function main() {
  try {
    const args = minimist(process.argv.slice(2));
    const fileContent = await fs.readFile("./config/tests.yaml", "utf8");
    const testsConfig = yaml.load(fileContent);
    let urlsToTest;

    console.log("Generating instruction files...");

    if (args.urls) {
      urlsToTest = Array.isArray(args.urls) ? args.urls : [args.urls];
    } else {
      urlsToTest = await testeableUrlsFromFiles(testsConfig);
    }
    await generateInstructionFiles(urlsToTest, testsConfig);

    console.log("done.");
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
