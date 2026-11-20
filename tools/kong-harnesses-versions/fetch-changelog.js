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

function userFacingRelease(release) {
  const [heading, ...sections] = release.split(/^(?=### )/m);
  const kept = sections.flatMap((section) => {
    const [title, ...lines] = section.trim().split('\n');
    const name = title.slice(4).trim();
    if (!userSections.has(name)) {
      return [];
    }
    // An upgrade step stays whatever its scope, because a user must still do it.
    let keep = true;
    const entries = lines
      .filter((line) => {
        if (line.startsWith('* ') && name !== breakingChanges) {
          keep = !internalScopes.has(line.match(/^\* \*\*([^:*]+):\*\*/)?.[1]);
        }
        return keep;
      })
      .join('\n')
      .trim();
    return entries ? [`${title}\n\n${entries}`] : [];
  });
  return kept.length ? [heading.trim(), ...kept].join('\n\n') : '';
}

// The repository is internal, so links into it break for readers of the site.
// The Mesh changelog drops them too (mesh.ignored_links_regex).
const repositoryPaths = new Map([
  ['github.com', '/kong/kong-harnesses'],
  ['www.github.com', '/kong/kong-harnesses'],
  ['api.github.com', '/repos/kong/kong-harnesses'],
  ['raw.githubusercontent.com', '/kong/kong-harnesses'],
]);
// A link address as Markdown writes it, with or without a scheme. Each one is parsed
// before it is judged, so a port, letter case or percent-encoding cannot hide it.
const address = String.raw`(?:https?:)?//[^\s)>]*`;
// A last check of the plain text, for an address that is not a link, as in a code span.
const anyInternalUrl = /(?:github\.com|api\.github\.com\/repos|raw\.githubusercontent\.com)\/kong\/kong-harnesses(?![\w.-])/i;
// The title forms that CommonMark allows after a link address.
const titleForms = String.raw`"[^"]*"|'[^']*'|\([^)]*\)`;
const linkTitle = String.raw`(?:\s+(?:${titleForms}))?`;
// A link whose address a later pass emptied, which the page would show as text.
const emptiedLink = new RegExp(String.raw`\]\(\s*(?:${titleForms})?\s*\)`);
// Marks where a link was removed, so the cleanup touches only the text next to it.
const removed = '\u0000';
// A relative address resolves against the page, as a reader's browser does.
const page = 'https://developer.konghq.com/kong-harnesses/changelog/';

// The path in the repository that the address names, such as "/commit/c0ffee1", or
// null for an address outside it. An address that cannot be parsed stops the sync,
// because the check cannot tell where it leads.
function repositoryPath(link) {
  let url;
  let path;
  try {
    url = new URL(link, page);
    path = decodeURIComponent(url.pathname).toLowerCase();
  } catch {
    throw new Error(`The changelog has a link address that is not a valid URL: ${link}`);
  }
  const prefix = repositoryPaths.get(url.hostname.replace(/\.$/, ''));
  if (!prefix || !path.startsWith(prefix) || /^[\w.-]/.test(path.slice(prefix.length))) {
    return null;
  }
  return path.slice(prefix.length);
}

// An issue or pull request number, or the hash of a commit link, means nothing without
// its link. A word of hex letters, such as "defaced", is a hash only on a commit link.
function linkText(text, path) {
  const reference = /^#?\d+$/.test(text) || (/^\/commits?\//.test(path) && /^[0-9a-f]{7,40}$/i.test(text));
  return reference ? removed : text;
}

function assertNoInternalLinks(text) {
  const addresses = [
    ...[...text.matchAll(/\]\(\s*<?([^\s)>]*)/g)].map((match) => match[1]),
    ...[...text.matchAll(/^ {0,3}\[[^\]]+\]:[ \t]*<?([^\s>]+)/gm)].map((match) => match[1]),
    ...[...text.matchAll(/<([a-z][a-z0-9+.-]*:[^\s>]*)>/gi)].map((match) => match[1]),
    ...[...text.matchAll(/(?:https?:)?\/\/[^\s)>\/][^\s)>]*/gi)].map((match) => match[0]),
  ];
  if (anyInternalUrl.test(text) || emptiedLink.test(text) || addresses.some((link) => repositoryPath(link) !== null)) {
    throw new Error('A link into the internal kong-harnesses repository is left, or left broken, in the changelog.');
  }
}

