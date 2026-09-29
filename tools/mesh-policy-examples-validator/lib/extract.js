import { parseHTML } from "linkedom";
import { parseAllDocuments } from "yaml";

const CHECKED_PANELS = new Set(["kubernetes", "universal"]);

export function extractBlocks(html) {
  const { document } = parseHTML(html);
  const blocks = [];

  for (const codeEl of document.querySelectorAll(
    'div[data-tab-group^="policy-yaml"] div[data-panel] code[id]',
  )) {
    const panel = codeEl.closest("[data-panel]")?.getAttribute("data-panel");
    if (!CHECKED_PANELS.has(panel)) continue;
    blocks.push({ panel, text: codeEl.textContent });
  }

  return blocks;
}

export function extractDocuments(html) {
  const entries = [];
  const findings = [];

  for (const { panel, text } of extractBlocks(html)) {
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
