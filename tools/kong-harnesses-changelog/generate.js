import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const MIN_VERSION = '0.18.0';

const COMPONENT = 'kong-harnesses';

const SECTION_TYPES = {
  '⚠ BREAKING CHANGES': 'Breaking Change',
  Features: 'feature',
  'Bug Fixes': 'bugfix',
  Performance: 'performance',
};

export function compareVersions(a, b) {
  const aParts = a.split('.').map(Number);
  const bParts = b.split('.').map(Number);
  const maxLength = Math.max(aParts.length, bParts.length);

  for (let i = 0; i < maxLength; i += 1) {
    const aVal = aParts[i] || 0;
    const bVal = bParts[i] || 0;

    if (aVal < bVal) return -1;
    if (aVal > bVal) return 1;
  }

  return 0;
}

const VERSION_HEADING = /^##\s*\[([^\]]+)\]\([^)]*\)/;
const SECTION_HEADING = /^###\s+(.+?)\s*$/;
const BULLET = /^[*-]\s+(.*)$/;
const REFERENCE_CHAIN = /\s*\(\[[^\]]+\]\([^)]+\)\)$/;

function stripReferences(message) {
  let result = message;
  while (REFERENCE_CHAIN.test(result)) {
    result = result.replace(REFERENCE_CHAIN, '');
  }
  return result.trim();
}

function sectionType(section) {
  return SECTION_TYPES[section] ?? section.toLowerCase();
}

export function generateChangelog(markdown, { minVersion = MIN_VERSION } = {}) {
  const versions = {};
  let currentVersion = null;
  let currentType = null;

  for (const rawLine of markdown.split('\n')) {
    const line = rawLine.replace(/\s+$/, '');

    const versionMatch = line.match(VERSION_HEADING);
    if (versionMatch) {
      const version = versionMatch[1];
      if (version.includes('-')) {
        currentVersion = null;
      } else if (compareVersions(version, minVersion) < 0) {
        currentVersion = null;
      } else {
        currentVersion = version;
        versions[version] = { [COMPONENT]: [] };
      }
      currentType = null;
      continue;
    }

    const sectionMatch = line.match(SECTION_HEADING);
    if (sectionMatch) {
      currentType = sectionType(sectionMatch[1]);
      continue;
    }

    const bulletMatch = line.match(BULLET);
    if (!bulletMatch || currentVersion === null || currentType === null) {
      continue;
    }

    const message = stripReferences(bulletMatch[1]);
    const entries = versions[currentVersion][COMPONENT];
    if (entries.some((entry) => entry.message === message && entry.type === currentType)) {
      continue;
    }

    entries.push({ message, type: currentType });
  }

  return Object.keys(versions)
    .sort((a, b) => compareVersions(b, a))
    .reduce((ordered, version) => {
      ordered[version] = versions[version];
      return ordered;
    }, {});
}

export function renderChangelog(markdown, options = {}) {
  return `${JSON.stringify(generateChangelog(markdown, options), null, 2)}\n`;
}

function parseArgs(argv) {
  const args = {};
  for (const arg of argv) {
    const match = arg.match(/^--([^=]+)(?:=(.*))?$/);
    if (match) {
      args[match[1]] = match[2] ?? true;
    }
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const input = path.resolve(args.input ?? 'CHANGELOG.md');
  const output = path.resolve(args.output ?? path.join(__dirname, '../../app/_changelogs/kong-harnesses.json'));
  const minVersion = typeof args['min-version'] === 'string' ? args['min-version'] : MIN_VERSION;

  const markdown = fs.readFileSync(input, 'utf8');
  const json = renderChangelog(markdown, { minVersion });

  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, json, 'utf8');

  const versions = Object.keys(JSON.parse(json));
  console.log(`Wrote ${versions.length} version(s) at or above ${minVersion} to ${output}`);
}

const isEntry = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isEntry) {
  main().catch((error) => {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  });
}
