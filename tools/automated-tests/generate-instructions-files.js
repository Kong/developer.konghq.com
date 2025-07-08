import yaml from "js-yaml";
import fs from "fs/promises";
import minimist from "minimist";
import { generateInstructionFiles } from "./instructions/extractor.js";
import { testeableUrlsFromFiles } from "./instructions-file.js";
import fastGlob from "fast-glob";

(async function main() {
  try {
    const args = minimist(process.argv.slice(2));
    const fileContent = await fs.readFile("./config/tests.yaml", "utf8");
    const testsConfig = yaml.load(fileContent);
    let urlsToTest;
    let howToFiles;

    console.log("Generating instruction files...");

    if (args.urls) {
      urlsToTest = Array.isArray(args.urls) ? args.urls : [args.urls];
    } else {
      if (args.files) {
        howToFiles = Array.isArray(args.files) ? args.files : [args.files];
      } else {
        howToFiles = await fastGlob("../../app/_how-tos/**/*");
      }
      urlsToTest = await testeableUrlsFromFiles(testsConfig, howToFiles);
    }
    await generateInstructionFiles(urlsToTest, testsConfig);

    console.log("done.");
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
