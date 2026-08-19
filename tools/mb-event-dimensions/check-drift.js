// Detect drift in the Metering & Billing emitted-event fields.
//
//   node check-drift.js <doc.json>
//
// Compares the field catalog freshly extracted from the kong-ee LuaLS export
// against two things:
//   1. the committed baseline snapshot (event-fields.snapshot.json) — the
//      "known good" the docs were last reconciled with; drift here is what the
//      scheduled workflow turns into an alert PR.
//   2. the rendered reference data file (app/_data/plugins/metering-and-billing.yaml)
//      — so the published tables can't silently disagree with the plugin.
//
// Exits non-zero (with a printed diff) on any drift; exit 0 when everything agrees.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import yaml from 'js-yaml';
import { extractCatalog } from './extract-catalog.js';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SNAPSHOT = path.join(HERE, 'event-fields.snapshot.json');
const DATA_FILE = path.resolve(HERE, '../../app/_data/plugins/metering-and-billing.yaml');

const nameSet = (fields) => new Set(fields.map((f) => f.name));
const typeMap = (fields) => new Map(fields.map((f) => [f.name, f.type]));
const diff = (a, b) => ({ added: [...b].filter((x) => !a.has(x)), removed: [...a].filter((x) => !b.has(x)) });

const docPath = process.argv[2];

if (!docPath) {
  console.error('usage: node check-drift.js <doc.json>');
  process.exit(2);
}

const current = extractCatalog(docPath);
let problems = 0;

// 1) drift vs committed snapshot (added / removed / type-changed, keyed by field name)
const snapshot = JSON.parse(fs.readFileSync(SNAPSHOT, 'utf8'));

for (const event of Object.keys(current)) {
  const cur = typeMap(current[event]);
  const snap = typeMap(snapshot[event] || []);
  const added = [...cur.keys()].filter((n) => !snap.has(n));
  const removed = [...snap.keys()].filter((n) => !cur.has(n));
  const changed = [...cur.keys()].filter((n) => snap.has(n) && snap.get(n) !== cur.get(n));

  if (added.length || removed.length || changed.length) {
    problems++;
    console.error(`DRIFT vs snapshot [${event}]:`);
    added.forEach((n) => console.error(`  + ${n}: ${cur.get(n)}   (new in cloudevent.lua)`));
    removed.forEach((n) => console.error(`  - ${n}: ${snap.get(n)}   (gone from cloudevent.lua)`));
    changed.forEach((n) => console.error(`  ~ ${n}: ${snap.get(n)} → ${cur.get(n)}   (type changed)`));
  }
}

// 2) rendered data file must match the code catalog (field names)
const data = yaml.load(fs.readFileSync(DATA_FILE, 'utf8'));
const portal = (data.portal_fields || []).map((f) => f.field);

for (const ev of data.events || []) {
  const shipped = new Set([...(ev.fields || []).map((f) => f.field), ...portal]);
  const code = nameSet(current[ev.type] || []);
  const { added, removed } = diff(code, shipped);

  if (added.length || removed.length) {
    problems++;
    console.error(`DOC MISMATCH [${ev.type}] (data file vs cloudevent.lua):`);
    added.forEach((x) => console.error(`  data-file only (not emitted): ${x}`));
    removed.forEach((x) => console.error(`  emitted but undocumented:     ${x}`));
  }
}

if (problems) {
  console.error(`\n${problems} problem(s) found — the docs reference needs updating.`);
  process.exit(1);
}

console.log('OK: extracted catalog matches the snapshot and the rendered data file.');
