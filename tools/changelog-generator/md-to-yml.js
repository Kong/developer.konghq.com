/*
 * Reverse the changelog generation: parse a release CHANGELOG.md and emit
 * one YAML entry per bullet under <path>/<version>/<component>/<slug>.yml.
 *
 * Usage:
 *   node md-to-yml.mjs --path <kong-ee-dir> --version <ver> [-o outputDir] [--dry-run]
 *
 *   <kong-ee-dir>    Path to the kong-ee repo folder. Resolved
 *                    RELATIVE TO THE SCRIPT'S LOCATION (not the caller's
 *                    cwd), so the script can live anywhere and still find
 *                    a co-located changelog folder via a stable relative
 *                    path like "../kong-ee/changelog".
 *
 *   <ver>            Release version, e.g. "3.14.0.0". The markdown is
 *                    read from <changelog-dir>/<ver>/<ver>.md.
 *
 *   -o <outDir>      Output directory (also resolved relative to the
 *                    script). Defaults to <script-dir>/tmp/changelog/<ver>.
 *
 * Mapping:
 *   ## section            -> component directory
 *     "Kong"                          -> kong
 *     "Kong-Enterprise"               -> kong-ee
 *     "Kong-Manager" / "Kong-Manager-Enterprise" -> kong-manager-ee
 *     "Kong-Portal"  / "Kong-Portal-Enterprise"  -> kong-portal-ee
 *
 *   ### subsection        -> type
 *     "Features"          -> feature
 *     "Fixes"             -> bugfix
 *     "Performance"       -> performance
 *     "Breaking Changes"  -> breaking_change
 *     "Deprecations"      -> deprecation
 *     "Dependencies"      -> dependency
 *
 *   #### sub-subsection   -> scope (verbatim: Core, Plugin, PDK, ...)
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TYPE_BY_SECTION = {
  'Features': 'feature',
  'Fixes': 'bugfix',
  'Performance': 'performance',
  'Breaking Changes': 'breaking_change',
  'Deprecations': 'deprecation',
  'Dependencies': 'dependency',
};

const COMPONENT_BY_SECTION = {
  'Kong': 'kong',
  'Kong-Enterprise': 'kong-ee',
  'Kong-Manager': 'kong-manager-ee',
  'Kong-Manager-Enterprise': 'kong-manager-ee',
  'Kong-Portal': 'kong-portal-ee',
  'Kong-Portal-Enterprise': 'kong-portal-ee',
};

const FILENAME_PREFIX_BY_TYPE = {
  feature: 'feat',
  bugfix: 'fix',
  performance: 'perf',
  breaking_change: 'break',
  deprecation: 'deprecate',
  dependency: 'bump',
};

function parseArgs(argv) {
  const args = { kongeeDir: null, version: null, outDir: null, dryRun: false };
  for (let i = 2; i < argv.length; i++) {
    const [flag, eqVal] = argv[i].split(/=(.+)/);
    const nextVal = () => eqVal !== undefined ? eqVal : argv[++i];
    if (flag === '--path' || flag === '-p') args.kongeeDir = nextVal();
    else if (flag === '--version' || flag === '-v') args.version = nextVal();
    else if (flag === '-o' || flag === '--out') args.outDir = nextVal();
    else if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '-h' || flag === '--help') {
      process.stdout.write(
        'Usage: node md-to-yml.js --path <kong-ee-dir> --version <ver> [-o outDir] [--dry-run]\n' +
        '  <kong-ee-dir> and <outDir> are resolved relative to the script.\n' +
        '  Reads <kong-ee-dir>/changelog/<ver>/<ver>.md, writes to <outDir>/<component>/.\n'
      );
      process.exit(0);
    } else throw new Error(`Unexpected argument: ${argv[i]}`);
  }
  if (!args.kongeeDir) throw new Error('Missing --path <kong-ee-dir>');
  if (!args.version) throw new Error('Missing --version <ver>');

  // Resolve relative to the script's location so the script can live
  // anywhere and find the changelog via a stable relative path.
  const resolveRel = (p) => path.resolve(__dirname, p);
  const kongeeDir = resolveRel(args.kongeeDir);
  const releaseDir = path.join(kongeeDir, 'changelog', args.version);
  const inputMd = path.join(releaseDir, `${args.version}.md`);

  if (!fs.existsSync(inputMd)) {
    throw new Error(`Markdown not found: ${inputMd}`);
  }

  args.inputMd = inputMd;
  args.outDir = args.outDir
    ? resolveRel(args.outDir)
    : path.join(__dirname, 'tmp', 'changelog', args.version);
  return args;
}

// Trailing inline " [#123](url) [KAG-1](url) ..." chain on a bullet line.
function stripInlineRefs(text) {
  return text.replace(/(\s+\[[^\]]+\]\([^)]+\))+\s*$/, '');
}

// A reference-link continuation line, e.g. " [#15138](https://...)".
function isRefLine(line) {
  return /^\s+\[[^\]]+\]\([^)]+\)\s*$/.test(line);
}

function parseChangelog(md) {
  const lines = md.split(/\r?\n/);
  const entries = [];
  let component = null;
  let type = null;
  let scope = null;
  let current = null;

  const flush = () => {
    if (!current) return;
    let text = current.lines.join('\n').replace(/\s+$/, '');
    text = stripInlineRefs(text);
    if (text && component && type) {
      entries.push({ component, type, scope, message: text.replace(/[\r\n]+$/, '') });
    }
    current = null;
  };

  for (const raw of lines) {
    const line = raw.replace(/\s+$/, '');

    if (/^##\s+/.test(line) && !/^###/.test(line)) {
      flush();
      const name = line.replace(/^##\s+/, '').trim();
      component = COMPONENT_BY_SECTION[name] || null;
      type = null;
      scope = null;
      continue;
    }
    if (/^###\s+/.test(line) && !/^####/.test(line)) {
      flush();
      const name = line.replace(/^###\s+/, '').trim();
      type = TYPE_BY_SECTION[name] || null;
      scope = null;
      continue;
    }
    if (/^####\s+/.test(line)) {
      flush();
      scope = line.replace(/^####\s+/, '').trim() || null;
      continue;
    }

    if (/^-\s+/.test(line)) {
      flush();
      current = { lines: [line.replace(/^-\s+/, '')] };
      continue;
    }

    if (!current) continue;
    if (line === '') { flush(); continue; }
    if (isRefLine(line)) continue;
    current.lines.push(line);
  }
  flush();
  return entries;
}

function slugify(message) {
  // Keep the **prefix** marker (plugin name etc.) and code-span contents —
  // they're the most recognizable parts of a filename.
  let s = message.replace(/\*\*([^*]+)\*\*/g, '$1');
  s = s.replace(/`([^`]*)`/g, '$1');
  s = s.toLowerCase();
  s = s.replace(/[^a-z0-9]+/g, '-');
  s = s.replace(/^-+|-+$/g, '');
  const words = s.split('-').filter(Boolean).slice(0, 6);
  return words.join('-') || 'entry';
}

function filenameFor(entry, used) {
  const prefix = FILENAME_PREFIX_BY_TYPE[entry.type] || 'entry';
  const base = `${prefix}-${slugify(entry.message)}`;
  let name = `${base}.yml`;
  let n = 2;
  while (used.has(name)) name = `${base}-${n++}.yml`;
  used.add(name);
  return name;
}

function toYaml(entry) {
  const indented = entry.message
    .split('\n')
    .map((l) => '  ' + l)
    .join('\n');
  const parts = ['message: |', indented, `type: ${entry.type}`];
  if (entry.scope) parts.push(`scope: ${entry.scope}`);
  return parts.join('\n') + '\n';
}

function main() {
  const args = parseArgs(process.argv);
  const md = fs.readFileSync(args.inputMd, 'utf8');
  const entries = parseChangelog(md);

  const usedByComponent = new Map();
  const byComponent = new Map();

  for (const e of entries) {
    if (!usedByComponent.has(e.component)) usedByComponent.set(e.component, new Set());
    const name = filenameFor(e, usedByComponent.get(e.component));
    if (!byComponent.has(e.component)) byComponent.set(e.component, []);
    byComponent.get(e.component).push({ name, yaml: toYaml(e) });
  }

  let total = 0;
  for (const [component, files] of byComponent) {
    const dir = path.join(args.outDir, component);
    if (!args.dryRun) fs.mkdirSync(dir, { recursive: true });
    for (const f of files) {
      const full = path.join(dir, f.name);
      if (args.dryRun) process.stdout.write(`--- ${full}\n${f.yaml}`);
      else fs.writeFileSync(full, f.yaml);
      total++;
    }
  }

  process.stderr.write(
    `${args.dryRun ? '[dry-run] would write' : 'wrote'} ${total} yml ` +
    `file(s) across ${byComponent.size} component(s)\n`
  );
}

main();
