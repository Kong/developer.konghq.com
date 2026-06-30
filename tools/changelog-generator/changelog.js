import fs from "fs";
import yaml from "js-yaml";
import path from "path";
import { globSync } from "tinyglobby";
import mergeWith from "lodash.mergewith";
import minimist from "minimist";
import { compareVersions } from "./compare-versions.js";

function customMerge(objValue, srcValue) {
  if (Array.isArray(objValue)) {
    return objValue.concat(srcValue);
  }
}

function generateChangelog(product) {
  try {
    const changelogFilePath = `../../app/_changelogs/${product}.json`;
    let changelog = {};
    if (fs.existsSync(changelogFilePath)) {
      changelog = JSON.parse(fs.readFileSync(changelogFilePath, "utf-8"));
    }

    let changelogByVersion = globSync(`./tmp/${product}/*`);
    if (product === "gateway") {
      changelogByVersion = changelogByVersion.concat(
        globSync(`./missing_changelogs/*`)
      );
    }
    const orderedFiles = changelogByVersion.sort(compareVersions).reverse();

    // changelog files
    orderedFiles.forEach((file) => {
      const version = path.basename(file, ".json");
      const entries = JSON.parse(fs.readFileSync(file, "utf-8"));

      if (changelog[version]) {
        changelog[version] = mergeWith(
          {},
          changelog[version],
          entries,
          customMerge
        );
      } else {
        changelog[version] = entries;
      }
    });

    // missing entries (gateway only)
    if (product === "gateway") {
      const entries_by_version = {};
      const baseDir = "./missing_entries";
      const versionDirs = fs.readdirSync(baseDir, { withFileTypes: true });

      versionDirs.forEach((dirent) => {
        if (dirent.isDirectory()) {
          const version = dirent.name;
          const versionPath = path.join(baseDir, version);

          const files = fs
            .readdirSync(versionPath)
            .map((file) => "./" + path.join(versionPath, file));

          const entries = files.flatMap((f) =>
            yaml.load(fs.readFileSync(f, "utf-8"))
          );
          entries_by_version[version] = entries;
        }
      });

      for (const version in entries_by_version) {
        if (changelog[version]) {
          changelog[version] = mergeWith(
            {},
            changelog[version],
            { "kong-ee": entries_by_version[version] },
            customMerge
          );
        } else {
          changelog[version] = { "kong-ee": entries_by_version[version] };
        }
      }
    }

    // remove duplicate entries...
    for (const version in changelog) {
      for (const component in changelog[version]) {
        changelog[version][component] = Object.values(
          changelog[version][component].reduce((acc, obj) => {
            acc[obj.message] = obj;
            return acc;
          }, {})
        );
      }
    }

    fs.writeFileSync(
      changelogFilePath,
      JSON.stringify(changelog, null, 2),
      "utf8"
    );
    console.log(`Changelog file written to ${changelogFilePath}.`);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
}

(function main() {
  const args = minimist(process.argv.slice(2), { string: ["product"] });
  const product = args.product || "gateway";

  if (!['gateway', 'ai-gateway'].includes(product)) {
    console.error(`Unknown --product "${product}": must be "gateway" or "ai-gateway"`);
    process.exit(1);
  }

  console.log(`Generating ${product}'s changelog.json...`);
  generateChangelog(product);
})();
