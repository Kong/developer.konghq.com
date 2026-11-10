import path from 'path';
import { fileURLToPath } from 'url';
import { syncReleases } from '../lib/tool-versions.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

(async () => {
  try {
    const series = await syncReleases({
      repo: 'Kong/kongctl',
      name: 'kongctl',
      dataFile: path.resolve(__dirname, '../../app/_data/tools/kongctl.yml'),
    });

    if (series.length > 0) {
      console.log(`Updated kongctl versions (${series.length} releases)`);
      console.log(`Latest version: ${series[0].version}`);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
})();
