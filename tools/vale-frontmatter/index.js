import fs from "fs/promises";
import { glob } from "tinyglobby";
import matter from "gray-matter";
import yaml from "js-yaml";
import path from "path";
import { fileURLToPath } from "url";

async function pathExists(path) {
  try {
    await fs.access(path);
    return true;
  } catch (e) {
    return false;
  }
}

async function prepareMarkdownFilesForVale() {
  const filesParam = process.argv.slice(2)[0] || "app/**/*.md";
  let pattern;

  if (await pathExists(path.resolve("../../", filesParam))) {
    pattern = [`${filesParam}/**/*.md`];
  } else {
    try {
      pattern = JSON.parse(filesParam);
    } catch (e) {
      console.log("Invalid path, defaulting to app/**/*.md");
      pattern = ["app/**/*.md"];
    }
  }
  let files = await glob(pattern, { cwd: "../../" });

  const frontmatterKeys = await fs.readFile(
    `../../.github/styles/frontmatter/Keys.txt`,
    "utf-8"
  );

  const keys = frontmatterKeys
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  for (const path of files) {
    console.log(`Processing: ${path}`);
    const contents = await fs.readFile(`../../${path}`, "utf-8");
    if (contents) {
      const parsed = matter(contents);
      const data = parsed.data;

      if (data && typeof data === "object") {
        for (const key of keys) {
          delete data[key];
        }

        const remaining = yaml.dump(data, { lineWidth: -1 });
        await fs.writeFile(`../../${path}`, remaining, "utf-8");
      }
    }
    console.log("Done.");
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    prepareMarkdownFilesForVale();
  } catch (e) {
    console.log(e);
  }
}

export default prepareMarkdownFilesForVale;
