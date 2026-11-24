import path from 'path';
import { fileURLToPath } from 'url';
import { syncReleases } from '../lib/tool-versions.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

(async () => {
  try {
    const repo = process.env.KONG_HARNESSES_RELEASES_REPO;
    if (!repo) {
      throw new Error('Set KONG_HARNESSES_RELEASES_REPO to the <owner>/<name> of the repository that publishes the kong-harnesses releases');
    }
    const series = await syncReleases({
      repo,
      name: 'kong-harnesses',
      tokenRequired: true,
      dataFile: path.resolve(__dirname, '../../app/_data/tools/kong-harnesses.yml'),
    });

    console.log(`Updated kong-harnesses versions (${series.length} releases)`);
    console.log(`Latest version: ${series[0].version}`);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
})();
