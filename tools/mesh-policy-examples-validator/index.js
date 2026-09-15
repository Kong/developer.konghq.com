import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { glob } from "tinyglobby";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { resolveRelease } from "./lib/release.js";
import { loadCrds } from "./lib/crds.js";
import { extractDocuments } from "./lib/extract.js";
import { findNullValues, findMarkerFields, checkSchema } from "./lib/rules.js";
import { builtPageToSourcePath } from "./lib/paths.js";
import { checkPreconditions } from "./lib/preconditions.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");

const BUILT_PAGES_GLOB = "dist/mesh/policies/*/examples/*/index.html";
const SOURCE_EXAMPLES_GLOB = "app/_mesh_policies/*/examples/*.{yaml,yml}";

function parseArgs(argv) {
  const versionIndex = argv.indexOf("--version");
  const version = versionIndex === -1 ? undefined : argv[versionIndex + 1];
  const rootIndex = argv.indexOf("--root");
  const root = rootIndex === -1 ? undefined : argv[rootIndex + 1];
  return { version, root };
}

// --root points the validator at a fixture directory laid out like a repo
// root; test/cli.test.js is the only caller, to exercise the CLI end to end
// without a real production build.
export async function run(argv, root) {
  const { version, root: rootArg } = parseArgs(argv);
  root = root ?? (rootArg ? path.resolve(rootArg) : ROOT);

  const { release, crdsDir } = resolveRelease(root, version);
  console.log(`Using mesh release: ${release}`);

  const crds = loadCrds(crdsDir);

  const builtPages = await glob(BUILT_PAGES_GLOB, { cwd: root });
  const sourceExamples = await glob(SOURCE_EXAMPLES_GLOB, { cwd: root });

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
      `${findings.length} finding(s).`,
  );

  return findings.length > 0 ? 1 : 0;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  run(process.argv.slice(2)).then((code) => process.exit(code));
}
