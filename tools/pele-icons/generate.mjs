#!/usr/bin/env node
import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(SCRIPT_DIR, "../../");
const ICON_DIRS = ["app/assets/icons", "app/assets/logos"];
// Pele renders every label icon inside a fixed 24x24 viewBox, so an icon that
// declares a different intrinsic size is clipped unless it is normalized to it.
const ICON_BOX = 24;
const OUTPUT_PATH = resolve(SITE_ROOT, "app/_assets/javascripts/diagram-icons.js");
const SOURCE_EXTENSIONS = [".md", ".yaml", ".yml", ".html", ".liquid"];
const SKIPPED_DIRS = [".repos", "node_modules", ".jekyll-cache", ".git"];
const BLOCK_SOURCE_RE = /\.(md|html|liquid)$/;
// Mirrors the token Pele parses. Pele's own pattern is /(fa[bklrs]?):fa-([\w-]+)/g,
// which is a single segment: it stops at a slash.
const TOKEN_RE = /\b(fa[bklrs]?):fa-([A-Za-z0-9][A-Za-z0-9._-]*)/g;
const NESTED_TOKEN_RE = /\b(fa[bklrs]?):fa-([A-Za-z0-9._-]+\/[A-Za-z0-9._/-]+)/g;
const MERMAID_BLOCK_RE = /\{%\s*mermaid\s*%\}([\s\S]*?)\{%\s*endmermaid\s*%\}/g;

function walkSources(dir, sources = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!SKIPPED_DIRS.includes(entry.name)) walkSources(join(dir, entry.name), sources);
    } else if (SOURCE_EXTENSIONS.includes(entry.name.slice(entry.name.lastIndexOf(".")))) {
      sources.push(join(dir, entry.name));
    }
  }
  return sources;
}

function mermaidSources(file) {
  const content = readFileSync(file, "utf8");
  if (BLOCK_SOURCE_RE.test(file)) {
    const blocks = [];
    for (const match of content.matchAll(MERMAID_BLOCK_RE)) blocks.push(match[1]);
    return blocks;
  }
  return [content];
}

function referencedIconNames() {
  const names = new Set();
  const nested = [];
  for (const file of walkSources(join(SITE_ROOT, "app"))) {
    for (const source of mermaidSources(file)) {
      for (const match of source.matchAll(NESTED_TOKEN_RE)) {
        nested.push(`${relative(SITE_ROOT, file)}: ${match[0]}`);
      }
      for (const match of source.matchAll(TOKEN_RE)) names.add(match[2]);
    }
  }
  if (nested.length > 0) {
    throw new Error(
      "pele-icons: icon tokens cannot contain '/', Pele parses a single hyphenated " +
        `segment (${TOKEN_RE}). Replace '/' with '-' in these tokens:\n  ${nested.join("\n  ")}`,
    );
  }
  return [...names].sort();
}

function walkIcons(dir, files = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) walkIcons(full, files);
    else if (entry.name.endsWith(".svg")) files.push(full);
  }
  return files;
}

function flatIconName(file, iconDir) {
  return relative(join(SITE_ROOT, iconDir), file)
    .replace(/\.svg$/, "")
    .split(sep)
    .join("-");
}

function buildIconIndex() {
  const index = new Map();
  for (const iconDir of ICON_DIRS) {
    const root = join(SITE_ROOT, iconDir);
    if (!existsSync(root)) continue;
    for (const file of walkIcons(root)) {
      const name = flatIconName(file, iconDir);
      const existing = index.get(name);
      if (existing !== undefined) {
        // The same logo often exists under both icons/ and logos/; the first
        // directory wins, matching the previous lookup order. Only a collision
        // inside one directory is a real ambiguity.
        if (existing.iconDir === iconDir) {
          console.warn(
            `pele-icons: fa:fa-${name} is ambiguous, ${relative(SITE_ROOT, existing.file)} ` +
              `and ${relative(SITE_ROOT, file)} both flatten to the same token.`,
          );
        }
        continue;
      }
      index.set(name, { file, iconDir });
    }
  }
  return index;
}

function numericAttr(attrs, name) {
  const match = attrs.match(new RegExp(`\\s${name}="\\s*([0-9.]+)(?:px)?"`));
  return match ? Number.parseFloat(match[1]) : 0;
}

function intrinsicSize(rootTag) {
  const viewBox = rootTag.match(/\sviewBox="([^"]*)"/);
  if (viewBox) {
    const parts = viewBox[1].trim().split(/[\s,]+/).map(Number);
    if (parts.length === 4 && parts[2] > 0 && parts[3] > 0) return [parts[2], parts[3]];
  }
  const width = numericAttr(rootTag, "width");
  const height = numericAttr(rootTag, "height");
  if (width > 0 && height > 0) return [width, height];
  return [ICON_BOX, ICON_BOX];
}

function normalizeIcon(svg) {
  const rootStart = svg.search(/<svg\b/);
  if (rootStart === -1) throw new Error("no root <svg> element found");
  const rootTag = svg.slice(rootStart).match(/^<svg\b[^>]*>/)[0];
  const body = svg
    .slice(rootStart + rootTag.length)
    .replace(/<style\b[\s\S]*?(<\/style>|$)/gi, "");
  const [width, height] = intrinsicSize(rootTag);
  const viewBox = rootTag.match(/\sviewBox="([^"]*)"/)?.[1] ?? `0 0 ${width} ${height}`;
  const rest = rootTag
    .replace(/\s(width|height|id|stroke|viewBox)="[^"]*"/g, "")
    .replace(/^<svg\b/, "");
  return `<svg width="${ICON_BOX}" height="${ICON_BOX}" viewBox="${viewBox}" stroke="none"${rest}>${body}`;
}

export function buildIconMap() {
  const index = buildIconIndex();
  const icons = {};
  for (const name of referencedIconNames()) {
    const entry = index.get(name);
    if (entry === undefined) {
      console.warn(`pele-icons: no SVG found for fa:fa-${name}`);
      continue;
    }
    icons[name] = normalizeIcon(readFileSync(entry.file, "utf8"));
  }
  return icons;
}

function emitModule(icons) {
  const entries = Object.entries(icons)
    .map(([name, markup]) => `  ${JSON.stringify(name)}: ${JSON.stringify(markup)},`)
    .join("\n");
  writeFileSync(
    OUTPUT_PATH,
    `// Generated by tools/pele-icons/generate.mjs. Do not edit.\n` +
      `// Re-run the generator whenever a Mermaid diagram references a new image.\n` +
      `export default {\n${entries}\n};\n`,
  );
}

function main() {
  const icons = buildIconMap();
  emitModule(icons);
  console.log(
    `pele-icons: wrote ${Object.keys(icons).length} icons to ${relative(SITE_ROOT, OUTPUT_PATH)}`,
  );
}

const invokedDirectly =
  process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invokedDirectly) main();
