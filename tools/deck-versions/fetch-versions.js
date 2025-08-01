import fetch from 'node-fetch';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function fetchDeckReleaseNames() {
  const response = await fetch('https://api.github.com/repos/kong/deck/releases');
  if (!response.ok) {
    console.error('Failed to fetch releases:', response.statusText);
    return;
  }

  const releases = await response.json();
  const releaseNames = releases.slice(0, 10);


  const deckDataPath = path.resolve(__dirname, '../../app/_data/tools/deck.yml');

  const seenReleases = {};

  const formattedReleases = releaseNames.map((r, index) => {
    const version = r.name.replace(/^v/, '');
    const [major, minor] = version.split('.');
    const release = `${major}.${minor}`;
    if (seenReleases[release]) {
      return;
    }

    const releaseData = {
      release,
      version: version,
      published_at: r.published_at.split("T")[0]
    };
    if (index == 0) {
      releaseData.latest = true;
    }
    seenReleases[release] = true;
    return releaseData;
  }).filter(Boolean);

  const yamlContent = `name: deck\n\nreleases:\n${formattedReleases
    .map(r => `  - release: "${r.release}"\n    version: "${r.version}"\n${r.latest ? `    latest: true\n` : ''}    released: ${r.published_at}`)
    .join('\n')}`;

  fs.writeFileSync(deckDataPath, yamlContent, 'utf8');
  console.log('Updated deck.yml successfully');

}

fetchDeckReleaseNames();
