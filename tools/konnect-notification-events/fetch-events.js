import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const outputPath = path.resolve(scriptDir, '../../app/_data/konnect_notification_events.json');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith('--')) continue;
    const [key, inlineValue] = arg.slice(2).split('=', 2);
    args[key] = inlineValue ?? argv[++i];
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv);
  const token = args['konnect-token'] || process.env.KONNECT_TOKEN;
  const baseUrl = (args['base-url'] || process.env.KONNECT_API_BASE_URL || 'https://global.api.konghq.com/v1').replace(/\/$/, '');

  if (!token) {
    throw new Error('Provide --konnect-token or set KONNECT_TOKEN.');
  }

  const response = await fetch(`${baseUrl}/notifications/configurations/organization`, {
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`API error ${response.status} ${response.statusText}: ${body}`);
  }

  const payload = await response.json();
  if (!Array.isArray(payload?.data)) {
    throw new Error('Unexpected API response: expected a data array.');
  }

  const events = payload.data
    .map(({ event_type, event_title, event_description, event_namespace }) => ({
      event_type,
      event_title,
      event_description,
      event_namespace,
    }))
    .sort((a, b) => a.event_namespace.localeCompare(b.event_namespace) || a.event_title.localeCompare(b.event_title));

  fs.writeFileSync(outputPath, `${JSON.stringify(events, null, 2)}\n`, 'utf8');
  console.log(`Wrote ${events.length} organization events to ${path.relative(process.cwd(), outputPath)}`);
}

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exitCode = 1;
});
