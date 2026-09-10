#!/usr/bin/env node
/**
 * Collect testable how-to URLs for one product, for feeding into
 * tools/automated-tests/generate-instructions-files.js --product=...
 *
 * Usage:  node collect-urls.mjs <product> [baseUrl]
 * Output: JSON { product, root, urls: [...], skipped: [{ file, reason }] }
 *
 * Scope: app/_how-tos/<product>/**\/*.md, excluding any directory segment
 * that looks like a version folder (v1, v2, v10, ...) — those are frozen
 * snapshots of a previous major and aren't meant to be re-tested here.
 */

import { readFileSync, existsSync, readdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import yaml from "js-yaml";

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(SCRIPT_DIR, "../..");
const VERSION_DIR = /^v\d+$/i;

function defaultBaseUrl() {
  const testsConfig = yaml.load(
    readFileSync(join(SCRIPT_DIR, "config/tests.yaml"), "utf8"),
  );
  return testsConfig.baseUrl;
}

function walk(dir) {
  const results = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (VERSION_DIR.test(entry.name)) continue;
      results.push(...walk(join(dir, entry.name)));
    } else if (entry.name.endsWith(".md")) {
      results.push(join(dir, entry.name));
    }
  }
  return results;
}

function parseFrontmatter(content) {
  const m = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!m) return {};
  try {
    return yaml.load(m[1]) ?? {};
  } catch {
    return {};
  }
}

export function collectUrls(product, baseUrl) {
  const root = join(REPO_ROOT, "app/_how-tos", product);
  baseUrl = baseUrl || defaultBaseUrl();

  if (!existsSync(root)) {
    throw new Error(`No such directory: ${root}`);
  }

  const files = walk(root).sort();

  const urls = [];
  const skipped = [];

  for (const file of files) {
    const fm = parseFrontmatter(readFileSync(file, "utf8"));
    if (!fm.permalink) {
      skipped.push({ file, reason: "no permalink in frontmatter" });
      continue;
    }
    urls.push(`${baseUrl}${fm.permalink}`);
  }

  return { product, root, urls, skipped };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [, , product, baseUrlArg] = process.argv;
  if (!product) {
    console.error("Usage: collect-urls.mjs <product> [baseUrl]");
    process.exit(1);
  }

  try {
    const result = collectUrls(product, baseUrlArg);
    process.stdout.write(JSON.stringify(result, null, 2) + "\n");
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
