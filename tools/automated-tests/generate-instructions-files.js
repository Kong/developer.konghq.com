import { load } from "js-yaml";
import fs from "fs/promises";
import minimist from "minimist";
import { generateInstructionFiles } from "./instructions/extractor.js";
import { resolveUrlsToTest } from "./resolve-urls.js";
import { resolveDevServerTarget } from "./dev-server-target.js";

(async function main() {
  try {
    const args = minimist(process.argv.slice(2));
    const fileContent = await fs.readFile("./config/tests.yaml", "utf8");
    const testsConfig = resolveDevServerTarget(load(fileContent));

    console.log("Generating instruction files...");
    console.log(`Scraping ${testsConfig.baseUrl}`);

    const { urlsToTest, haltOnSeriesError } = await resolveUrlsToTest(
      args,
      testsConfig,
    );

    await generateInstructionFiles(urlsToTest, testsConfig, {
      haltOnSeriesError,
    });

    console.log("done.");
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
