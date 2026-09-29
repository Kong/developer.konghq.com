import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const eq = key.indexOf('=');
      if (eq !== -1) {
        args[key.slice(0, eq)] = key.slice(eq + 1);
      } else {
        args[key] = argv[++i];
      }
    }
  }
  return args;
}

(async () => {
  const args = parseArgs(process.argv);
  const konnectToken = args['konnect-token'] || process.env.KONNECT_TOKEN;
  const aigwId = args['aigw-id'] || process.env.AIGW_ID;
  const domain = args['domain'] || process.env.KONNECT_DOMAIN || 'com';

  if (!konnectToken) {
    console.error('Error: --konnect-token is required (or set KONNECT_TOKEN)');
    process.exit(1);
  }
  if (!aigwId) {
    console.error('Error: --aigw-id is required (or set AIGW_ID)');
    process.exit(1);
  }

  const url = `https://us.api.konghq.${domain}/v1/ai-gateways/${aigwId}/available-policies`;

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json, application/problem+json',
        'Authorization': `Bearer ${konnectToken}`,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`API error ${response.status} ${response.statusText}: ${body}`);
    }

    const payload = await response.json();
    const data = Array.isArray(payload?.data) ? payload.data : [];

    const outputPath = path.resolve(__dirname, '../../app/_data/policies/ai-gateway/scopes.json');
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, JSON.stringify(data, null, 2) + '\n', 'utf8');

    console.log(`Wrote ${data.length} policies to ${path.relative(process.cwd(), outputPath)}`);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
})();
