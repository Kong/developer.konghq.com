#!/usr/bin/env node
/**
 * Collect the how-to source files for one product.
 *
 * Imported by resolve-urls.js for the `--product` mode of
 * generate-instructions-files.js. Can also be run directly, for manual checks:
 *
 * Usage:  node collect-how-to-files.mjs <product>
 * Output: JSON { product, root, files: [...] }, where `root` is the scanned
 *         folder and `files` are the how-to paths found under it.
 *
 * Scope: app/_how-tos/<product>/**\/*.md, excluding any directory segment
 * that looks like a version folder (v1, v2, v10, ...). Those are frozen
 * snapshots of a previous major, and aren't meant to be re-tested here.
 *
 * This decides scope only. Whether a collected file is testable is decided by
 * testeableUrlsFromFiles, which also builds the URL and writes the manifest.
 */

import { existsSync, readdirSync } from "fs";
import { join, dirname, relative } from "path";
import { fileURLToPath } from "url";

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(SCRIPT_DIR, "../..");
const VERSION_DIR = /^v\d+$/i;

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

export function collectHowToFiles(product, { repoRoot = REPO_ROOT } = {}) {
  const root = join(repoRoot, "app/_how-tos", product);

  if (!existsSync(root)) {
    throw new Error(`No such directory: ${root}`);
  }

  // The filter derives URLs and log paths from the "../../app/_how-tos/" prefix
  // the full scan produces, so hand it paths in that same form.
  const files = walk(root)
    .map((file) => join("../..", relative(repoRoot, file)))
    .sort();

  return { product, root, files };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [, , product] = process.argv;
  if (!product) {
    console.error("Usage: node collect-how-to-files.mjs <product>");
    process.exit(1);
  }

  try {
    const result = collectHowToFiles(product);
    process.stdout.write(JSON.stringify(result, null, 2) + "\n");
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
