import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

(async () => {
  try {
    // Fetch releases from GitHub API
    const response = await fetch('https://api.github.com/repos/Kong/kongctl/releases');

    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.statusText}`);
    }

    const releases = await response.json();

    // Filter to only include actual releases (not pre-releases or drafts)
    const validReleases = releases
      .filter(r => !r.draft && !r.prerelease)
      .map(r => ({
        version: r.tag_name.replace(/^v/, ''), // Remove 'v' prefix
        released: r.published_at.split('T')[0], // Extract date only
        tag: r.tag_name
      }))
      .slice(0, 10); // Keep last 10 releases

    if (validReleases.length === 0) {
      console.warn('No valid releases found');
      return;
    }

    // Group by release series (e.g., "0.3" for v0.3.x)
    const releasesByVersion = {};

    validReleases.forEach(r => {
      const parts = r.version.split('.');
      const release = `${parts[0]}.${parts[1]}`;

      if (!releasesByVersion[release] ||
          compareVersions(r.version, releasesByVersion[release].version) > 0) {
        releasesByVersion[release] = r;
      }
    });

    // Build YAML structure
    const yamlReleases = Object.entries(releasesByVersion)
      .map(([release, info]) => ({
        release,
        version: info.version,
        released: info.released
      }))
      .sort((a, b) => compareVersions(b.version, a.version));

    // Mark latest
    if (yamlReleases.length > 0) {
      yamlReleases[0].latest = true;
    }

    // Write to YAML file
    const outputPath = path.resolve(__dirname, '../../app/_data/tools/kongctl.yml');
    let yamlContent = 'name: kongctl\n\nreleases:\n';

    yamlReleases.forEach(r => {
      yamlContent += `  - release: "${r.release}"\n`;
      yamlContent += `    version: "${r.version}"\n`;
      if (r.latest) {
        yamlContent += `    latest: true\n`;
      }
      yamlContent += `    released: ${r.released}\n`;
    });

    fs.writeFileSync(outputPath, yamlContent, 'utf8');
    console.log(`Updated kongctl versions (${yamlReleases.length} releases)`);
    console.log(`Latest version: ${yamlReleases[0].version}`);

  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
})();

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
