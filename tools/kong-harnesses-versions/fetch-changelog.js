import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repo = 'Kong/kong-harnesses';

// The repository is internal, so links into it break for readers of the site.
// The Mesh changelog drops them the same way (mesh.ignored_links_regex).
export function publicChangelog(markdown, repoName = repo) {
  const base = `https://github\\.com/${repoName.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&')}`;
  const body = markdown
    .replace(/^# Changelog\s*\n/, '')
    .replace(new RegExp(` \\(\\[[^\\]]*\\]\\(${base}/(?:issues|pull|commit)/[^)]*\\)\\)`, 'gi'), '')
    .replace(new RegExp(`\\[([^\\]]*)\\]\\(${base}[^)]*\\)`, 'gi'), '$1')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
  return `{% raw %}\n${body}\n{% endraw %}\n`;
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
