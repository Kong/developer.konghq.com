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
      frontmatter.products && frontmatter.products.includes("gateway");

    if (isTesteable) {
      const skipHowTo =
        content.includes("@todo") || frontmatter.automated_tests === false;
      const howToUrl = `/how-to/${fileToUrl(file)}`;

      if (skipHowTo) {
        const relativeFilePath = file.replace("../../", "");
        let message;
        if (frontmatter.automated_tests === false) {
          message = "Tagged with automated_tests=false";
        } else {
          message = "Tagged with @todo.";
        }
        console.log(`Skipping file: ${relativeFilePath}. ${message}`);

        skipped.push({
          name: howToUrl,
          status: "skipped",
          duration: 0,
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

export async function groupInstructionFilesByRuntime(files) {
  const groupedFiles = {};

  for (const file of files) {
    const runtime = path.basename(file, path.extname(file));
    groupedFiles[runtime] = groupedFiles[runtime] || [];
    groupedFiles[runtime].push(file);
  }

  return groupedFiles;
}
