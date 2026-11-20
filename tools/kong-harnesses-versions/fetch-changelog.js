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
// has to be right for the changelog that release-please writes. No step changes the
// text of code, so an example in a code span or a code block stays as it is.
const removed = '\u0000';
// Stands in for a code span while links are removed, so a link with a code span as
// its text is found, and nothing inside the span is read as a link.
const span = '\u0001';
const spanMark = new RegExp(`${span}(\\d+)${span}`, 'g');
const linkTitle = String.raw`(?:\s+(?:"[^"]*"|'[^']*'|\([^)]*\)))?`;
// Link text, with brackets in it only in pairs, as in the text of a linked image.
const bracketed = String.raw`(?:[^\[\]]|\[[^\[\]]*\])*`;
const inlineLink = new RegExp(
  String.raw`(!?)\[(${bracketed})\]\(\s*(<[^>\n]*>|[^()\s]*(?:\([^()\s]*\)[^()\s]*)*)${linkTitle}\s*\)`,
  'g',
);
const fullReference = new RegExp(String.raw`(!?)\[(${bracketed})\]\[([^\]]*)\]`, 'g');
// A link definition, also inside a list item or a block quote. A footnote is no link
// definition: it stays, and the rendered check refuses the link that kramdown makes.
const definition = /^[ \t>]*(?:(?:[*+-]|\d+[.)])[ \t]+)?\[(?!\^)([^\]]+)\]:[ \t]*(\S*)/;
// An http or https address. A closing parenthesis ends it unless the address opened one.
const webAddress = /<https?:\/\/[^\s<>]*>|\bhttps?:\/\/[^\s<>()]*(?:\([^\s<>()]*\)[^\s<>()]*)*/gi;

// Marks the lines of fenced and indented code blocks. A line taken as code by mistake
// keeps its links, which the rendered check then refuses, so where kramdown's rules are
// hard to follow, such as the indent of a fence, a line counts as code.
function withCode(markdown) {
  let fence;
  let column = 0;
  let indentedCode = false;
  let blankBefore = true;
  return markdown.split('\n').map((text) => {
    const content = text.replace(/^(?:[ \t]*> ?)*/, '').replace(/\t/g, '    ');
    const indent = content.match(/^ */)[0].length;
    const blank = !content.trim();
    let code = true;
    if (fence) {
      const close = content.trim().match(/^(`{3,}|~{3,})$/);
      if (close && close[1][0] === fence[0] && close[1].length >= fence.length) {
        fence = undefined;
      }
    } else if ((fence = content.match(/^ *(`{3,}|~{3,})/)?.[1])) {
      indentedCode = false;
    } else if (blank) {
      // A blank line between two lines of an indented block belongs to the block.
      code = indentedCode;
    } else {
      indentedCode = indent >= column + 4 && (blankBefore || indentedCode);
      code = indentedCode;
      if (!code) {
        const item = content.match(/^ *(?:[*+-]|\d+[.)])(?: {1,4}|$)/);
        column = item ? item[0].length : indent < column ? 0 : column;
      }
    }
    blankBefore = blank;
    return { text, code };
  });
}

