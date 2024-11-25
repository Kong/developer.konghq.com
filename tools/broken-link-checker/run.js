import { Octokit } from "@octokit/rest";
import { context } from "@actions/github";
import minimist from "minimist";
import fg from "fast-glob";
import { promises as fs } from "fs";
import checkUrls from "./lib/check-url-list.js";
import processResult from "./lib/process-result.js";

const argv = minimist(process.argv.slice(2));

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN,
});

async function getPRFiles(options) {
  if (context.repo.owner) {
    options = { ...context.repo, ...options };
  }

  const files = await octokit.paginate(
    octokit.rest.pulls.listFiles,
    options,
    (response) => response.data
  );

  const fileList = files.map((f) => f.filename);

  return fileList;
}

async function getSourceUrlsMappings() {
  const filePath = "../../dist/sources_urls_mapping.json";
  try {
    const data = await fs.readFile(filePath, {
      encoding: "utf8",
    });
    return JSON.parse(data);
  } catch (err) {
    console.error(err);
    console.error(`There's was an error while reading ${filePath}`);
    process.exit(1);
  }
}

async function filterIgnoredPaths(urlsToCheck) {
  let ignoredPaths = await fs.readFile("./config/ignored_paths.json");

  ignoredPaths = JSON.parse(ignoredPaths).map((r) => new RegExp(r));

  const ignoredUrls = [];
  let filteredUrls = urlsToCheck;

  filteredUrls = filteredUrls.filter((u) => {
    const shouldIgnore = ignoredPaths.some((item) => {
      if (u.url.match(item)) {
        ignoredUrls.push(`${u.url} (${item})`);
        return true;
      }
      return false;
    });
    return !shouldIgnore;
  });

  if (ignoredUrls.length) {
    console.log("Ignoring the following URLs");
    console.table(ignoredUrls);
  }
  return filteredUrls;
}

async function urlsToCheck(files, options) {
  let mappings = await getSourceUrlsMappings();
  let filteredMappings = Object.fromEntries(
    files
      .map((file) => [file, mappings[file]])
      .filter(([_, value]) => value != null)
  );

  let urlsToCheck = Object.entries(filteredMappings).flatMap(([file, urls]) =>
    urls.map((url) => ({ source: file, url }))
  );

  if (urlsToCheck.length) {
    urlsToCheck = await filterIgnoredPaths(urlsToCheck);
  }

  return urlsToCheck.map((u) => {
    return { ...u, url: `${options.baseUrl}${u.url}` };
  });
}

async function urlsFromPR(options) {
  console.log(
    `Loading changed files for PR ${options.prNumber} (fork: ${options.isFork}).`
  );
  let changedFiles = await getPRFiles({ pull_number: options.prNumber });
  const urls = await urlsToCheck(changedFiles, options);

  return urls;
}

async function urlsFromFiles(options) {
  let changedFiles = await fg(options.files, {
    cwd: "../../",
  });
  const urls = await urlsToCheck(changedFiles, options);
  return urls;
}

(async function main() {
  const baseUrl = argv.base_url || "http://localhost:8888";
  const type = argv._[0];

  if (
    baseUrl.includes("https://developer.konghq.com") ||
    baseUrl.includes("http://developer.konghq.com")
  ) {
    console.error("This tool can not be run against production.");
    process.exit(1);
  }
  // Are there any additional patterns to ignore failures on?
  let ignore = argv.ignore || [];
  if (typeof ignore === "string") {
    ignore = [ignore];
  }
  const ignoreFailures = ignore.map((i) => new RegExp(i));

  let options = { baseUrl, ignore: ignoreFailures };
  let urls = [];

  if (type === "pr") {
    options.prNumber = argv.prNumber || context.issue.number;
    options.isFork =
      argv.isFork !== undefined
        ? argv.isFork
        : context.payload.pull_request.head.repo.fork;
    options.skipEditLink = options.isFork;
    urls = await urlsFromPR(options);
  } else if (type === undefined) {
    options.skipEditLink = true;
    if (argv.files === undefined) {
      console.error("Missing flag --files.");
      process.exit(1);
    }
    options.files = argv.files;
    urls = await urlsFromFiles(options);
  }

  if (urls.length) {
    console.log(`Checking the following URLs on ${baseUrl}`);
    console.table(urls);

    console.log("Checking URLs...");
    const result = await checkUrls(urls, options);

    processResult(result);
  } else {
    console.log("No URLs detected to test.");
  }
})();
