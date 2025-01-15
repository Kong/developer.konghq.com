import debug from "debug";
import yaml from "js-yaml";
import fs from "fs/promises";
import minimist from "minimist";
import fastGlob from "fast-glob";
import matter from "gray-matter";
import { generateInstructionFiles } from "./instructions/extractor.js";

const log = debug("tests:extractor");

async function testeableUrlsFromFiles(config) {
  const howTosUrls = [];
  const howToFiles = await fastGlob("../../app/_how-tos/**/*");

  for (const file of howToFiles) {
    const { data: frontmatter, content } = matter.read(file);

    const isTesteable =
      frontmatter.products &&
      frontmatter.products.length === 1 &&
      frontmatter.products.includes("gateway");

    if (isTesteable) {
      const skipHowTo =
        content.includes("@todo") || frontmatter.automated_tests === false;
      if (skipHowTo) {
        const relativeFilePath = file.replace("../../", "");
        if (frontmatter.automated_tests === false) {
          log(
            `Skipping file: ${relativeFilePath}, it's tagged with automated_tests=false`
          );
        } else {
          log(`Skipping file: ${relativeFilePath}, it's tagged with @todo.`);
        }
      } else {
        const fileToUrl = file
          .replace("../../app/_how-tos/", "")
          .replace(".md", "/");
        howTosUrls.push(`${config.baseUrl}/how-to/${fileToUrl}`);
      }
    }
  }
  return howTosUrls;
}

(async function main() {
  try {
    const args = minimist(process.argv.slice(2));
    const fileContent = await fs.readFile("./config.yaml", "utf8");
    const testsConfig = yaml.load(fileContent);
    let urlsToTest;

    log("Generating instruction files...");

    if (args.urls) {
      urlsToTest = Array.isArray(args.urls) ? args.urls : [args.urls];
    } else {
      urlsToTest = await testeableUrlsFromFiles(testsConfig);
    }
    await generateInstructionFiles(urlsToTest, testsConfig);

    log("done.");
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
