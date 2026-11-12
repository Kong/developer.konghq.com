#!/usr/bin/env node
// Extracts the Lua sandbox allowlists from the kong-ee source into app/_data/sandbox_allowlist/<product>.yml.
// See README.md for usage and for how versions are tracked.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';

const DOCS_ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '../..');
// Products with versioned data track min_version and max_version per name. The others hold only the latest.
const PRODUCTS = { gateway: { versioned: true }, 'ai-gateway': { versioned: false } };
const USAGE = 'Usage: node extract.js --path <path-to-kong-ee> --product <gateway|ai-gateway> [--version 3.15]';

function main() {
  const { repo, product, versionOverride } = parseArgs(process.argv.slice(2));
  const { versioned } = PRODUCTS[product];
  const out = path.join(DOCS_ROOT, `app/_data/sandbox_allowlist/${product}.yml`);

  const source = openSource(repo);
  assertExpectedLayout(source);
  const lists = readLists(source);
  assertLaxIsAdditive(lists);

  const version = versioned ? versionOverride || gatewayVersion(source) : undefined;
  const existing = versioned && fs.existsSync(out) ? YAML.parse(fs.readFileSync(out, 'utf8')) : null;
  const { blocks, stats } = mergeLists(lists, existing, product, version);

  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, YAML.stringify(blocks, { indent: 2, lineWidth: 0 }));
  report({ product, versioned, version, out, isBaseline: !existing, blocks, stats });
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

function parseArgs(argv) {
  const flag = (name) => {
    const i = argv.indexOf(name);
    return i === -1 ? undefined : argv.splice(i, 2)[1];
  };
  const versionOverride = flag('--version');
  const product = flag('--product');
  const repo = flag('--path');
  if (!repo || !product || argv.length) fail(USAGE);
  if (!PRODUCTS[product]) fail(`Unknown product "${product}". Use one of: ${Object.keys(PRODUCTS).join(', ')}.`);
  if (!PRODUCTS[product].versioned && versionOverride) {
    fail(
      `Error: --version can't be used with --product ${product}. ${product} has no versions in its data file, only the latest.\n` +
      `Remove --version and run: node tools/sandbox-allowlist/extract.js --path ${repo} --product ${product}`,
    );
  }
  return { repo, product, versionOverride };
}

// Reads files from the kong-ee checkout, relative to its root. Each file is read once.
function openSource(repo) {
  if (!fs.existsSync(path.join(repo, 'kong/tools/sandbox'))) {
    fail(`${repo} doesn't look like a kong-ee checkout: kong/tools/sandbox is missing. Check the --path value.`);
  }
  const cache = new Map();
  const file = (rel) => {
    if (!cache.has(rel)) cache.set(rel, fs.readFileSync(path.join(repo, rel), 'utf8'));
    return cache.get(rel);
  };
  return {
    file,
    sandbox: (rel) => file(`kong/tools/sandbox/${rel}`),
  };
}


function gatewayVersion(source) {
  for (const file of ['kong/enterprise_edition/meta.lua', 'kong/meta.lua']) {
    let src;
    try { src = source.file(file); } catch { continue; }
    const major = src.match(/major\s*=\s*(\d+)/);
    const minor = src.match(/minor\s*=\s*(\d+)/);
    if (major && minor) return `${major[1]}.${minor[1]}`;
  }
  throw new Error('Could not read the Gateway version from meta.lua. Pass --version.');
}

// The release before `version` in the docs' own release list, used for max_version.
function previousRelease(product, version) {
  const file = `app/_data/products/${product}.yml`;
  const releases = YAML.parse(fs.readFileSync(path.join(DOCS_ROOT, file), 'utf8')).releases.map((r) => r.release);
  const i = releases.indexOf(version);
  if (i === -1) throw new Error(`Release ${version} is not in ${file}`);
  if (i === 0) throw new Error(`Release ${version} is the first in ${file}, so it has no previous release.`);
  return releases[i - 1];
}

// Each allowlist file returns a [[ ... ]] long string, optionally prefixed by
// require("...") .. " " .. to inherit another layer. Only the file's own names are returned.
function ownNames(source, rel) {
  const m = source.sandbox(rel).match(/\[\[([\s\S]*?)\]\]/);
  if (!m) throw new Error(`No [[ ]] string found in ${rel}`);
  return m[1].split(/\s+/).filter(Boolean);
}

function parentOf(source, rel) {
  const m = source.sandbox(rel).match(/return\s+require\("([^"]+)"\)/);
  return m ? m[1].replace('kong.tools.sandbox.', '').replace(/\./g, '/') + '.lua' : null;
}

