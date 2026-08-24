import fs from "fs/promises";
import { glob } from "tinyglobby";
import matter from "gray-matter";
import path from "path";
import yaml from "js-yaml";

function fileToUrl(file) {
  return file.replace("../../app/_how-tos/", "").replace(".md", "/");
}

function deriveSkipProducts(products) {
  // Mirrors extractor.js's deriveProduct special case: ai-gateway v1 how-tos are
  // tagged with both "gateway" and "ai-gateway" but only ever run as "gateway".
  if (products.includes("ai-gateway") && products.includes("gateway")) {
    return ["gateway"];
  }
  return products;
}

export async function testeableUrlsFromFiles(config, files, { explicit = false } = {}) {
  const howTosUrls = [];
  const skipped = [];

  const parsedFiles = files.map((file) => {
    const { data: frontmatter, content } = matter.read(file);
    return { file, frontmatter, content };
  });

  const seriesFirstPageTitles = {};
  for (const { frontmatter } of parsedFiles) {
    if (frontmatter.series && frontmatter.series.position === 1) {
      seriesFirstPageTitles[frontmatter.series.id] = frontmatter.title;
    }
  }

  for (const { file, frontmatter, content } of parsedFiles) {
    const isTesteable =
      frontmatter.products &&
      (frontmatter.products.includes("gateway") ||
        frontmatter.products.includes("ai-gateway") ||
        frontmatter.products.includes("event-gateway"));

    if (isTesteable) {
      const isNonFirstSeriesPage =
        frontmatter.series && frontmatter.series.position !== 1;

      if (isNonFirstSeriesPage && explicit) {
        const relativeFilePath = file.replace("../../", "");
        throw new Error(
          `${relativeFilePath} is part of series "${frontmatter.series.id}" but is not the ` +
          `first page (position ${frontmatter.series.position}). Target the first page of ` +
          `the series instead.`
        );
      }

      const skipHowTo =
        isNonFirstSeriesPage ||
        content.includes("@todo") ||
        frontmatter.automated_tests === false ||
        frontmatter.published === false;

      let howToUrl;
      if (frontmatter.permalink) {
        howToUrl = frontmatter.permalink;
      } else {
        howToUrl = `/how-to/${fileToUrl(file)}`;
      }

      if (skipHowTo) {
        const relativeFilePath = file.replace("../../", "");
        let message;
        if (isNonFirstSeriesPage) {
          const firstPageTitle =
            seriesFirstPageTitles[frontmatter.series.id] || "the series' first page";
          message = `Part of series "${frontmatter.series.id}", tested via "${firstPageTitle}"`;
        } else if (frontmatter.automated_tests === false) {
          message = "Tagged with automated_tests=false";
        } else {
          message = "Tagged with @todo.";
        }
        console.log(`Skipping file: ${relativeFilePath}. ${message}`);

        const name = `[${frontmatter.title}](${config.productionUrl}${howToUrl})`;
        skipped.push({
          status: "skipped",
          products: deriveSkipProducts(frontmatter.products),
          duration: 0,
          name,
          message,
          reason: isNonFirstSeriesPage ? "series" : "excluded",
        });
      } else {
        howTosUrls.push(`${config.baseUrl}${howToUrl}`);
      }
    }
  }
  await fs.writeFile(".automated-tests", yaml.dump(skipped), "utf-8");

  return howTosUrls;
}

export async function instructionFileFromConfig(config) {
  const files = await glob("**/*", { cwd: config.instructionsDir });
  if (files.length === 0) {
    console.error(
      `The platform couldn't find any instructions files to run in ${config.instructionsDir}.`
    );
    console.error(`Please run \`npm run generate-instruction-files\` first`);
    process.exit(1);
  }

  return files.map((f) => path.join(config.instructionsDir, f));
}

export async function groupInstructionFilesByDeploymentModelAndProduct(files) {
  const groupedFiles = {};

  for (const file of files) {
    // Deployment model is the parent directory name (e.g., "on-prem" or "konnect")
    const deploymentModel = path.basename(path.dirname(file));

    // Product is the file basename without extension (e.g., "gateway", "operator")
    const product = path.basename(file, path.extname(file));

    groupedFiles[deploymentModel] = groupedFiles[deploymentModel] || {};
    groupedFiles[deploymentModel][product] =
      groupedFiles[deploymentModel][product] || [];
    groupedFiles[deploymentModel][product].push(file);
  }

  return groupedFiles;
}
