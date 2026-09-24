import { parseHTML } from "linkedom";
import { parseAllDocuments } from "yaml";

const PANELS = new Set(["kubernetes", "universal", "terraform"]);
const YAML_PANELS = new Set(["kubernetes", "universal"]);

export function extractBlocks(html) {
  const { document } = parseHTML(html);
  const blocks = [];

  for (const codeEl of document.querySelectorAll(
    'div[data-tab-group^="policy-yaml"] div[data-panel] code[id]',
  )) {
    const panel = codeEl.closest("[data-panel]")?.getAttribute("data-panel");
    if (!PANELS.has(panel)) continue;
    blocks.push({ panel, text: codeEl.textContent });
  }

  return blocks;
}

// A terraform block is not YAML: it is extracted as raw text and never
// reaches the YAML parse, schema, empty-value, or marker rules.
export function extractTerraformBlocks(html) {
  return extractBlocks(html)
    .filter((block) => block.panel === "terraform")
    .map((block) => block.text);
}

export function extractDocuments(html) {
  const entries = [];
  const findings = [];

  for (const { panel, text } of extractBlocks(html)) {
    if (!YAML_PANELS.has(panel)) continue;

    for (const doc of parseAllDocuments(text)) {
      if (doc.errors.length > 0) {
        findings.push({ panel, pointer: "/", message: doc.errors[0].message });
        continue;
      }
      entries.push({ panel, value: doc.toJS() });
    }
  }

  return { entries, findings };
}
