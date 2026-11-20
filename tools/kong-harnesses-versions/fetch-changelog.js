import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';
import { compareVersions } from '../lib/tool-versions.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repo = 'Kong/kong-harnesses';

// Readers of the site need what changed for them, not the repository's own build, CI,
// docs and review work, so only these sections are published.
const userSections = new Set(['⚠ BREAKING CHANGES', 'Features', 'Bug Fixes', 'Performance']);
const breakingChanges = '⚠ BREAKING CHANGES';
// Scopes of changes to the repository's own tooling, reviews and dependency pins.
// docs/release.md in Kong/kong-harnesses names the same list; change both together.
const internalScopes = new Set(['ci', 'deps', 'ksai', 'threat-model']);

// The page has no links: every link goes and keeps only its text, so no list of the
// forms an address can take is needed. The Mesh changelog drops its source links too
// (mesh.ignored_links_regex). check-changelog-links.rb then renders the result as the
// site does and stops the sync on any link or address that is left, so this step only
// has to be right for the changelog that release-please writes.
const removed = '\u0000';
const linkTitle = String.raw`(?:\s+(?:"[^"]*"|'[^']*'|\([^)]*\)))?`;
const inlineLink = new RegExp(
  String.raw`(!?)\[([^\]]*)\]\(\s*(<[^>\n]*>|[^()\s]*(?:\([^()\s]*\)[^()\s]*)*)${linkTitle}\s*\)`,
  'g',
);
// A link definition, also inside a list item or a block quote.
const definition = /^[ \t>]*(?:(?:[*+-]|\d+[.)])[ \t]+)?\[([^\]]+)\]:[ \t]*(\S*).*(?:\n|$)/gm;
// An http or https address. A closing parenthesis ends it unless the address opened one.
const webAddress = /<https?:\/\/[^\s<>]*>|\bhttps?:\/\/[^\s<>()]*(?:\([^\s<>()]*\)[^\s<>()]*)*/gi;

// Splits a line into prose and code spans, as kramdown pairs them: a run of backticks
// opens a span only when a later run of the same length closes it, and otherwise it is
// plain text. The odd items are the code spans.
function splitCode(line) {
  const parts = [];
  const runs = /(?<!\\)`+/g;
  let start = 0;
  let match;
  while ((match = runs.exec(line))) {
    const closer = new RegExp(`(?<!\`)${match[0]}(?!\`)`, 'g');
    closer.lastIndex = runs.lastIndex;
    if (closer.exec(line)) {
      parts.push(line.slice(start, match.index), line.slice(match.index, closer.lastIndex));
      start = closer.lastIndex;
      runs.lastIndex = closer.lastIndex;
    }
  }
  parts.push(line.slice(start));
  return parts;
}

// An issue or pull request number, or the hash of a commit link, means nothing without
// its link. A word of hex letters, such as "defaced", is a hash only on a commit link,
// and a number such as a year is a reference only on an issue or pull request link.
function linkText(text, address) {
  const reference =
    /^#\d+$/.test(text) ||
    (/\/(?:issues|pull)\/\d+/i.test(address) && /^\d+$/.test(text)) ||
    (/\/commits?\//i.test(address) && /^[0-9a-f]{7,40}$/i.test(text));
  return reference ? removed : text;
}

function withoutLinks(prose, labels) {
  const reference = (link, image, text, label) => {
    const address = labels.get(label.toLowerCase());
    if (address === undefined) {
      return link;
    }
    return image ? text : linkText(text, address);
  };
  return prose
    .replace(inlineLink, (_, image, text, address) => (image ? text : linkText(text, address)))
    .replace(/(!?)\[([^\]]*)\]\[([^\]]*)\]/g, (link, image, text, label) => reference(link, image, text, label || text))
    .replace(/(!?)\[([^\]]+)\](?![([:])/g, (link, image, text) => reference(link, image, text, text))
    .replace(webAddress, removed);
}

// Kramdown reads <name> outside a code span as an HTML tag and shows nothing, so a
// subject such as "profile get <profile>" keeps its placeholder only when escaped.
function publicLine(line, labels) {
  return splitCode(line)
    .map((part, index) => (index % 2 ? part : withoutLinks(part, labels).replace(/</g, '&lt;')))
    .join('')
    // Brackets that held only removed links go, then each mark takes one space with it.
    .replace(new RegExp(String.raw`\(\s*(?:${removed}\s*)+\)`, 'g'), removed)
    .replace(new RegExp(`\\(${removed}+ ?`, 'g'), '(')
    .replace(new RegExp(` ?${removed}+`, 'g'), '');
}

function publicText(text, labels) {
  return text
    .replace(definition, '')
    .split('\n')
    .map((line) => publicLine(line, labels))
    // An entry that held only a removed reference goes.
    .filter((line) => !/^\s*(?:[*+-]|\d+[.)])\s*$/.test(line))
    .join('\n')
    .trim();
}

