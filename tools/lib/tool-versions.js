import fs from 'fs';
import path from 'path';

export function escapeLiquid(text) {
  return text.replace(/\$\{\{[^}]*\}\}/g, '{% raw %}$&{% endraw %}');
}

export function writeHelpTree({ tree, includesDir, fence }) {
  const closingFence = fence.match(/^`+/)?.[0] ?? fence;

  fs.rmSync(includesDir, { recursive: true, force: true });
  fs.mkdirSync(includesDir, { recursive: true });

  for (const command of tree) {
    const commandDir = path.join(includesDir, command.name);
    fs.mkdirSync(commandDir, { recursive: true });
    fs.writeFileSync(
      path.join(commandDir, 'index.md'),
      `${fence}\n${escapeLiquid(command.help)}\n${closingFence}`,
      'utf8',
    );
    console.log(`Wrote help for '${command.name}' to ${command.name}/index.md`);

    for (const subcommand of command.subcommands ?? []) {
      fs.writeFileSync(
        path.join(commandDir, `${subcommand.name}.md`),
        `${fence}\n${escapeLiquid(subcommand.help)}\n${closingFence}`,
        'utf8',
      );
      console.log(`Wrote help for '${command.name} ${subcommand.name}' to ${command.name}/${subcommand.name}.md`);
    }
  }
}

export function pruneStalePages({ docsDir, includesDir, includePattern }) {
  const docs = listFilesRecursive(docsDir).filter((filePath) => filePath.endsWith('.md'));
  let removedPages = 0;

  for (const docPath of docs) {
    const content = fs.readFileSync(docPath, 'utf8');
    const includeMatches = [...content.matchAll(includePattern)];

    if (includeMatches.length === 0) {
      continue;
    }

    const hasMissingInclude = includeMatches.some(
      (match) => !fs.existsSync(path.resolve(includesDir, match[1])),
    );

    if (hasMissingInclude) {
      fs.unlinkSync(docPath);
      removedPages += 1;
      console.log(`Removed stale page: ${docPath}`);
    }
  }

  pruneEmptyDirectories(docsDir);
  return removedPages;
}

function listFilesRecursive(rootDir) {
  const entries = fs.readdirSync(rootDir, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(rootDir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listFilesRecursive(entryPath));
    } else if (entry.isFile()) {
      files.push(entryPath);
    }
  }

  return files;
}

function pruneEmptyDirectories(rootDir, currentDir = rootDir) {
  const entries = fs.readdirSync(currentDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) {
      continue;
    }
    pruneEmptyDirectories(rootDir, path.join(currentDir, entry.name));
  }

  if (currentDir === rootDir) {
    return;
  }

  if (fs.readdirSync(currentDir).length === 0) {
    fs.rmdirSync(currentDir);
  }
}

export async function syncReleases({
  repo,
  dataFile,
  name,
  fetch = globalThis.fetch,
  writeFile = (filePath, content) => fs.writeFileSync(filePath, content, 'utf8'),
  env = process.env,
}) {
  const headers = { Accept: 'application/vnd.github+json' };
  if (env.GH_TOKEN) {
    headers.Authorization = `Bearer ${env.GH_TOKEN}`;
  }

  const response = await fetch(`https://api.github.com/repos/${repo}/releases`, { headers });

  if (!response.ok) {
    throw new Error(
      `GitHub API request for ${repo} releases failed (${response.status} ${response.statusText}). ` +
        `${repo} is a private repository: set GH_TOKEN to a GitHub token with read access to it.`,
    );
  }

  const releases = await response.json();

  const validReleases = releases
    .filter((release) => !release.draft && !release.prerelease)
    .map((release) => ({
      version: release.tag_name.replace(/^v/, ''),
      released: release.published_at.split('T')[0],
    }));

  if (validReleases.length === 0) {
    console.warn('No valid releases found');
    return [];
  }

  const releasesBySeries = {};
  for (const release of validReleases) {
    const [major, minor] = release.version.split('.');
    const series = `${major}.${minor}`;
    if (!releasesBySeries[series] || compareVersions(release.version, releasesBySeries[series].version) > 0) {
      releasesBySeries[series] = release;
    }
  }

  const seriesList = Object.entries(releasesBySeries)
    .map(([series, release]) => ({ release: series, ...release }))
    .sort((a, b) => compareVersions(b.version, a.version))
    .slice(0, 10);

  seriesList[0].latest = true;

  let yamlContent = `name: ${name}\n\nreleases:\n`;
  for (const release of seriesList) {
    yamlContent += `  - release: "${release.release}"\n`;
    yamlContent += `    version: "${release.version}"\n`;
    if (release.latest) {
      yamlContent += `    latest: true\n`;
    }
    yamlContent += `    released: ${release.released}\n`;
  }

  writeFile(dataFile, yamlContent);
  return seriesList;
}

function compareVersions(a, b) {
  const aParts = a.split('.').map(Number);
  const bParts = b.split('.').map(Number);

  for (let i = 0; i < Math.max(aParts.length, bParts.length); i++) {
    const aNum = aParts[i] || 0;
    const bNum = bParts[i] || 0;

    if (aNum > bNum) return 1;
    if (aNum < bNum) return -1;
  }

  return 0;
}
