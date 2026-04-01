import fs from "fs";
import path from "path";
import fastGlob from "fast-glob";
import minimist from "minimist";
import yaml from "js-yaml";
import { compareVersions } from "./compare-versions.js";

function generateChangelogsByVersion(folderPath, version) {
  console.log(`Generating changelog files for version: ${version}.`);
  const foldersToIgnore = fs.readFileSync(
    "./config/ignored_folders.json",
    "utf-8"
  );
  const folders = fastGlob.globSync(`${folderPath}/changelog/${version}/*`, {
    onlyDirectories: true,
    ignore: JSON.parse(foldersToIgnore).map(
      (f) => `${folderPath}/changelog/${version}/${f}`
    ),
  });

  let changelog = {};
  const setup = yaml.load(fs.readFileSync("./config/setup.yaml", "utf-8"));
  folders.forEach((folder) => {
    const key = path.basename(folder);
    changelog[key] = [];
    const entries = fastGlob.globSync(`${folder}/*`);
    entries.forEach((entry) => {
      const change = yaml.load(fs.readFileSync(entry, "utf-8"));
      if (!change.hasOwnProperty("scope")) {
        change.scope = setup.defaults.scope;
      }
      if (!change.hasOwnProperty("type")) {
        change.type = setup.defaults.type;
      }
      change.type = setup.type_mappings[change.type] || change.type;

      change.message = change.message.replace(/^"([^"]*)"?\n?$/, "$1");
      if (change.scope === "Plugin") {
        const match = change.message.match(/(\*\*\s?(.*?):?\s?\*\*?)/);
        if (match && match[2]) {
          let plugin = match[2].replace(/-plugin/i, "");

          if (setup.skip_plugin_entries.includes(plugin)) {
            return;
          }
          plugin = setup.plugin_mappings[plugin] || plugin;
          change.message = change.message.replace(
            /\*\*\s?.*?:?\s?\*\*?/,
            `**${plugin}**`
          );
        }
      }
      changelog[key].push(change);
    });
  });

  const destinationPath = `./tmp/${version}.json`;
  fs.mkdirSync("./tmp", { recursive: true });
  fs.writeFileSync(destinationPath, JSON.stringify(changelog, null, 2), "utf8");
  console.log(`Changelog file written to ${destinationPath}.`);
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
