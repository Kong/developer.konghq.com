import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repo = 'Kong/kong-harnesses';

// Readers of the site need what changed for them, not the repository's own build, CI,
// docs and review work, so only these sections are published.
const userSections = new Set(['⚠ BREAKING CHANGES', 'Features', 'Bug Fixes', 'Performance']);
// Scopes of fixes to the repository's own tooling and reviews.
const internalScopes = new Set(['ci', 'ksai', 'threat-model']);

function userFacingRelease(release) {
  const [heading, ...sections] = release.split(/^(?=### )/m);
  const kept = sections.flatMap((section) => {
    const [title, ...lines] = section.trim().split('\n');
    if (!userSections.has(title.slice(4).trim())) {
      return [];
    }
    let keep = false;
    const entries = lines
      .filter((line) => {
        if (line.startsWith('* ')) {
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
// The Mesh changelog drops them the same way (mesh.ignored_links_regex).
// Vale stays off because the entries are commit subjects full of code names.
export function publicChangelog(markdown, repoName = repo) {
  const base = `https://github\\.com/${repoName.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&')}(?![\\w.-])`;
  const body = markdown
    .replace(/^# Changelog\s*\n/, '')
    .replace(new RegExp(` \\(\\[[^\\]]*\\]\\(${base}/(?:issues|pull|commit)/[^)]*\\)\\)`, 'gi'), '')
    .replace(new RegExp(`\\[([^\\]]*)\\]\\(${base}[^)]*\\)`, 'gi'), '$1')
    .split(/^(?=## )/m)
    .map(userFacingRelease)
    .filter(Boolean)
    .join('\n\n')
    .replace(/\n{3,}/g, '\n\n');
  if (body.includes('{% endraw')) {
    throw new Error('The changelog contains {% endraw %}, which would end the raw block early.');
  }
  return `<!--vale off-->\n{% raw %}\n${body}\n{% endraw %}\n<!--vale on-->\n`;
}

export async function syncChangelog({ outFile, fetch = globalThis.fetch, env = process.env }) {
  const headers = { Accept: 'application/vnd.github+json' };
  if (env.GH_TOKEN) {
    headers.Authorization = `Bearer ${env.GH_TOKEN}`;
  }

  const latest = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, { headers });
  if (!latest.ok) {
    throw new Error(
      `GitHub API request for the latest ${repo} release failed (${latest.status} ${latest.statusText}). ${repo} is an internal repository: set GH_TOKEN to a GitHub token with read access to it.`,
    );
  }
  const { tag_name: tag } = await latest.json();

  const file = await fetch(`https://api.github.com/repos/${repo}/contents/CHANGELOG.md?ref=${tag}`, {
    headers: { ...headers, Accept: 'application/vnd.github.raw' },
  });
  if (!file.ok) {
    throw new Error(`GitHub API request for ${repo} CHANGELOG.md at ${tag} failed (${file.status} ${file.statusText}).`);
  }

  fs.writeFileSync(outFile, publicChangelog(await file.text()), 'utf8');
  return tag;
}

const isEntry = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isEntry) {
  syncChangelog({ outFile: path.resolve(__dirname, '../../app/_includes/kong-harnesses/changelog.md') })
    .then((tag) => console.log(`Wrote the kong-harnesses changelog at ${tag}`))
    .catch((error) => {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    });
}
