import fs from "node:fs/promises";
import YAML from "yaml";
import minimist from "minimist";

const insomniaPrefixes = ["/insomnia/", "/inso-cli/"];

async function getUrlMappings() {
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

async function getSources() {
  const filePath = "./config/sources.yml";
  try {
    const config = await fs.readFile(filePath, {
      encoding: "utf8",
    });

    return YAML.parse(config);
  } catch (err) {
    console.error(err);
    console.error(`There's was an error while reading ${filePath}`);
    process.exit(1);
  }
}

async function filterUrlsByRepo(urls, repo) {
  let filteredUrls = urls;

  if (repo === "docs") {
    filteredUrls = urls.filter(
      (u) => !insomniaPrefixes.some((prefix) => u.startsWith(prefix))
    );
  }
  // return everything for insomnia because of how-tos, etc
  return filteredUrls;
}

async function filterFilesByRepo(files, repo) {
  let filteredFiles;

  if (repo === "insomnia") {
    filteredFiles = files.filter((f) =>
      insomniaPrefixes.some((prefix) => f.startsWith(prefix))
    );
  } else {
    filteredFiles = files.filter(
      (f) => !insomniaPrefixes.some((prefix) => f.startsWith(prefix))
    );
  }
  return filteredFiles;
}

async function devSiteUrlsToExternalSourceFileMappings(
  sources,
  mappings,
  repo
) {
  const urlsToSourceFiles = {};

  console.log("Mapping entries in sources.yml to dev site urls...");
  for (const [devSiteFile, sourceFiles] of Object.entries(sources)) {
    const devSiteUrls = mappings[devSiteFile];

    if (devSiteUrls === undefined) {
      console.log(`Missing url for file: ${devSiteFile}`);
    } else {
      // filter insomnia/docs urls
      const filteredUrls = await filterUrlsByRepo(devSiteUrls, repo);
      filteredUrls.forEach((url) => {
        urlsToSourceFiles[url] ||= sourceFiles;
      });
    }
  }

  return urlsToSourceFiles;
}

async function externalSourceFileToDevSiteUrlMappings(mappings, repo) {
  const sources = {};
  let kumaSources = {};

  for (const [devSiteUrl, sourceFiles] of Object.entries(mappings)) {
    const filteredSourceFiles = await filterFilesByRepo(sourceFiles, repo);
    // filter source files, some insomnia pages are how-tos...
    filteredSourceFiles.forEach((sourceFile) => {
      sources[sourceFile] ||= [];
      sources[sourceFile].push(devSiteUrl);
    });
  }

  if (repo === "docs") {
    kumaSources = await kumaSubmoduleMappings();
  }

  return { ...sources, ...kumaSources };
}

async function kumaSources() {
  const filePath = "../../app/_data/kuma_to_mesh/config.yaml";
  try {
    const config = await fs.readFile(filePath, {
      encoding: "utf8",
    });

    const pages = YAML.parse(config).pages;
    const mappings = {};

    pages.forEach((page) => {
      mappings[page.path] = [page.url];
    });

    return mappings;
  } catch (err) {
    console.error(err);
    console.error(`There's an error while reading kuma to mesh config`);
    process.exit(1);
  }
}

async function kumaSubmoduleMappings() {
  const sources = await kumaSources();
  const mappings = {};

  for (const [sourceFile, devSiteUrls] of Object.entries(sources)) {
    // Mapping in docs repo
    mappings[`app/_src/.repos/kuma/${sourceFile}`] = devSiteUrls;
  }

  return mappings;
}

async function missingSourcesConfig() {
  const config = await fs.readFile("./config/missing_sources.yml", {
    encoding: "utf8",
  });
  return YAML.parse(config);
}

async function checkForMissingSourceFileMappingsToExternalSources(
  sources,
  sourcesUrlsMapping
) {
  let missing = [];
  const kumaToMeshSources = await kumaSources();
  const config = await missingSourcesConfig();

  const kumaToMeshSourcesDevSitePaths = {};
  // convert path in kuma_to_mesh/config.yaml to path in the dev site
  for (const [sourceFile, devSiteUrls] of Object.entries(kumaToMeshSources)) {
    kumaToMeshSourcesDevSitePaths[`app/.repos/kuma/${sourceFile}`] =
      devSiteUrls;
  }

  for (const sourceFile of Object.keys(sourcesUrlsMapping)) {
    if (config.ignoredPaths.some((path) => sourceFile.startsWith(path))) {
      console.log(`Skipping ${sourceFile}`);
      continue;
    }
    const missingSource =
      sources[sourceFile] === undefined &&
      kumaToMeshSourcesDevSitePaths[sourceFile] === undefined;
    if (missingSource) {
      missing.push(sourceFile);
    }
  }
  return missing;
}

(async function main() {
  const args = minimist(process.argv.slice(2));
  const repos = ["docs", "insomnia"];
  const repo = args.repo ? args.repo : "docs";

  if (!repos.includes(repo)) {
    console.error(`Invalid value '${repo}' for repo, valid values: ${repos}.`);
    process.exit(1);
  }

  const sources = await getSources();
  const mappings = await getUrlMappings();

  console.log("Checking for missing sources...");
  const missingSources =
    await checkForMissingSourceFileMappingsToExternalSources(sources, mappings);

  await fs.writeFile(
    "dev_site_files_without_sources.yaml",
    YAML.stringify(missingSources),
    "utf-8"
  );

  const devSiteUrlToSourceMappings =
    await devSiteUrlsToExternalSourceFileMappings(sources, mappings, repo);

  let result = await externalSourceFileToDevSiteUrlMappings(
    devSiteUrlToSourceMappings,
    repo
  );

  await fs.writeFile(
    "source_files_to_dev_site_urls.yaml",
    YAML.stringify(result),
    "utf-8"
  );
})();
