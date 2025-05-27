import fs from "fs";
import yaml from "js-yaml";
import path from "path";
import fastGlob from "fast-glob";
import mergeWith from "lodash.mergewith";
import { compareVersions } from "./compare-versions.js";

function customMerge(objValue, srcValue) {
  if (Array.isArray(objValue)) {
    return objValue.concat(srcValue);
  }
}

function generateChangelog() {
  try {
    const changelogFilePath = `../../app/_data/changelogs/gateway.json`;
    let changelog = {};
    if (fs.existsSync(changelogFilePath)) {
      changelog = JSON.parse(fs.readFileSync(changelogFilePath, "utf-8"));
    }

    let changelogByVersion = fastGlob.globSync(`./tmp/*`);
    changelogByVersion = changelogByVersion.concat(
      fastGlob.globSync(`./missing_changelogs/*`)
    );
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

    // missing entries
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

    // remove duplicate entries...
    for (const version in changelog) {
      for (const product in changelog[version]) {
        changelog[version][product] = Object.values(
          changelog[version][product].reduce((acc, obj) => {
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
  console.log("Generating gateway's changelog.json...");
  generateChangelog();
})();
