import { promises as fs } from "fs";
import minimist from "minimist";
import checkSite from "./lib/check-site.js";
import processResult from "./lib/process-result.js";

const argv = minimist(process.argv.slice(2));

(async function () {
  const host = argv.host;

  if (!host) {
    console.error("Please provide the --host argument");
    process.exit(1);
  }

  if (
    host.includes("https://developer.konghq.com") ||
    host.includes("http://developer.konghq.com")
  ) {
    console.error("This tool can not be run against production.");
    process.exit(1);
  }

  // Known list of exclusions
  let excluded = [];
  // Excluded external sites for full scan only
  excluded.push("https://github.com/*");

  const ignoredPaths = JSON.parse(
    await fs.readFile("./config/ignored_targets.json")
  );
  excluded = excluded.concat(ignoredPaths);

  const result = await checkSite({ excluded, host });
  processResult(result);
})();