function withoutInternalLinks(markdown) {
  if (markdown.includes(removed)) {
    throw new Error('The changelog contains a NUL character.');
  }
  const labels = new Map();
  const text = markdown
    .replace(new RegExp(String.raw`^ {0,3}\[([^\]]+)\]:[ \t]*<?(${address})>?.*\n?`, 'gim'), (definition, label, link) => {
      const path = repositoryPath(link);
      if (path === null) {
        return definition;
      }
      labels.set(label.toLowerCase(), path);
      return '';
    })
    .replace(new RegExp(String.raw`\(\[[^\]]*\]\(\s*<?(${address})>?${linkTitle}\s*\)\)`, 'gi'), (link, url) =>
      repositoryPath(url) === null ? link : removed,
    )
    .replace(new RegExp(String.raw`\[([^\]]*)\]\(\s*<?(${address})>?${linkTitle}\s*\)`, 'gi'), (link, label, url) => {
      const path = repositoryPath(url);
      return path === null ? link : linkText(label, path);
    })
    .replace(/\[([^\]]*)\]\[([^\]]*)\]/g, (link, label, reference) => {
      const path = labels.get((reference || label).toLowerCase());
      return path === undefined ? link : linkText(label, path);
    })
    .replace(/\[([^\]]+)\](?![([:])/g, (link, label) => {
      const path = labels.get(label.toLowerCase());
      return path === undefined ? link : linkText(label, path);
    })
    .replace(/<(https?:\/\/[^\s>]*)>/gi, (link, url) => (repositoryPath(url) === null ? link : removed))
    .replace(/https?:\/\/[^\s)>]*/gi, (url) => (repositoryPath(url) === null ? url : removed))
    // Brackets that held only removed links go, then each mark takes one space with it.
    .replace(new RegExp(String.raw`\(\s*(?:${removed}\s*)+\)`, 'g'), removed)
    .replace(new RegExp(`\\(${removed}+ ?`, 'g'), '(')
    .replace(new RegExp(` ?${removed}+`, 'g'), '');
  assertNoInternalLinks(text);
  return text;
}

// Kramdown reads <name> outside a code span as an HTML tag and shows nothing, so a
// subject such as "profile get <profile>" keeps its placeholder only when escaped.
function withEscapedTags(markdown) {
  return markdown
    .split(/(`+[^`]*`+)/)
    .map((part, index) => (index % 2 ? part : part.replace(/<(?!https?:\/\/|mailto:)/g, '&lt;')))
    .join('');
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
// before the first heading goes. A heading with no version, or no heading for `highest`, the highest published
// release, stops the sync, so a changelog that lost its sections cannot empty the page.
// So does a changelog with no entries for users left.
export function publicChangelog(markdown, { published, highest }) {
  const versions = new Set();
  const releases = withEscapedTags(withoutInternalLinks(markdown.replace(/^# Changelog\s*\n/, '')))
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
    });
  if (!versions.has(highest)) {
    throw new Error(`The changelog has no section for ${highest}, the highest published release.`);
  }
  const kept = releases.map(userFacingRelease).filter(Boolean);
  if (!kept.length) {
    throw new Error('The changelog has no entries for users in its published releases.');
  }
  return kept.join('\n\n').replace(/\n{3,}/g, '\n\n').concat('\n');
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
        `GitHub API request for ${repo} releases failed (${list.status} ${list.statusText}). ${repo} is an internal repository: set GH_TOKEN to a GitHub token with read access to it.`,
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
