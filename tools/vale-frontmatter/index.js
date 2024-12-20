const fs = require("fs").promises;
const fg = require("fast-glob");
const matter = require("gray-matter");
const path = require("path");

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
  let files = await fg(pattern, { cwd: "../../" });

  const frontmatterKeys = await fs.readFile(
    `../../.github/styles/frontmatter/Keys.txt`,
    "utf-8"
  );

  const frontmatterDictionary = await fs.readFile(
    `../../.github/styles/frontmatter/Dictionary.txt`,
    "utf-8"
  );

  const keys = frontmatterKeys
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  const frontmatterExceptions = frontmatterDictionary
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  for (const path of files) {
    console.log(`Processing: ${path}`);
    const contents = await fs.readFile(`../../${path}`, "utf-8");
    if (contents) {
      const parsed = matter(contents);
      let frontmatter = parsed.matter;

      if (frontmatter) {
        for (const key of keys) {
          const keyRegex = new RegExp(`^\\s*${key}:.*$`, "gm");

          frontmatter = frontmatter.replace(keyRegex, "");
        }

        for (const word of frontmatterExceptions) {
          frontmatter = frontmatter.replaceAll(word, "");
        }

        await fs.writeFile(`../../${path}`, frontmatter, "utf-8");
      }
    }
    console.log("Done.");
  }
}

if (require.main === module) {
  try {
    prepareMarkdownFilesForVale();
  } catch (e) {
    console.log(e);
  }
}

module.exports = prepareMarkdownFilesForVale;
