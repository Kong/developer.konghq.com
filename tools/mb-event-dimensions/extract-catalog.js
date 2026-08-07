// Extract the Metering & Billing emitted-event field catalog from the LuaLS
// `--doc` JSON export (doc.json) of the kong-ee cloudevent.lua annotations.
//
//   lua-language-server --doc <dir> --doc_out_path <out>   # produces <out>/doc.json
//   node extract-catalog.js <out>/doc.json [--out catalog.json]
//
// doc.json is an array of type definitions; each of our event classes carries a
// `.fields` array with inheritance already resolved (portal fields folded in).
import fs from 'node:fs';

// LuaLS class name -> emitted CloudEvent type.
export const CLASS_TO_EVENT = {
  'kong.mnb.ApiRequestData': 'kong.api_request',
  'kong.mnb.LlmRequestData': 'kong.llm_request',
};

// Fail-loud floor: if the parser finds fewer than this, the annotations were
// probably renamed/removed or the export shape changed — better to error than
// emit a wrong catalog that would silently pass the drift check.
const MIN_FIELDS = 10;

export function extractCatalog(docJsonPath) {
  const doc = JSON.parse(fs.readFileSync(docJsonPath, 'utf8'));

  if (!Array.isArray(doc)) throw new Error(`${docJsonPath}: expected a JSON array from lua-language-server --doc`);

  const byName = new Map(doc.map((x) => [x.name, x]));
  const catalog = {};

  for (const [cls, event] of Object.entries(CLASS_TO_EVENT)) {
    const entry = byName.get(cls);

    if (!entry) throw new Error(`doc.json: class '${cls}' not found — cloudevent.lua annotations missing or renamed?`);

    const fields = (entry.fields || [])
      .map((f) => ({ name: f.name, type: (f.extends && f.extends.view) || 'unknown' }))
      .sort((a, b) => a.name.localeCompare(b.name));

    if (fields.length < MIN_FIELDS) {
      throw new Error(`doc.json: class '${cls}' yielded only ${fields.length} fields (expected >= ${MIN_FIELDS})`);
    }

    catalog[event] = fields;
  }

  return catalog;
}

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const docPath = process.argv[2];

  if (!docPath) {
    console.error('usage: node extract-catalog.js <doc.json> [--out <file>]');
    process.exit(2);
  }

  const catalog = extractCatalog(docPath);
  const json = JSON.stringify(catalog, null, 2) + '\n';
  const outIdx = process.argv.indexOf('--out');

  if (outIdx !== -1 && process.argv[outIdx + 1]) {
    fs.writeFileSync(process.argv[outIdx + 1], json);
    console.error(`wrote ${process.argv[outIdx + 1]}`);
  } else {
    process.stdout.write(json);
  }
}
