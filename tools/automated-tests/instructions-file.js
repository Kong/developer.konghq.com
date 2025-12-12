import fs from "fs/promises";
import fastGlob from "fast-glob";
import matter from "gray-matter";
import path from "path";
import yaml from "js-yaml";

function fileToUrl(file) {
  return file.replace("../../app/_how-tos/", "").replace(".md", "/");
}

export async function testeableUrlsFromFiles(config, files) {
  const howTosUrls = [];
  const skipped = [];

  for (const file of files) {
    const { data: frontmatter, content } = matter.read(file);

    const isTesteable =
      frontmatter.products &&
      (frontmatter.products.includes("gateway") ||
        frontmatter.products.includes("ai-gateway") ||
        frontmatter.products.includes("event-gateway"));

    if (isTesteable) {
      const skipHowTo =
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
        if (frontmatter.automated_tests === false) {
          message = "Tagged with automated_tests=false";
        } else {
          message = "Tagged with @todo.";
        }
        console.log(`Skipping file: ${relativeFilePath}. ${message}`);

        const name = `[${frontmatter.title}](${config.productionUrl}${howToUrl})`;
        skipped.push({
          status: "skipped",
          products: frontmatter.products,
          duration: 0,
          name,
          message,
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
  const files = await fastGlob("**/*", { cwd: config.instructionsDir });
  if (files.length === 0) {
    console.error(
      `The platform couldn't find any instructions files to run in ${config.instructionsDir}.`
    );
    console.error(`Please run \`npm run generate-instruction-files\` first`);
    process.exit(1);
  }

  return files.map((f) => path.join(config.instructionsDir, f));
}

export async function groupInstructionFilesByProductAndRuntime(files) {
  const groupedFiles = {};

  for (const file of files) {
    const data = yaml.load(await fs.readFile(`./${file}`, "utf-8"));

    const products = data.products;
    let mainProduct = products[0];
    if (products.includes("ai-gateway") && mainProduct !== "ai-gateway") {
      mainProduct = "ai-gateway";
    }
    let runtime = path.basename(file, path.extname(file));

    groupedFiles[mainProduct] = groupedFiles[mainProduct] || {};
    groupedFiles[mainProduct][runtime] =
      groupedFiles[mainProduct][runtime] || [];
    groupedFiles[mainProduct][runtime].push(file);
  }

  return groupedFiles;
}
