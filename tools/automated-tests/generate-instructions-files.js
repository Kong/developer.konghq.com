import yaml from "js-yaml";
import fs from "fs/promises";
import minimist from "minimist";
import { generateInstructionFiles } from "./instructions/extractor.js";
import { testeableUrlsFromFiles } from "./instructions-file.js";
import { glob } from "tinyglobby";
import { collectUrls } from "./collect-urls.mjs";

(async function main() {
  try {
    const args = minimist(process.argv.slice(2));
    const fileContent = await fs.readFile("./config/tests.yaml", "utf8");
    const testsConfig = yaml.load(fileContent);
    let urlsToTest;
    let howToFiles;
    let haltOnSeriesError = true;

    console.log("Generating instruction files...");

    if (args.urls && args.product) {
      throw new Error("Pass either --urls or --product, not both.");
    }

    if (args.urls) {
      urlsToTest = Array.isArray(args.urls) ? args.urls : [args.urls];
    } else if (args.product) {
      const { urls, skipped } = collectUrls(args.product, args.baseUrl);
      if (skipped.length) {
        console.warn(
          `Skipped ${skipped.length} file(s) with no permalink:`,
          skipped.map((s) => s.file).join(", "),
        );
      }
      urlsToTest = urls;
      // Scanning a whole product routinely hits non-first series pages;
      // log and skip them instead of aborting the rest of the batch.
      haltOnSeriesError = false;
    } else {
      if (args.files) {
        howToFiles = Array.isArray(args.files) ? args.files : [args.files];
      } else {
        howToFiles = await glob("../../app/_how-tos/**/*");
      }
      urlsToTest = await testeableUrlsFromFiles(testsConfig, howToFiles, {
        explicit: !!args.files,
      });
    }
    await generateInstructionFiles(urlsToTest, testsConfig, {
      haltOnSeriesError,
    });

    console.log("done.");
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