// Splits text into prose and code spans with the rules of kramdown's code span parser.
// A run of backticks that an odd number of backslashes comes before is escaped. A single
// backtick with white space, or the start of the text, before it and white space after it
// is plain text. Any other run opens a span that ends at the next place where the same
// run appears, even inside a longer run, and a run with no such place is plain text. The
// odd items are the code spans.
function splitCode(text) {
  const parts = [];
  const runs = /(?<!\\)((?:\\\\)*)(`+)/g;
  let start = 0;
  let match;
  while ((match = runs.exec(text))) {
    const opener = match.index + match[1].length;
    const run = match[2];
    if (run.length === 1 && (opener === 0 || /\s/.test(text[opener - 1])) && /\s/.test(text[runs.lastIndex] ?? '')) {
      continue;
    }
    const close = text.indexOf(run, runs.lastIndex);
    if (close >= 0) {
      parts.push(text.slice(start, opener), text.slice(opener, close + run.length));
      start = runs.lastIndex = close + run.length;
    }
  }
  parts.push(text.slice(start));
  return parts;
}

// The text with each code span replaced by a mark, and the spans the marks stand for.
function masked(text) {
  const spans = [];
  const prose = splitCode(text)
    .map((part, index) => (index % 2 ? `${span}${spans.push(part) - 1}${span}` : part))
    .join('');
  return { text: prose, unmask: (value) => value.replace(spanMark, (_, index) => spans[index]) };
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

function withoutLinks(prose, labels, unmask) {
  const reference = (link, image, text, label) => {
    const address = labels.get(unmask(label).toLowerCase());
    if (address === undefined) {
      return link;
    }
    return image ? text : linkText(text, address);
  };
  // A link around an image, such as a badge, goes in a second pass, once the image has
  // become its text. Each pass that changes the text makes it shorter, so this ends.
  for (let previous; previous !== prose; ) {
    previous = prose;
    prose = prose
      .replace(inlineLink, (_, image, text, address) => (image ? text : linkText(text, address)))
      .replace(fullReference, (link, image, text, label) => reference(link, image, text, label || text))
      .replace(/(!?)\[([^\]]+)\](?![([:])/g, (link, image, text) => reference(link, image, text, text))
      .replace(webAddress, removed);
  }
  return prose;
}

// Kramdown reads <name> outside a code span as an HTML tag and shows nothing, so a
// subject such as "profile get <profile>" keeps its placeholder only when escaped. A
// `\<` is escaped already, and kramdown shows it as `<`.
function publicProse(paragraph, labels) {
  const { text, unmask } = masked(paragraph);
  return unmask(
    withoutLinks(text, labels, unmask)
      .replace(/(?<!\\)((?:\\\\)*)</g, '$1&lt;')
      // Brackets that held only removed links go, then each mark takes one space with it.
      .replace(new RegExp(String.raw`\(\s*(?:${removed}\s*)+\)`, 'g'), removed)
      .replace(new RegExp(`\\(${removed}+ ?`, 'g'), '(')
      .replace(new RegExp(` ?${removed}+`, 'g'), ''),
  );
}

function isDefinition(line) {
  return definition.test(masked(line).text);
}

// A line that starts a block of its own, so no code span or link goes on across it.
const blockStart = /^[ \t]*(?:(?:[*+-]|\d+[.)])(?:[ \t]|$)|#|>)/;

// Drops the blank lines at the start and the end, but no white space of a code line.
function trimmed(lines) {
  const start = lines.findIndex(({ text }) => text.trim());
  return start < 0 ? [] : lines.slice(start, lines.findLastIndex(({ text }) => text.trim()) + 1);
}

// Removes the links from each paragraph as a whole, because a code span or a link can go
// on to the next line of its paragraph.
function publicText(lines, labels) {
  const kept = [];
  let paragraph = [];
  const end = () => {
    if (paragraph.length) {
      kept.push(...publicProse(paragraph.join('\n'), labels).split('\n').map((text) => ({ text, code: false })));
    }
    paragraph = [];
  };
  for (const line of lines) {
    const { text, code } = line;
    if (code || !text.trim() || blockStart.test(text) || isDefinition(text)) {
      end();
    }
    if (code || !text.trim()) {
      kept.push(line);
    } else if (!isDefinition(text)) {
      paragraph.push(text);
    }
  }
  end();
  // An entry that held only a removed reference goes, and so does a second blank line.
  const entries = [];
  for (const line of kept) {
    const blank = !line.text.trim();
    if (line.code || !(/^\s*(?:[*+-]|\d+[.)])\s*$/.test(line.text) || (blank && !entries.at(-1)?.text.trim()))) {
      entries.push(line);
    }
  }
  return trimmed(entries)
    .map(({ text }) => text)
    .join('\n');
}

// Splits lines at each heading that starts with `prefix`, but not at a line of code.
function splitAt(lines, prefix) {
  const parts = [[]];
  for (const line of lines) {
    if (!line.code && line.text.startsWith(prefix)) {
      parts.push([]);
    }
    parts.at(-1).push(line);
  }
  return parts;
}

function userFacingRelease([heading, ...sections], labels) {
  const kept = sections.flatMap(([title, ...lines]) => {
    const name = title.text.slice(4).trim();
    if (!userSections.has(name)) {
      return [];
    }
    // An upgrade step stays whatever its scope, because a user must still do it.
    let keep = true;
    const entries = publicText(
      lines.filter((line) => {
        if (!line.code && line.text.startsWith('* ') && name !== breakingChanges) {
          keep = !internalScopes.has(line.text.match(/^\* \*\*([^:*(]+)(?:\([^)]*\))?:\*\*/)?.[1]);
        }
        return keep;
      }),
      labels,
    );
    return entries ? [`${title.text.trim()}\n\n${entries}`] : [];
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
  if (markdown.includes(removed) || markdown.includes(span)) {
    throw new Error('The changelog contains a NUL or SOH control character.');
  }
  const lines = withCode(markdown);
  const labels = new Map(
    lines.flatMap(({ text, code }) => {
      const { text: prose, unmask } = masked(text);
      const match = !code && prose.match(definition);
      return match ? [[unmask(match[1]).toLowerCase(), unmask(match[2])]] : [];
    }),
  );
  const versions = new Set();
  const kept = splitAt(lines, '## ')
    .slice(1)
    .filter(([{ text }]) => {
      const version = text.match(/^## \[?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)(?=[\]\s(]|$)/)?.[1];
      if (!version) {
        throw new Error(`The changelog has a release heading with no version: ${text}`);
      }
      versions.add(version);
      return published.has(version) && published.has(version.split('-')[0]);
    })
    .map((release) => userFacingRelease(splitAt(release, '### '), labels))
    .filter(Boolean);
  if (!versions.has(highest)) {
    throw new Error(`The changelog has no section for ${highest}, the highest published release.`);
  }
  if (!kept.length) {
    throw new Error('The changelog has no entries for users in its published releases.');
  }
  return `${kept.join('\n\n')}\n`;
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
