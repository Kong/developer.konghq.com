import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { glob } from "tinyglobby";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { resolveRelease, latestMajor } from "./lib/release.js";
import { loadCrds } from "./lib/crds.js";
import { extractDocuments } from "./lib/extract.js";
import { findNullValues, findMarkerFields, checkSchema } from "./lib/rules.js";
import {
  builtPageToSourcePath,
  parseBuiltPage,
  parseSourceExample,
} from "./lib/paths.js";
import { checkPreconditions } from "./lib/preconditions.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");

const BUILT_PAGES_GLOBS = [
  "dist/mesh/policies/*/examples/*/index.html",
  "dist/mesh/v2/policies/*/examples/*/index.html",
];
const SOURCE_EXAMPLES_GLOBS = [
  "app/_mesh_policies/*/examples/*.{yaml,yml}",
  "app/_mesh_policies/v2/*/examples/*.{yaml,yml}",
];

function parseArgs(argv) {
  if (argv.includes("--version")) {
    throw new Error(
      "--version is no longer supported: the validator resolves and checks " +
        "every mesh major present in the build.",
    );
  }
  const rootIndex = argv.indexOf("--root");
  const root = rootIndex === -1 ? undefined : argv[rootIndex + 1];
  const skipIndex = argv.indexOf("--skip");
  const skip =
    skipIndex === -1
      ? []
      : argv[skipIndex + 1]
          .split(",")
          .filter((entry) => entry.length > 0)
          .map(parseSkipEntry);
  return { root, skip };
}

// A skip entry is `<policy>` (every major) or `<policy>@v<major>` (that
// major only), e.g. `meshaccesslog@v2`.
function parseSkipEntry(entry) {
  const at = entry.indexOf("@");
  if (at === -1) return { name: entry, major: undefined };
  const name = entry.slice(0, at);
  const major = Number(entry.slice(at + 1).replace(/^v/, ""));
  if (name.length === 0 || !Number.isInteger(major) || major < 1) {
    throw new Error(
      `Invalid --skip entry "${entry}". Use <policy> or <policy>@v<major>.`,
    );
  }
  return { name, major };
}

function skipEntryLabel(entry) {
  return entry.major === undefined
    ? entry.name
    : `${entry.name}@v${entry.major}`;
}

function excludeSkippedPolicies(paths, skip, parse, latest) {
  if (skip.length === 0) return paths;
  return paths.filter(
    (p) =>
      !skip.some((entry) => {
        const { policy, major } = parse(p);
        return (
          entry.name === policy &&
          (entry.major === undefined || entry.major === (major ?? latest))
        );
      }),
  );
}

// --root points the validator at a fixture directory laid out like a repo
// root; test/cli.test.js is the only caller, to exercise the CLI end to end
// without a real production build.
export async function run(argv, root) {
  const { root: rootArg, skip } = parseArgs(argv);
  root = root ?? (rootArg ? path.resolve(rootArg) : ROOT);

  const latest = latestMajor(root);

  const builtPages = excludeSkippedPolicies(
    await glob(BUILT_PAGES_GLOBS, { cwd: root }),
    skip,
    parseBuiltPage,
    latest,
  );
  const sourceExamples = excludeSkippedPolicies(
    await glob(SOURCE_EXAMPLES_GLOBS, { cwd: root }),
    skip,
    parseSourceExample,
    latest,
  );

  const majors = new Set(
    builtPages.map((page) => parseBuiltPage(page).major ?? latest),
  );

  const releasesByMajor = new Map();
  try {
    for (const major of [...majors].sort((a, b) => a - b)) {
      const { release, crdsDir } = resolveRelease(root, major);
      releasesByMajor.set(major, { release, crds: loadCrds(crdsDir) });
    }
  } catch (err) {
    console.error(err.message);
    return 1;
  }
  console.log(
    `Using mesh releases: ${[...releasesByMajor]
      .map(([major, { release }]) => `major ${major} -> ${release}`)
      .join(", ")}.`,
  );

  const preconditions = checkPreconditions(builtPages, sourceExamples);
  if (!preconditions.ok) {
    console.error(preconditions.message);
    return 1;
  }

  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);

  const findings = [];
  let blocksChecked = 0;
  let blocksWithCoverage = 0;

  for (const builtPage of builtPages) {
    const { crds } = releasesByMajor.get(
      parseBuiltPage(builtPage).major ?? latest,
    );
    const sourcePath = builtPageToSourcePath(root, builtPage);
    const relativeSource = path.relative(root, sourcePath);
    const html = fs.readFileSync(path.join(root, builtPage), "utf-8");

    const { entries, findings: parseFindings } = extractDocuments(html);
    for (const finding of parseFindings) {
      findings.push({ source: relativeSource, ...finding });
    }

    for (const block of entries) {
      blocksChecked++;

      for (const pointer of findNullValues(block.value)) {
        findings.push({
          source: relativeSource,
          panel: block.panel,
          pointer,
          message: "value is null",
        });
      }

      for (const pointer of findMarkerFields(block.value)) {
        findings.push({
          source: relativeSource,
          panel: block.panel,
          pointer,
          message: "renderer marker field survived rendering",
        });
      }

      const { findings: schemaFindings, hasCoverage } = checkSchema(
        block,
        crds,
        ajv,
      );
      if (hasCoverage) blocksWithCoverage++;
      for (const finding of schemaFindings) {
        findings.push({
          source: relativeSource,
          panel: block.panel,
          ...finding,
        });
      }
    }
  }

  for (const finding of findings) {
    console.log(
      `${finding.source} [${finding.panel ?? "-"}] ${finding.pointer}: ${finding.message}`,
    );
  }

  console.log(
    `\nChecked ${builtPages.length} pages, ${blocksChecked} blocks ` +
      `(${blocksWithCoverage} with meaningful schema coverage). ` +
      `${findings.length} finding(s).` +
      (skip.length > 0
        ? ` Skipped: ${skip.map(skipEntryLabel).join(", ")}.`
        : ""),
  );

  return findings.length > 0 ? 1 : 0;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  run(process.argv.slice(2)).then(
    (code) => process.exit(code),
    (err) => {
      console.error(err.message);
      process.exit(1);
    },
  );
}
