import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";
import { glob } from "tinyglobby";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { resolveRelease, latestMajor } from "./lib/release.js";
import { loadCrds } from "./lib/crds.js";
import {
  countPolicyYamlGroups,
  countPolicyYamlInstances,
  extractDocuments,
  extractTerraformBlocks,
} from "./lib/extract.js";
import { findNullValues, findMarkerFields, checkSchema } from "./lib/rules.js";
import { checkHclGrammar, checkProviderSchema } from "./lib/terraform.js";
import {
  builtPageToSourcePath,
  otherSourceToBuiltPath,
  overviewSourceToBuiltPath,
  parseBuiltPage,
  parseOtherSource,
  parseOverviewSource,
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
const OVERVIEW_SOURCES_GLOBS = [
  "app/_mesh_policies/*/index.md",
  "app/_mesh_policies/v2/*/index.md",
];
const OTHER_SOURCES_GLOBS = ["app/mesh/*.md", "app/mesh/v2/*.md"];

const TERRAFORM_VALIDATE_MODES = new Set(["off", "warn", "gate"]);

function parseTerraformValidate(argv) {
  const index = argv.findIndex(
    (arg) => arg === "--terraform-validate" || arg.startsWith("--terraform-validate="),
  );
  if (index === -1) return "gate";
  const arg = argv[index];
  const value = arg.includes("=")
    ? arg.slice(arg.indexOf("=") + 1)
    : argv[index + 1];
  if (!TERRAFORM_VALIDATE_MODES.has(value)) {
    throw new Error(
      `Invalid --terraform-validate value "${value}". Use off, warn, or gate.`,
    );
  }
  return value;
}

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
  const terraformValidate = parseTerraformValidate(argv);
  return { root, skip, terraformValidate };
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

function isAdvisory(finding) {
  return (finding.severity ?? "gating") === "advisory";
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

// A skip entry names a policy folder (examples, overviews) or a mesh page slug
// (others); the slug plays the policy-name role for exclusion matching.
function parseOtherForSkip(sourcePath) {
  const parsed = parseOtherSource(sourcePath);
  return parsed && { policy: parsed.slug, major: parsed.major };
}

function usesPolicyYaml(root, sourcePath) {
  return /\{%\s*policy_yaml/.test(
    fs.readFileSync(path.join(root, sourcePath), "utf-8"),
  );
}

// A finding names the instance ordinal only on multi-instance pages; single-
// instance pages keep the plain panel format.
function panelLabel(page, block) {
  if (!page.multiInstance) return block.panel;
  return `${block.panel}, block ${block.instance}`;
}

// --root points the validator at a fixture directory laid out like a repo
// root; test/cli.test.js is the only caller, to exercise the CLI end to end
// without a real production build.
export async function run(argv, root) {
  const { root: rootArg, skip, terraformValidate } = parseArgs(argv);
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
  const overviewSources = excludeSkippedPolicies(
    await glob(OVERVIEW_SOURCES_GLOBS, { cwd: root }),
    skip,
    parseOverviewSource,
    latest,
  ).filter((source) => usesPolicyYaml(root, source));
  const otherSources = excludeSkippedPolicies(
    await glob(OTHER_SOURCES_GLOBS, { cwd: root }),
    skip,
    parseOtherForSkip,
    latest,
  ).filter((source) => usesPolicyYaml(root, source));

  const majors = new Set([
    ...builtPages.map((page) => parseBuiltPage(page).major ?? latest),
    ...overviewSources.map((source) => parseOverviewSource(source).major ?? latest),
    ...otherSources.map((source) => parseOtherSource(source).major ?? latest),
  ]);

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

  const preconditions = checkPreconditions(
    builtPages,
    sourceExamples,
    overviewSources,
    otherSources,
    root,
  );
  if (!preconditions.ok) {
    console.error(preconditions.message);
    return 1;
  }

  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);

  const findings = [];
  let blocksWithCoverage = 0;
  let pluginCacheDir;
  const terraformEnv = () => {
    pluginCacheDir ??= fs.mkdtempSync(path.join(os.tmpdir(), "mesh-policy-tf-cache-"));
    return { ...process.env, TF_PLUGIN_CACHE_DIR: pluginCacheDir };
  };

  // One phase per page class (design decision 1 and 5). Discovery is
  // source-driven: a built page under the policies URL space with no source
  // (a parked page like mutual-tls) is never checked.
  const classes = [
    {
      label: "Policy example pages",
      summaryLabel: "policy example pages",
      checkInstanceCount: false,
      pages: builtPages.map((builtPage) => ({
        relativeSource: path.relative(root, builtPageToSourcePath(root, builtPage)),
        builtPath: builtPage,
        crds: releasesByMajor.get(parseBuiltPage(builtPage).major ?? latest).crds,
      })),
    },
    {
      label: "Policy overview pages",
      summaryLabel: "policy overview pages",
      checkInstanceCount: true,
      pages: overviewSources.map((source) => ({
        relativeSource: source,
        builtPath: overviewSourceToBuiltPath(source),
        crds: releasesByMajor.get(parseOverviewSource(source).major ?? latest).crds,
      })),
    },
    {
      label: "Other mesh pages",
      summaryLabel: "other mesh pages",
      checkInstanceCount: true,
      pages: otherSources.map((source) => ({
        relativeSource: source,
        builtPath: otherSourceToBuiltPath(source),
        crds: releasesByMajor.get(parseOtherSource(source).major ?? latest).crds,
      })),
    },
  ];

  let totalPages = 0;
  let totalBlocks = 0;
  let totalTerraformBlocks = 0;
  const ranPhases = [];

  for (const cls of classes) {
    // A phase whose every page is excluded prints nothing.
    if (cls.pages.length === 0) continue;

    console.log(`${cls.label}:`);

    // Parse every page of the phase once, so the three checking steps do not
    // re-read the built pages.
    const pages = cls.pages.map((page) => {
      const html = fs.readFileSync(path.join(root, page.builtPath), "utf-8");
      const { entries, findings: parseFindings } = extractDocuments(html);
      const groupCount = countPolicyYamlGroups(html);
      const sourceCount = cls.checkInstanceCount
        ? countPolicyYamlInstances(
            fs.readFileSync(path.join(root, page.relativeSource), "utf-8"),
          )
        : undefined;
      return {
        ...page,
        entries,
        parseFindings,
        tfBlocks: extractTerraformBlocks(html),
        groupCount,
        sourceCount,
        // The instance ordinal is driven by the source instance count: a page
        // whose source holds several policy_yaml instances labels its
        // findings with the ordinal even when the build rendered fewer
        // groups, and a stale build cannot add ordinals to a
        // single-instance page. Example pages have no policy_yaml source
        // tag, so their group count is the only available signal.
        multiInstance: (sourceCount ?? groupCount) > 1,
      };
    });

    // The instance-count rule (design decision 3): every source instance must
    // render. A mismatch is a gating finding, not a precondition: the run
    // still checks every page.
    if (cls.checkInstanceCount) {
      for (const page of pages) {
        if (page.sourceCount !== page.groupCount) {
          findings.push({
            source: page.relativeSource,
            pointer: "/",
            message:
              `built page renders ${page.groupCount} policy-yaml tab group(s) ` +
              `but the source contains ${page.sourceCount} policy_yaml instance(s)`,
          });
        }
      }
    }

    let blocksChecked = 0;
    let terraformBlocksChecked = 0;

    // First step: the Kubernetes and Universal block checks.
    process.stdout.write("Checking Kubernetes and Universal blocks... ");
    for (const page of pages) {
      for (const finding of page.parseFindings) {
        findings.push({
          source: page.relativeSource,
          ...finding,
          panel: panelLabel(page, finding),
        });
      }

      for (const block of page.entries) {
        blocksChecked++;

        for (const pointer of findNullValues(block.value)) {
          findings.push({
            source: page.relativeSource,
            panel: panelLabel(page, block),
            pointer,
            message: "value is null",
          });
        }

        for (const pointer of findMarkerFields(block.value)) {
          findings.push({
            source: page.relativeSource,
            panel: panelLabel(page, block),
            pointer,
            message: "renderer marker field survived rendering",
          });
        }

        const { findings: schemaFindings, hasCoverage } = checkSchema(
          block,
          page.crds,
          ajv,
        );
        if (hasCoverage) blocksWithCoverage++;
        for (const finding of schemaFindings) {
          findings.push({
            source: page.relativeSource,
            panel: panelLabel(page, block),
            ...finding,
          });
        }
      }
    }
    console.log(`done (${blocksChecked} blocks)`);

    // Second step: the terraform grammar check, which runs in every mode.
    process.stdout.write("Checking terraform grammar... ");
    for (const page of pages) {
      for (const tfBlock of page.tfBlocks) {
        terraformBlocksChecked++;

        const grammarFinding = checkHclGrammar(tfBlock.text);
        if (grammarFinding) {
          findings.push({
            source: page.relativeSource,
            panel: panelLabel(page, tfBlock),
            pointer: "/",
            severity: "gating",
            ...grammarFinding,
          });
        }
      }
    }
    console.log(`done (${terraformBlocksChecked} terraform block(s))`);

    // Third step: the provider-schema validation, skipped in off mode.
    if (terraformValidate !== "off") {
      process.stdout.write("Validating against the provider schema... ");
      for (const page of pages) {
        for (const tfBlock of page.tfBlocks) {
          const schemaFinding = checkProviderSchema(tfBlock.text, terraformEnv());
          if (schemaFinding) {
            findings.push({
              source: page.relativeSource,
              panel: panelLabel(page, tfBlock),
              pointer: "/",
              severity: terraformValidate === "warn" ? "advisory" : "gating",
              ...schemaFinding,
            });
          }
        }
      }
      console.log(`done (${terraformBlocksChecked} terraform block(s))`);
    }

    totalPages += pages.length;
    totalBlocks += blocksChecked;
    totalTerraformBlocks += terraformBlocksChecked;
    ranPhases.push({
      label: cls.summaryLabel,
      pages: pages.length,
      blocks: blocksChecked,
    });
  }

  for (const finding of findings) {
    const advisorySuffix = isAdvisory(finding) ? " (advisory)" : "";
    console.log(
      `${finding.source} [${finding.panel ?? "-"}] ${finding.pointer}: ` +
        `${finding.message}${advisorySuffix}`,
    );
  }

  const gatingCount = findings.filter((finding) => !isAdvisory(finding)).length;
  const advisoryCount = findings.length - gatingCount;

  const breakdown = ranPhases
    .map((phase) => `${phase.label} ${phase.pages} pages, ${phase.blocks} blocks`)
    .join("; ");
  console.log(
    `\nChecked ${totalPages} pages, ${totalBlocks} blocks ` +
      `(${blocksWithCoverage} with meaningful schema coverage), ` +
      `${totalTerraformBlocks} terraform block(s)` +
      `: ${breakdown}. ` +
      `${findings.length} finding(s): ${gatingCount} gating, ${advisoryCount} advisory.` +
      (skip.length > 0
        ? ` Skipped: ${skip.map(skipEntryLabel).join(", ")}.`
        : ""),
  );

  if (pluginCacheDir) {
    fs.rmSync(pluginCacheDir, { recursive: true, force: true });
  }

  return gatingCount > 0 ? 1 : 0;
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
