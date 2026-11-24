import { parseHTML } from "linkedom";
import { parseAllDocuments } from "yaml";

const PANELS = new Set(["kubernetes", "universal", "terraform"]);
const YAML_PANELS = new Set(["kubernetes", "universal"]);

export function extractBlocks(html) {
  const { document } = parseHTML(html);
  const blocks = [];
  // A page may publish several {% policy_yaml %} instances; each renders one
  // tab group. Number the groups in document order so a block records which
  // instance it came from. A dual-variant tab emits two code elements in one
  // panel, so panels are not a valid grouping unit.
  const groupOrdinals = new Map();

  for (const codeEl of document.querySelectorAll(
    'div[data-tab-group^="policy-yaml"] div[data-panel] code[id]',
  )) {
    const panel = codeEl.closest("[data-panel]")?.getAttribute("data-panel");
    if (!PANELS.has(panel)) continue;
    const group = codeEl.closest('[data-tab-group^="policy-yaml"]');
    if (!groupOrdinals.has(group)) {
      groupOrdinals.set(group, groupOrdinals.size + 1);
    }
    blocks.push({
      panel,
      text: codeEl.textContent,
      instance: groupOrdinals.get(group),
    });
  }

  return blocks;
}

// The number of policy-yaml tab groups in the built page, regardless of
// whether any of them hold extractable blocks.
export function countPolicyYamlGroups(html) {
  const { document } = parseHTML(html);
  return document.querySelectorAll('div[data-tab-group^="policy-yaml"]').length;
}

// The number of {% policy_yaml %} invocations in a source file. The built page
// must render one tab group per invocation.
export function countPolicyYamlInstances(sourceText) {
  return (sourceText.match(/\{%\s*policy_yaml/g) || []).length;
}

// A terraform block is not YAML: it is extracted as raw text and never
// reaches the YAML parse, schema, empty-value, or marker rules.
export function extractTerraformBlocks(html) {
  return extractBlocks(html).filter((block) => block.panel === "terraform");
}

export function extractDocuments(html) {
  const entries = [];
  const findings = [];

  for (const { panel, text, instance } of extractBlocks(html)) {
    if (!YAML_PANELS.has(panel)) continue;

    for (const doc of parseAllDocuments(text)) {
      if (doc.errors.length > 0) {
        findings.push({ panel, pointer: "/", message: doc.errors[0].message, instance });
        continue;
      }
      entries.push({ panel, value: doc.toJS(), instance });
    }
  }

  return { entries, findings };
}
