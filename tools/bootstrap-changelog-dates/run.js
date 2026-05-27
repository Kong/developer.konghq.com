// Bootstrap app/_data/changelogs/_dates.yml from existing sources.
//
// Usage (run locally, not in CI, not at build time):
//   cd tools/bootstrap-changelog-dates && npm ci
//   node run.js
//
// Resolution order per version key:
//   1. Existing authored data
//      - products/gateway.yml release_dates (Gateway)
//      - inline "**Release date**:" / "> Released on" lines in Markdown
//   2. Git pickaxe (first commit that introduced the version key) for everything
//      else. Used only by this script -- never at build time.
//
// Output is a single YAML file committed to the repo. Feed generation at
// build time reads that file; it never invokes git.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import yaml from "js-yaml";
import { globSync } from "tinyglobby";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");

const GATEWAY_JSON = path.join(REPO_ROOT, "app/_data/changelogs/gateway.json");
const GATEWAY_YAML = path.join(REPO_ROOT, "app/_data/products/gateway.yml");
const PLUGINS_GLOB = "app/_kong_plugins/*/changelog.json";
const MESH_MD = path.join(REPO_ROOT, "app/assets/mesh/raw/CHANGELOG.md");
const OPERATOR_MD = path.join(REPO_ROOT, "app/operator/changelog.md");
const EVENT_GW_MD = path.join(REPO_ROOT, "app/event-gateway/changelog.md");
const OUTPUT = path.join(REPO_ROOT, "app/_data/changelogs/_dates.yml");

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function normalizeDate(raw) {
  if (raw == null) return null;
  const s = String(raw).trim().replace(/\//g, "-").replace(/[.,]\s*$/, "");
  if (!s) return null;
  // Accept YYYY-MM-DD or YYYY-M-D
  const m = s.match(/^(\d{4})-(\d{1,2})-(\d{1,2})/);
  if (!m) return null;
  const [, y, mo, d] = m;
  return `${y}-${mo.padStart(2, "0")}-${d.padStart(2, "0")}`;
}

// First commit (oldest) that introduced an exact string into a file.
// Argv-form execFileSync so the search string is passed literally to git
// (no shell interpretation, no injection surface).
function gitFirstIntroduction(needle, relpath) {
  let stdout;
  try {
    stdout = execFileSync(
      "git",
      ["-C", REPO_ROOT, "log", "--reverse", "--format=%aI", "-S", needle, "--", relpath],
      { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] },
    );
  } catch {
    return null;
  }
  const first = stdout.split("\n").find((line) => line.trim() !== "");
  if (!first) return null;
  return normalizeDate(first.slice(0, 10));
}

function parseMarkdownSections(absPath) {
  const sections = [];
  let current = null;
  for (const line of fs.readFileSync(absPath, "utf8").split("\n")) {
    const headingMatch = line.match(/^##\s+([^\s#].*)$/);
    if (headingMatch) {
      current = { version: headingMatch[1].trim(), inlineDate: null };
      sections.push(current);
      continue;
    }
    if (current && current.inlineDate == null) {
      let m = line.match(/^\*\*Release date\*\*:?\s*(.+)$/);
      if (m) current.inlineDate = normalizeDate(m[1]);
      m = line.match(/^>\s*Released on\s*(.+)$/);
      if (m) current.inlineDate = normalizeDate(m[1]);
    }
  }
  return sections;
}

// ---------------------------------------------------------------------------
// Resolvers
// ---------------------------------------------------------------------------

function resolveGateway() {
  const data = JSON.parse(fs.readFileSync(GATEWAY_JSON, "utf8"));
  const authored =
    yaml.load(fs.readFileSync(GATEWAY_YAML, "utf8")).release_dates ?? {};
  const result = {};
  for (const version of Object.keys(data).sort()) {
    const date =
      normalizeDate(authored[version]) ??
      gitFirstIntroduction(`"${version}"`, "app/_data/changelogs/gateway.json");
    if (date) result[version] = date;
  }
  return result;
}

function resolvePlugins() {
  const result = {};
  const files = globSync(PLUGINS_GLOB, { cwd: REPO_ROOT }).sort();
  for (const rel of files) {
    const slug = path.basename(path.dirname(rel));
    const abs = path.join(REPO_ROOT, rel);
    const versions = Object.keys(JSON.parse(fs.readFileSync(abs, "utf8")));
    const pluginDates = {};
    for (const version of versions.sort()) {
      const date = gitFirstIntroduction(`"${version}"`, rel);
      if (date) pluginDates[version] = date;
    }
    if (Object.keys(pluginDates).length > 0) result[slug] = pluginDates;
    process.stderr.write(
      `  plugin ${slug}: ${Object.keys(pluginDates).length}/${versions.length} dated\n`,
    );
  }
  return result;
}

function resolveMarkdown(absPath, relpath, label) {
  const sections = parseMarkdownSections(absPath);
  const result = {};
  for (const s of sections) {
    const date =
      s.inlineDate ?? gitFirstIntroduction(`## ${s.version}`, relpath);
    if (date) result[s.version] = date;
  }
  process.stderr.write(
    `  ${label}: ${Object.keys(result).length}/${sections.length} dated\n`,
  );
  return result;
}

// ---------------------------------------------------------------------------
// Drive
// ---------------------------------------------------------------------------

process.stderr.write("Resolving Gateway versions...\n");
const gateway = resolveGateway();
process.stderr.write(`  gateway: ${Object.keys(gateway).length} dated\n`);

process.stderr.write("Resolving plugin versions...\n");
const plugins = resolvePlugins();

process.stderr.write("Resolving Mesh versions...\n");
const mesh = resolveMarkdown(MESH_MD, "app/assets/mesh/raw/CHANGELOG.md", "mesh");

process.stderr.write("Resolving Operator versions...\n");
const operator = resolveMarkdown(OPERATOR_MD, "app/operator/changelog.md", "operator");

process.stderr.write("Resolving Event Gateway versions...\n");
const eventGateway = resolveMarkdown(
  EVENT_GW_MD,
  "app/event-gateway/changelog.md",
  "event-gateway",
);

const payload = {
  _generated: {
    note: "Bootstrapped via tools/bootstrap-changelog-dates. Maintained by hand thereafter, like products/gateway.yml release_dates. Dates source the <pubDate> field in changelog RSS feeds only; the website is unaffected.",
    bootstrapped_at: new Date().toISOString().replace(/\.\d+Z$/, "Z"),
  },
  gateway,
  plugins,
  mesh,
  operator,
  "event-gateway": eventGateway,
};

fs.writeFileSync(OUTPUT, yaml.dump(payload, { lineWidth: -1, sortKeys: false }));
process.stderr.write(`Wrote ${OUTPUT}\n`);
