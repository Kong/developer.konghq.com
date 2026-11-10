import path from 'path';
import { fileURLToPath } from 'url';
import { syncReleases } from '../lib/tool-versions.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

(async () => {
  try {
    const series = await syncReleases({
      repo: 'Kong/kong-harnesses',
      name: 'kong-harnesses',
      internalRepo: true,
      dataFile: path.resolve(__dirname, '../../app/_data/tools/kong-harnesses.yml'),
    });

    if (series.length > 0) {
      console.log(`Updated kong-harnesses versions (${series.length} releases)`);
      console.log(`Latest version: ${series[0].version}`);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
})();
