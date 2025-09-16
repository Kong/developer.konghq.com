import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import yaml from "js-yaml";

const baseBranch = process.env.GITHUB_BASE_REF || "main";

const diffOutput = execSync(
  `git diff --name-status origin/${baseBranch}...HEAD`,
  {
    encoding: "utf8",
  }
);

const lines = diffOutput.trim().split("\n").filter(Boolean);

const redirects = fs
  .readFileSync("../../app/_redirects", "utf8")
  .split("\n")
  .filter(Boolean);

const collectionPermalinks = (function () {
  const configFile = "../../jekyll.yml";
  let permalinks = {};
  if (fs.existsSync(configFile)) {
    const config = yaml.load(fs.readFileSync(configFile, "utf8"));
    if (config.defaults) {
      for (const def of config.defaults) {
        if (def.scope?.path?.startsWith("_") && def.values?.permalink) {
          permalinks[def.scope.path] = def.values.permalink;
        }
      }
    }
  }
  return permalinks;
})();

function readFileAtRef(file) {
  try {
    return execSync(`git show origin/${baseBranch}:${file}`, {
      encoding: "utf8",
    });
  } catch {
    return null;
  }
}

function fileToUrl(file) {
  const ext = path.extname(file);
  let rawFile;
  let frontmatter;

  if (fs.existsSync(`../../${file}`)) {
    rawFile = fs.readFileSync(`../../${file}`, "utf8");
  } else {
    rawFile = readFileAtRef(file);
  }

  if (rawFile) {
    frontmatter = matter(rawFile);
    if (frontmatter.data.permalink) {
      return frontmatter.data.permalink;
    }
  }

  for (const [collectionPath, permalinkPattern] of Object.entries(
    collectionPermalinks
  )) {
    const relativePath = file.replace("app/", "");
    if (relativePath.startsWith(collectionPath)) {
      let filePath = relativePath
        .slice(collectionPath.length + 1)
        .replace(ext, "");
      if (filePath.endsWith("index")) {
        filePath = path.dirname(filePath);
      }
      return permalinkPattern.replace(":path", filePath);
    }
  }

  if (file.startsWith("app/_landing_pages")) {
    if (frontmatter.data.permalink) {
      return frontmatter.data.permalink;
    } else {
      return file.replace("app/_landing_pages", "").replace(ext, "/");
    }
  }

  const pathWithoutExtension = file.replace(ext, "/").replace("app", "");
  if (pathWithoutExtension.endsWith("index/")) {
    return path.dirname(pathWithoutExtension);
  }
  return pathWithoutExtension;
}

function ignoreFile(file) {
  if (!file.startsWith("app/")) {
    return true;
  }

  return [
    "app/assets",
    "app/_assets",
    "app/_data",
    "app/_includes",
    "app/_layouts",
    "app/_plugins",
    "app/_indices",
    "app/.repos",
  ].some((folder) => file.startsWith(folder));
}

(async function () {
  let missingRedirects = [];

  for (const line of lines) {
    const [status, ...files] = line.split(/\s+/);

    if (status === "D" || status.startsWith("R")) {
      const filePath = files[0];
      if (ignoreFile(filePath)) {
        continue;
      }

      const oldUrl = fileToUrl(filePath);
      if (oldUrl && !redirects.some((r) => r.startsWith(oldUrl + " "))) {
        missingRedirects.push({ path: filePath, url: oldUrl, status });
      }
    }
  }

  if (missingRedirects.length > 0) {
    console.error("Missing redirects:");
    for (const m of missingRedirects) {
      if (m.status === "D") {
        console.error(`- Deleted ${m.path}, url: ${m.url}`);
      } else {
        console.error(`- Renamed ${m.path}, url: ${m.url}`);
      }
    }
    process.exit(1);
  } else {
    console.log("✅ All deleted/renamed files have redirects.");
  }
})();