function userFacingRelease(release, labels) {
  const [heading, ...sections] = release.split(/^(?=### )/m);
  const kept = sections.flatMap((section) => {
    const [title, ...lines] = section.trim().split('\n');
    const name = title.slice(4).trim();
    if (!userSections.has(name)) {
      return [];
    }
    // An upgrade step stays whatever its scope, because a user must still do it.
    let keep = true;
    const entries = publicText(
      lines
        .filter((line) => {
          if (line.startsWith('* ') && name !== breakingChanges) {
            keep = !internalScopes.has(line.match(/^\* \*\*([^:*(]+)(?:\([^)]*\))?:\*\*/)?.[1]);
          }
          return keep;
        })
        .join('\n'),
      labels,
    );
    return entries ? [`${title}\n\n${entries}`] : [];
  });
  return kept.length ? [publicText(heading, labels), ...kept].join('\n\n') : '';
}

// The page prints the result as a Liquid variable, which Jekyll does not parse as a
// template, so text such as {{ }} or {% endraw %} in a commit subject stays text.
//
// Only text of a published release reaches the site. release-please writes a section
// when the release pull request merges, before the release job publishes it, and a
// release candidate can be published before its final release, or for a final release
// that never comes. So a section stays only when its heading names a published release
// (`published`, the versions without the v), and a release candidate stays only once
// the final release of the same version is published. The candidate's section stays
// after that, because release-please takes the version in its manifest, the candidate,
// as the last release, so the final section lists only the commits after it. Text
// before the first heading goes. A heading with no version, or no heading for `highest`,
// the highest published release, stops the sync, so a changelog that lost its sections
// cannot empty the page. So does a changelog with no entries for users left. Links are
// removed only from the text that is kept, so a section that is left out cannot stop
// the sync.
export function publicChangelog(markdown, { published, highest }) {
  if (markdown.includes(removed)) {
    throw new Error('The changelog contains a NUL character.');
  }
  const labels = new Map([...markdown.matchAll(definition)].map((match) => [match[1].toLowerCase(), match[2]]));
  const versions = new Set();
  const kept = markdown
    .replace(/^# Changelog\s*\n/, '')
    .split(/^(?=## )/m)
    .filter((release) => {
      if (!release.startsWith('## ')) {
        return false;
      }
      const version = release.match(/^## \[?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)(?=[\]\s(]|$)/)?.[1];
      if (!version) {
        throw new Error(`The changelog has a release heading with no version: ${release.split('\n')[0]}`);
      }
      versions.add(version);
      return published.has(version) && published.has(version.split('-')[0]);
    })
    .map((release) => userFacingRelease(release, labels))
    .filter(Boolean);
  if (!versions.has(highest)) {
    throw new Error(`The changelog has no section for ${highest}, the highest published release.`);
  }
  if (!kept.length) {
    throw new Error('The changelog has no entries for users in its published releases.');
  }
  return kept.join('\n\n').replace(/\n{3,}/g, '\n\n').trimEnd().concat('\n');
}

export async function syncChangelog({ outFile, fetch = globalThis.fetch, env = process.env }) {
  const headers = { Accept: 'application/vnd.github+json' };
  if (env.GH_TOKEN) {
    headers.Authorization = `Bearer ${env.GH_TOKEN}`;
  }

  const releases = [];
  for (let page = 1; ; page += 1) {
    const list = await fetch(`https://api.github.com/repos/${repo}/releases?per_page=100&page=${page}`, { headers });
    if (!list.ok) {
      throw new Error(
        `GitHub API request for ${repo} releases failed (${list.status} ${list.statusText}). Set GH_TOKEN to a GitHub token with read access to ${repo}.`,
      );
    }
    const batch = await list.json();
    releases.push(...batch);
    if (batch.length < 100) {
      break;
    }
  }
  // The highest vX.Y.Z release, not the newest or the one marked latest, as the versions
  // job picks it: anyone who can write to the repository can mark an older release as
  // the latest, and a backport published after a newer release must not replace it.
  const [highest] = releases
    .filter((release) => !release.draft && !release.prerelease && /^v\d+\.\d+\.\d+$/.test(release.tag_name))
    .map((release) => ({ tag: release.tag_name, version: release.tag_name.slice(1) }))
    .sort((a, b) => compareVersions(b.version, a.version));
  const tag = highest?.tag;
  if (!tag) {
    throw new Error(`${repo} has no published vX.Y.Z release.`);
  }
  // Every published release, release candidates too, but no draft.
  const published = new Set(
    releases
      .filter((release) => !release.draft && /^v\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?$/.test(release.tag_name))
      .map((release) => release.tag_name.slice(1)),
  );

  // main, not the tag, so a correction to an earlier entry reaches the page.
  const file = await fetch(`https://api.github.com/repos/${repo}/contents/CHANGELOG.md?ref=main`, {
    headers: { ...headers, Accept: 'application/vnd.github.raw' },
  });
  if (!file.ok) {
    throw new Error(`GitHub API request for ${repo} CHANGELOG.md on main failed (${file.status} ${file.statusText}).`);
  }

  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, `${JSON.stringify({ markdown: publicChangelog(await file.text(), { published, highest: highest.version }) }, null, 2)}\n`, 'utf8');
  return tag;
}

const isEntry = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isEntry) {
  syncChangelog({ outFile: path.resolve(__dirname, '../../app/_data/kong-harnesses/changelog.json') })
    .then((tag) => console.log(`Wrote the kong-harnesses changelog at ${tag}`))
    .catch((error) => {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    });
}
