import fastGlob from "fast-glob";
import matter from "gray-matter";
import path from "path";

export async function testeableUrlsFromFiles(config, files) {
  const howTosUrls = [];

  for (const file of files) {
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
          console.log(
            `Skipping file: ${relativeFilePath}, it's tagged with automated_tests=false`
          );
        } else {
          console.log(
            `Skipping file: ${relativeFilePath}, it's tagged with @todo.`
          );
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