// Verify the inheritance chain is what this script assumes.
const EXPECTED_PARENTS = {
  'environment/lua.lua': null,
  'environment/strict.lua': 'environment/lua.lua',
  'environment/lax.lua': 'environment/strict.lua',
  'require/lua.lua': null,
  'require/strict.lua': 'require/lua.lua',
  'require/lax.lua': 'require/strict.lua',
};
function assertExpectedLayout(source) {
  for (const [file, parent] of Object.entries(EXPECTED_PARENTS)) {
    if (parentOf(source, file) !== parent) {
      throw new Error(`${file} inherits from ${parentOf(source, file)}, expected ${parent}. Update extract.js.`);
    }
  }
}

// Table keys from a Lua `local NAME = { a = true, ... }` block.
function luaAllowlist(source, file, name) {
  const m = source.sandbox(file).match(new RegExp(`local ${name} = \\{([\\s\\S]*?)\\n\\}`));
  if (!m) throw new Error(`${name} not found in ${file}`);
  return [...m[1].matchAll(/^\s*(\w+)\s*=\s*true/gm)].map((x) => x[1]);
}

// Environment entries group by their parent table (math.abs -> math, kong.request.get_path ->
// kong.request). Colon methods group by their class (kong.db.routes:select -> kong.db.routes).
// Names with no parent table are globals. Constants and fields get their own rows so the
// large ngx.* constant list does not bury the ngx.* functions.
function envGroup(name) {
  if (name.includes(':')) return name.split(':')[0];
  const parts = name.split('.');
  if (parts.length === 1) return 'globals';
  if (parts[0] === 'ngx' && parts.length === 2 && /^[A-Z_0-9]+$/.test(parts[1])) return 'ngx (constants)';
  return parts.slice(0, -1).join('.');
}

const RESTY_FAMILIES = {
  openssl: 'resty.openssl', aws: 'resty.aws', azure: 'resty.azure', gcp: 'resty.gcp',
  redis: 'resty.redis', rediscluster: 'resty.redis', xmodem: 'resty.redis',
  http: 'resty.http', http_connect: 'resty.http', http_headers: 'resty.http',
};

// Module entries group by library family: the first segment, except for the larger families
// (resty.openssl, kong.tools, ...) that would otherwise dominate their row.
function modGroup(name) {
  const parts = name.split('.');
  if (parts[0] === 'resty') return RESTY_FAMILIES[parts[1]] || 'resty';
  if (parts[0] === 'kong') return parts.length > 2 || parts[1] === 'tools' ? parts.slice(0, 2).join('.') : 'kong';
  return parts[0];
}

// The names one allowlist file adds, as { name, group } entries.
function layer(source, file) {
  const groupOf = file.startsWith('environment/') ? envGroup : modGroup;
  return ownNames(source, file).map((name) => ({ name, group: groupOf(name) }));
}

// kong.log.* and ngx.* field names. Releases up to 3.14 build these inline in init.lua;
// newer releases use the KONG_LOG_ALLOWLIST and NGX_ALLOWLIST tables.
function specialNames(source) {
  const file = 'environment/init.lua';
  const src = source.sandbox(file);
  if (src.includes('local KONG_LOG_ALLOWLIST')) {
    return {
      log: luaAllowlist(source, file, 'KONG_LOG_ALLOWLIST'),
      ngxFields: luaAllowlist(source, file, 'NGX_ALLOWLIST'),
    };
  }
  const log = [...src.matchAll(/^\s*(\w+) = function\(\.\.\.\) return kong\.log\.\1\(/gm)].map((m) => m[1]);
  const fromComment = (src.match(/special ngx\.\{([^})]*)[})]/)?.[1] ?? '').split('|').map((x) => x.trim()).filter(Boolean);
  const fromRawset = [...src.matchAll(/rawset\(env\.ngx, "(\w+)"/g)].map((m) => m[1]);
  const ngxFields = [...new Set([...fromComment, ...fromRawset])].sort();
  if (!log.length || !ngxFields.length) throw new Error(`Could not read kong.log / ngx fields from ${file}. Update extract.js.`);
  return { log, ngxFields };
}

