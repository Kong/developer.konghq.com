import fs from "fs";
import path from "path";
import fastGlob from "fast-glob";
import { compareVersions } from "./compare-versions.js";

function generateChangelog() {
  try {
    const changelogFilePath = `../../app/_data/changelogs/gateway.json`;
    let changelog = {};
    const changelogByVersion = fastGlob.globSync(`./tmp/*`);

    const orderedFiles = changelogByVersion.sort(compareVersions).reverse();
    orderedFiles.forEach((file) => {
      const version = path.basename(file, ".json");
      const entries = JSON.parse(fs.readFileSync(file, "utf-8"));
      changelog[version] = entries;
    });

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
