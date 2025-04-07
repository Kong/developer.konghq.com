import fs from "fs";
import path from "path";
import fastGlob from "fast-glob";
import minimist from "minimist";
import yaml from "js-yaml";

function generateChangelogsByVersion(folderPath, version) {
  console.log(`Generating changelog files for version: ${version}.`);
  const foldersToIgnore = fs.readFileSync(
    "./config/ignored_folders.json",
    "utf-8"
  );
  // Questions: do I need to bundle enterprise and OSS?
  const folders = fastGlob.globSync(`${folderPath}/changelog/${version}/*`, {
    onlyDirectories: true,
    ignore: JSON.parse(foldersToIgnore).map(
      (f) => `${folderPath}/changelog/${version}/${f}`
    ),
  });

  let changelog = {};
  folders.forEach((folder) => {
    const key = path.basename(folder);
    changelog[key] = [];
    const entries = fastGlob.globSync(`${folder}/*`);
    entries.forEach((entry) => {
      changelog[key].push(yaml.load(fs.readFileSync(entry, "utf-8")));
    });
  });

  const destinationPath = `../../app/_data/changelog/gateway/${version}.json`;
  fs.writeFileSync(destinationPath, JSON.stringify(changelog, null, 2), "utf8");
  console.log(`Changelog file written to ${destinationPath}.`);
}

function compareVersions(a, b) {
  const aParts = a.split(".").map(Number);
  const bParts = b.split(".").map(Number);
  const maxLength = Math.max(aParts.length, bParts.length);

  for (let i = 0; i < maxLength; i++) {
    const aVal = aParts[i] === undefined ? 0 : aParts[i];
    const bVal = bParts[i] === undefined ? 0 : bParts[i];

    if (aVal < bVal) {
      return -1;
    }
    if (aVal > bVal) {
      return 1;
    }
  }

  return 0;
}

function fetchVersions(path) {
  const versions = fastGlob.globSync("[0-9]*", {
    cwd: `${path}/changelog/`,
    onlyDirectories: true,
  });
  return versions.sort(compareVersions);
}

(function main() {
  const args = minimist(process.argv.slice(2), { string: ["version"] });

  try {
    if (!args.path) {
      console.error(
        "Missing argument --path, relative path to the kong-ee repo."
      );
    }

    if (args.version) {
      generateChangelogsByVersion(args.path, args.version);
    } else {
      const versions = fetchVersions(args.path);
      versions.forEach((version) => {
        generateChangelogsByVersion(args.path, version);
      });
    }
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
})();