// Names that the sandbox exposes through code in environment/init.lua rather than the string lists.
function specialEnvEntries(source) {
  const { log, ngxFields } = specialNames(source);
  const tableFields = new Set(['arg', 'ctx', 'header', 'var']); // exposed as tables, shown as name[*]
  const entries = (group, names) => names.map((name) => ({ name, group }));
  return [
    ...entries('kong.log', ['kong.log', ...log.map((k) => `kong.log.${k}`), 'kong.log.deprecation', 'kong.log.deprecation.write']),
    ...entries('kong.ctx', ['kong.ctx.shared[*]', 'kong.ctx.plugin[*]']),
    ...entries('ngx (fields)', ngxFields.map((k) => (tableFields.has(k) ? `ngx.${k}[*]` : `ngx.${k}`))),
  ];
}

// Strict is the union of the lua and strict layers. Lax lists only what lax mode adds on top.
// kong.configuration is created only when the mode is neither lua nor strict (environment/init.lua).
function readLists(source) {
  return {
    environment: {
      strict: [...layer(source, 'environment/lua.lua'), ...layer(source, 'environment/strict.lua'), ...specialEnvEntries(source)],
      lax: [...layer(source, 'environment/lax.lua'), { name: 'kong.configuration[*]', group: 'kong.configuration' }],
    },
    require: {
      strict: [...layer(source, 'require/lua.lua'), ...layer(source, 'require/strict.lua')],
      lax: layer(source, 'require/lax.lua'),
    },
  };
}

function assertLaxIsAdditive(lists) {
  for (const [kind, { strict, lax }] of Object.entries(lists)) {
    const strictNames = new Set(strict.map((e) => e.name));
    const dupes = lax.filter((e) => strictNames.has(e.name)).map((e) => e.name);
    if (dupes.length) throw new Error(`Names in both strict and lax additions for ${kind}: ${dupes.join(', ')}`);
  }
}

// Merges the live lists into the existing data file (null on a first run or for unversioned
// products) and records what changed. Returns the blocks to write.
function mergeLists(lists, existing, product, version) {
  const isBaseline = !existing;
  const ctx = {
    existing,
    version,
    isBaseline,
    previous: isBaseline ? undefined : previousRelease(product, version),
    stats: { added: [], removed: [], restored: [] },
  };
  const blocks = Object.entries(lists).flatMap(([kind, modes]) =>
    Object.entries(modes).map(([mode, entries]) => mergeBlock(ctx, kind, mode, entries)),
  );
  return { blocks, stats: ctx.stats };
}

// Merges the live entries of one kind and mode into what the data file already holds.
function mergeBlock({ existing, version, isBaseline, previous, stats }, kind, mode, entries) {
  const label = (name) => `${kind}/${mode}: ${name}`;

  // name -> { group, entry } from the existing file, in file order. An entry is
  // { name, min_version?, max_version? }.
  const known = new Map();
  const old = (existing || []).find((b) => b.kind === kind && b.mode === mode);
  for (const g of old?.groups || []) {
    for (const n of g.names) known.set(n.name, { group: g.id, entry: { ...n } });
  }

  for (const { name, group } of entries) {
    const prior = known.get(name);
    if (!prior) {
      known.set(name, { group, entry: isBaseline ? { name } : { name, min_version: version } });
      if (!isBaseline) stats.added.push(label(name));
    } else if (prior.entry.max_version) {
      delete prior.entry.max_version;
      stats.restored.push(label(name));
    }
  }

  if (!isBaseline) {
    const live = new Set(entries.map((e) => e.name));
    for (const [name, { entry }] of known) {
      if (!live.has(name) && !entry.max_version) {
        entry.max_version = previous;
        stats.removed.push(label(name));
      }
    }
  }

  const byGroup = new Map();
  for (const { group, entry } of known.values()) {
    if (!byGroup.has(group)) byGroup.set(group, []);
    byGroup.get(group).push(entry);
  }
  const groups = [...byGroup.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([id, names]) => ({ id, names }));
  return { kind, mode, groups };
}

function report({ product, versioned, version, out, isBaseline, blocks, stats }) {
  console.log(versioned ? `${isBaseline ? 'Seeded' : 'Merged'} release ${version} into ${out}` : `Wrote ${product} to ${out}`);
  for (const kind of ['environment', 'require']) {
    const [strict, lax] = ['strict', 'lax'].map((mode) =>
      blocks.find((b) => b.kind === kind && b.mode === mode).groups.reduce((n, g) => n + g.names.length, 0));
    console.log(`${`${kind}:`.padEnd(13)}strict=${strict} lax=${lax}`);
  }
  for (const [label, list] of Object.entries(stats)) {
    if (list.length) console.log(`\n${label} (${list.length}):\n  ${list.join('\n  ')}`);
  }
}

main();
