import fs from "fs/promises";
import { glob } from "tinyglobby";
import matter from "gray-matter";
import path from "path";
import { dump } from "js-yaml";

function fileToUrl(file) {
  return file.replace("../../app/_how-tos/", "").replace(".md", "/");
}

function logSkip(file, message) {
  console.log(`Skipping file: ${file.replace("../../", "")}. ${message}`);
}

function deriveSkipProducts(products) {
  // Mirrors extractor.js's deriveProduct special case: ai-gateway v1 how-tos are
  // tagged with both "gateway" and "ai-gateway" but only ever run as "gateway".
  if (products.includes("ai-gateway") && products.includes("gateway")) {
    return ["gateway"];
  }
  return products;
}

// A version value counts as numeric only when every dotted segment is an
// integer (`'1.3'`, `'1.1.0'`). Anything else (`'latest'`, `'next'`, unset)
// carries no version information and is ignored by the gate.
export function isNumericVersion(value) {
  if (typeof value === "number") {
    value = String(value);
  }
  if (typeof value !== "string" || value === "") {
    return false;
  }
  return value.split(".").every((segment) => /^\d+$/.test(segment));
}

export function compareVersions(a, b) {
  const aSegments = a.split(".").map(Number);
  const bSegments = b.split(".").map(Number);
  const segments = Math.max(aSegments.length, bSegments.length);

  for (let i = 0; i < segments; i++) {
    const left = aSegments[i] ?? 0;
    const right = bSegments[i] ?? 0;
    if (left !== right) {
      return left - right;
    }
  }
  return 0;
}

export function effectiveVersionUnderTest(imageTag, eventGatewayMinVersion) {
  const candidates = [imageTag, eventGatewayMinVersion].filter(isNumericVersion);

  if (candidates.length === 0) {
    return null;
  }

  return candidates.reduce((minimum, candidate) =>
    compareVersions(candidate, minimum) < 0 ? candidate : minimum,
  );
}

