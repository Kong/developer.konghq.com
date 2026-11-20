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
const internalUrl = String.raw`https?://(?:www\.)?github\.com/kong/kong-harnesses(?![\w.-])[^\s)>]*`;
const anyInternalUrl = /github\.com\/kong\/kong-harnesses(?![\w.-])/i;
// The title forms that CommonMark allows after a link address.
const titleForms = String.raw`"[^"]*"|'[^']*'|\([^)]*\)`;
const linkTitle = String.raw`(?:\s+(?:${titleForms}))?`;
// A link whose address a later pass emptied, which the page would show as text.
const emptiedLink = new RegExp(String.raw`\]\(\s*(?:${titleForms})?\s*\)`);
// An issue or pull request number or a commit hash means nothing without its link.
const referenceLabel = /^#?\d+$|^[0-9a-f]{7,40}$/i;

function linkText(text) {
  return referenceLabel.test(text) ? '' : text;
}

function withoutInternalLinks(markdown) {
  const labels = new Set();
  const text = markdown
    .replace(new RegExp(String.raw`^ {0,3}\[([^\]]+)\]:[ \t]*<?${internalUrl}>?.*\n?`, 'gim'), (_, label) => {
      labels.add(label.toLowerCase());
      return '';
    })
    .replace(new RegExp(String.raw` ?\(\[[^\]]*\]\(\s*<?${internalUrl}>?${linkTitle}\s*\)\)`, 'gi'), '')
    .replace(new RegExp(String.raw`\[([^\]]*)\]\(\s*<?${internalUrl}>?${linkTitle}\s*\)`, 'gi'), (_, label) => linkText(label))
    .replace(/\[([^\]]*)\]\[([^\]]*)\]/g, (link, label, reference) =>
      labels.has((reference || label).toLowerCase()) ? linkText(label) : link,
    )
    .replace(/\[([^\]]+)\](?![([:])/g, (link, label) => (labels.has(label.toLowerCase()) ? linkText(label) : link))
    .replace(new RegExp(` ?<${internalUrl}>`, 'gi'), '')
    .replace(new RegExp(` ?${internalUrl}`, 'gi'), '')
    .replace(/\( +/g, '(')
    .replace(/ +\)/g, ')')
    .replace(/ ?\(\s*\)/g, '')
    .replace(/(\S) {2,}/g, '$1 ')
    .replace(/[ \t]+$/gm, '');
  if (anyInternalUrl.test(text) || emptiedLink.test(text)) {
    throw new Error('A link into the internal kong-harnesses repository is left, or left broken, in the changelog.');
  }
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
// With publishedVersion, a release above it is left out: release-please writes its
// section when the release pull request merges, before the release is published.
export function publicChangelog(markdown, publishedVersion) {
  return withEscapedTags(withoutInternalLinks(markdown.replace(/^# Changelog\s*\n/, '')))
    .split(/^(?=## )/m)
    .filter((release) => {
      const version = release.match(/^## \[?(\d+\.\d+\.\d+)\b/)?.[1];
      return !publishedVersion || !version || compareVersions(version, publishedVersion) <= 0;
    })
    .map(userFacingRelease)
    .filter(Boolean)
    .join('\n\n')
    .replace(/\n{3,}/g, '\n\n')
    .concat('\n');
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

  // main, not the tag, so a correction to an earlier entry reaches the page.
  const file = await fetch(`https://api.github.com/repos/${repo}/contents/CHANGELOG.md?ref=main`, {
    headers: { ...headers, Accept: 'application/vnd.github.raw' },
  });
  if (!file.ok) {
    throw new Error(`GitHub API request for ${repo} CHANGELOG.md on main failed (${file.status} ${file.statusText}).`);
  }

  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, `${JSON.stringify({ markdown: publicChangelog(await file.text(), highest.version) }, null, 2)}\n`, 'utf8');
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
