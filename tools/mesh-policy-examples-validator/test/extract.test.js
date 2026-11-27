import test from "node:test";
import assert from "node:assert/strict";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import {
  countPolicyYamlGroups,
  countPolicyYamlInstances,
  extractBlocks,
  extractDocuments,
  extractTerraformBlocks,
} from "../lib/extract.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const fixture = (name) =>
  fs.readFileSync(path.join(__dirname, "fixtures", name), "utf-8");

function tabGroup(panels) {
  return `<div data-tab-group="policy-yaml x">${panels}</div>`;
}

function panel(name, codes) {
  return `<div data-panel="${name}">${codes}</div>`;
}

function code(id, text) {
  return `<code id="${id}">${text}</code>`;
}

test("a page publishing one block per tab extracts each, recording its panel", () => {
  const blocks = extractBlocks(fixture("single-variant.html"));
  const panels = blocks.map((b) => b.panel);

  assert.deepEqual(panels, ["kubernetes", "universal", "terraform"]);
  assert.ok(blocks[0].text.includes("kind: MeshTimeout"));
  assert.ok(blocks[1].text.includes("type: MeshTimeout"));
  assert.ok(blocks[2].text.includes('resource "konnect_mesh_timeout"'));
});

test("a use_meshservice page extracts both variants per tab independently", () => {
  const blocks = extractBlocks(fixture("use-meshservice.html"));
  const panels = blocks.map((b) => b.panel);

  assert.deepEqual(panels, [
    "kubernetes",
    "kubernetes",
    "universal",
    "universal",
    "terraform",
  ]);
});

test("a prose code block outside the tab group is not extracted", () => {
  const blocks = extractBlocks(fixture("zone-egress.html"));
  const panels = blocks.map((b) => b.panel);

  assert.deepEqual(panels, ["kubernetes", "universal", "terraform"]);
  assert.ok(!blocks.some((b) => b.text.includes("example-1")));
});

test("the terraform panel is extracted as raw text and kept out of the YAML rules", () => {
  const html = fixture("single-variant.html");
  const tfBlocks = extractTerraformBlocks(html);

  assert.equal(tfBlocks.length, 1);
  assert.equal(tfBlocks[0].panel, "terraform");
  assert.match(tfBlocks[0].text, /^resource "konnect_mesh_timeout"/);

  const { entries, findings } = extractDocuments(html);
  assert.ok(!entries.some((e) => e.panel === "terraform"));
  assert.equal(findings.length, 0);
});

test("a block holding several YAML documents parses to one entry per document", () => {
  const html = tabGroup(
    panel(
      "universal",
      code(
        "a",
        "type: MeshTimeout\nname: one\n---\ntype: MeshTimeout\nname: two",
      ),
    ),
  );
  const { entries, findings } = extractDocuments(html);

  assert.equal(findings.length, 0);
  assert.equal(entries.length, 2);
  assert.equal(entries[0].value.name, "one");
  assert.equal(entries[1].value.name, "two");
});

test("a block that isn't parseable as YAML reports a finding", () => {
  const html = tabGroup(
    panel("universal", code("a", "type: MeshTimeout\n  bad: [unclosed")),
  );
  const { entries, findings } = extractDocuments(html);

  assert.equal(entries.length, 0);
  assert.equal(findings.length, 1);
  assert.equal(findings[0].panel, "universal");
  assert.equal(findings[0].pointer, "/");
});

test("a page with three policy-yaml tab groups numbers every block by its instance in document order", () => {
  const group = (id, name) =>
    tabGroup(
      panel("kubernetes", code(id, `kind: MeshTimeout\nmetadata:\n  name: ${name}`)) +
        panel("universal", code(`u-${id}`, `type: MeshTimeout\nname: ${name}`)),
    );
  const blocks = extractBlocks(group("a", "one") + group("b", "two") + group("c", "three"));

  assert.deepEqual(
    blocks.map((b) => [b.instance, b.panel]),
    [
      [1, "kubernetes"],
      [1, "universal"],
      [2, "kubernetes"],
      [2, "universal"],
      [3, "kubernetes"],
      [3, "universal"],
    ],
  );
});

test("a dual-variant tab keeps both code blocks under one instance ordinal", () => {
  const html = tabGroup(
    panel(
      "kubernetes",
      code("legacy", "kind: MeshService") + code("variant", "kind: MeshService"),
    ),
  );
  const blocks = extractBlocks(html);

  assert.deepEqual(
    blocks.map((b) => [b.instance, b.panel]),
    [
      [1, "kubernetes"],
      [1, "kubernetes"],
    ],
  );
});

test("another tab group on the page contributes no blocks and no ordinals", () => {
  const html =
    tabGroup(panel("kubernetes", code("a", "kind: MeshTimeout"))) +
    `<div data-tab-group="support-matrix x">${panel("kubernetes", code("b", "kind: Nope"))}</div>` +
    tabGroup(panel("universal", code("c", "type: MeshTimeout")));
  const blocks = extractBlocks(html);

  assert.deepEqual(
    blocks.map((b) => [b.instance, b.panel]),
    [
      [1, "kubernetes"],
      [2, "universal"],
    ],
  );
});

test("a single-instance page keeps its existing block output", () => {
  const blocks = extractBlocks(fixture("single-variant.html"));

  assert.deepEqual(blocks.map((b) => b.panel), [
    "kubernetes",
    "universal",
    "terraform",
  ]);
  assert.ok(blocks.every((b) => b.instance === 1));
});

test("the source-instance counter counts policy_yaml invocations per source file", () => {
  const source = [
    "---",
    "title: MeshTimeout",
    "---",
    "",
    "{% policy_yaml /mesh/meshtimeout/examples/basic.yaml %}",
    "",
    "Some prose in between.",
    "",
    "{% policy_yaml /examples/another.yaml %}",
    "",
    "{% policy_yaml /examples/third.yaml %}",
  ].join("\n");

  assert.equal(countPolicyYamlInstances(source), 3);
});

test("the source-instance counter returns zero for a file without the tag", () => {
  assert.equal(countPolicyYamlInstances("---\ntitle: No tags\n---\n\nprose\n"), 0);
});

test("the tab-group counter counts policy-yaml groups, including empty ones", () => {
  const html =
    tabGroup(panel("kubernetes", code("a", "kind: MeshTimeout"))) +
    `<div data-tab-group="policy-yaml x"></div>` +
    tabGroup(panel("universal", code("b", "type: MeshTimeout")));

  assert.equal(countPolicyYamlGroups(html), 3);
});

test("the tab-group counter ignores other tab groups", () => {
  const html =
    tabGroup(panel("kubernetes", code("a", "kind: MeshTimeout"))) +
    `<div data-tab-group="support-matrix x">${panel("kubernetes", code("b", "kind: Nope"))}</div>`;

  assert.equal(countPolicyYamlGroups(html), 1);
});