export async function testeableUrlsFromFiles(
  config,
  files,
  { explicit = false, imageTag, eventGatewayMinVersion } = {},
) {
  const howTosUrls = [];
  const skipped = [];
  const versionUnderTest = effectiveVersionUnderTest(
    imageTag,
    eventGatewayMinVersion,
  );

  const parsedFiles = files.map((file) => {
    const { data: frontmatter, content } = matter.read(file);
    return { file, frontmatter, content };
  });

  const seriesFirstPageTitles = {};
  for (const { frontmatter } of parsedFiles) {
    if (frontmatter.series && frontmatter.series.position === 1) {
      seriesFirstPageTitles[frontmatter.series.id] = frontmatter.title;
    }
  }

  for (const { file, frontmatter, content } of parsedFiles) {
    const isTesteable =
      frontmatter.products &&
      (frontmatter.products.includes("gateway") ||
        frontmatter.products.includes("ai-gateway") ||
        frontmatter.products.includes("event-gateway") ||
        frontmatter.products.includes("operator"));

    if (isTesteable) {
      const isNonFirstSeriesPage =
        frontmatter.series && frontmatter.series.position !== 1;

      if (isNonFirstSeriesPage && explicit) {
        const relativeFilePath = file.replace("../../", "");
        throw new Error(
          `${relativeFilePath} is part of series "${frontmatter.series.id}" but is not the ` +
          `first page (position ${frontmatter.series.position}). Target the first page of ` +
          `the series instead.`
        );
      }

      const requiredEventGatewayVersion =
        frontmatter.min_version && frontmatter.min_version["event-gateway"]
          ? String(frontmatter.min_version["event-gateway"])
          : null;
      const needsNewerEventGateway =
        versionUnderTest &&
        frontmatter.products.includes("event-gateway") &&
        isNumericVersion(requiredEventGatewayVersion) &&
        compareVersions(requiredEventGatewayVersion, versionUnderTest) > 0;

      if (needsNewerEventGateway && explicit) {
        const relativeFilePath = file.replace("../../", "");
        throw new Error(
          `${relativeFilePath} requires Event Gateway >= ${requiredEventGatewayVersion}, ` +
          `but the version under test is ${versionUnderTest}. ` +
          `Unset KONG_IMAGE_TAG and KONNECT_EVENT_GATEWAY_MIN_VERSION to generate it anyway.`
        );
      }

      const skipHowTo =
        isNonFirstSeriesPage ||
        content.includes("@todo") ||
        frontmatter.automated_tests === false ||
        frontmatter.published === false ||
        needsNewerEventGateway;

      let howToUrl;
      if (frontmatter.permalink) {
        howToUrl = frontmatter.permalink;
      } else {
        howToUrl = `/how-to/${fileToUrl(file)}`;
      }

      if (skipHowTo) {
        let message;
        let reason = "excluded";
        if (isNonFirstSeriesPage) {
          const firstPageTitle =
            seriesFirstPageTitles[frontmatter.series.id] || "the series' first page";
          message = `Part of series "${frontmatter.series.id}", tested via "${firstPageTitle}"`;
          reason = "series";
        } else if (frontmatter.automated_tests === false) {
          message = "Tagged with automated_tests=false";
        } else if (frontmatter.published === false) {
          message = "Tagged with published=false";
        } else if (needsNewerEventGateway) {
          message = `Requires Event Gateway >= ${requiredEventGatewayVersion}, generating for ${versionUnderTest}`;
          reason = "min-version";
        } else {
          message = "Tagged with @todo.";
        }
        logSkip(file, message);

        const name = `[${frontmatter.title}](${config.productionUrl}${howToUrl})`;
        skipped.push({
          status: "skipped",
          products: deriveSkipProducts(frontmatter.products),
          duration: 0,
          name,
          message,
          reason,
        });
      } else {
        howTosUrls.push(`${config.baseUrl}${howToUrl}`);
      }
    } else {
      // Say so out loud: a silent drop looks the same as a deliberate
      // exclusion, so a missing or misspelled product tag goes unnoticed.
      const products = frontmatter.products || [];
      logSkip(
        file,
        products.length
          ? `Products (${products.join(", ")}) include no testable product`
          : "No products in frontmatter, so nothing to test",
      );
    }
  }
  await fs.writeFile(".automated-tests", dump(skipped), "utf-8");

  return howTosUrls;
}

export async function instructionFileFromConfig(config) {
  const files = await glob("**/*", { cwd: config.instructionsDir });
  if (files.length === 0) {
    console.error(
      `The platform couldn't find any instructions files to run in ${config.instructionsDir}.`
    );
    console.error(`Please run \`npm run generate-instruction-files\` first`);
    process.exit(1);
  }

  return files.map((f) => path.join(config.instructionsDir, f));
}

export async function groupInstructionFilesByDeploymentModelAndProduct(files) {
  const groupedFiles = {};

  for (const file of files) {
    // Deployment model is the parent directory name (e.g., "on-prem" or "konnect")
    const deploymentModel = path.basename(path.dirname(file));

    // Product is the file basename without extension (e.g., "gateway", "operator")
    const product = path.basename(file, path.extname(file));

    groupedFiles[deploymentModel] = groupedFiles[deploymentModel] || {};
    groupedFiles[deploymentModel][product] =
      groupedFiles[deploymentModel][product] || [];
    groupedFiles[deploymentModel][product].push(file);
  }

  return groupedFiles;
}

// Pure filter over the grouped instruction files. `products` is the split
// PRODUCTS env var; `deploymentModel` is the DEPLOYMENT_MODEL env var or
// undefined to run every deployment model. Returns a new object of the same
// shape, holding only the matching groups. An empty object means the filters
// matched nothing, which the caller reports as a hard failure.
export function selectRunnableGroups(groups, products, deploymentModel) {
  const selected = {};

  for (const [model, instructionFilesByProduct] of Object.entries(groups)) {
    if (deploymentModel && deploymentModel !== model) {
      continue;
    }

    for (const [product, instructionFiles] of Object.entries(
      instructionFilesByProduct,
    )) {
      if (products.includes(product)) {
        selected[model] = selected[model] || {};
        selected[model][product] = instructionFiles;
      }
    }
  }

  return selected;
}
