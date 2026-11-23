#!/usr/bin/env node
// Bootstraps the mechanical parts of a new product: 4 new files and 4 patches.
// The nav link and homepage card are NOT handled here (they depend on
// user-facing section names); the bootstrap-product skill handles those.
//
// Usage:
//   node tools/bootstrap-product --slug webhook-engine --name "Webhook Engine" \
//     --color green --tag webhook --works-on konnect,on-prem [--dry-run]

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const STYLESHEET = 'app/_assets/stylesheets/index.css';

// Valid colors are the --color-semantic-<name>-primary variables in the stylesheet.
const COLORS = [
  ...new Set(
    [...fs.readFileSync(path.join(root, STYLESHEET), 'utf8').matchAll(/--color-semantic-([a-z]+)-primary:/g)].map((m) => m[1])
  ),
];

const { values: args } = parseArgs({
  options: {
    slug: { type: 'string' },
    name: { type: 'string' },
    color: { type: 'string', default: 'green' },
    tag: { type: 'string' },
    'works-on': { type: 'string' },
    'dry-run': { type: 'boolean', default: false },
  },
});

const fail = (msg) => {
  console.error(`Error: ${msg}`);
  process.exit(1);
};

const { slug, name, color, tag } = args;
if (!slug || !name || !tag || !args['works-on']) {
  fail('--slug, --name, --tag, and --works-on are required');
}

// works_on values come from the frontmatter schema; pass one or both, comma-separated.
const WORKS_ON = JSON.parse(fs.readFileSync(path.join(root, 'app/_data/schemas/frontmatter/base.json'), 'utf8'))
  .properties.works_on.items.enum;
const worksOn = args['works-on'].split(',').map((v) => v.trim());
if (!worksOn.every((v) => WORKS_ON.includes(v))) {
  fail(`--works-on must be a comma-separated list of: ${WORKS_ON.join(', ')}`);
}
if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(slug)) {
  fail('--slug must be lowercase letters, digits, and hyphens');
}
if (!COLORS.includes(color)) {
  fail(`--color must be one of: ${COLORS.join(', ')}`);
}

const snake = slug.replaceAll('-', '_');
const camel = slug.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase());
const file = (p) => path.join(root, p);
const read = (p) => fs.readFileSync(file(p), 'utf8');

const tags = JSON.parse(read('app/_data/schemas/frontmatter/tags.json')).enum;
if (!tags.includes(tag)) {
  fail(`tag "${tag}" is not in app/_data/schemas/frontmatter/tags.json. Add it there first (alphabetical order).`);
}

// New files: skipped if they already exist.
const newFiles = {
  [`app/_data/products/${slug}.yml`]: `name: ${name}
icon: /_assets/icons/products/${slug}.svg
`,
  [`app/_assets/icons/products/${slug}.svg`]: `<svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6.9 1L2.5 6.6H5.4L5.1 11L9.5 5.4H6.6L6.9 1Z" fill="rgb(var(--color-${slug}-brand))"/>
</svg>
`,
  [`app/_indices/${slug}.yaml`]: `title: "{{site.${snake}}} Documentation"
description: Index containing all documentation for {{site.${snake}}}.
sections:
  - title: Overview
    items:
      - path: /${slug}/
`,
  [`app/_landing_pages/${slug}.yaml`]: `metadata:
  title: "{{site.${snake}}}"
  content_type: landing_page
  description: This page is an introduction to {{site.${snake}}}.
  products:
    - ${slug}
  works_on:
${worksOn.map((v) => `    - ${v}`).join('\n')}
  tags:
    - ${tag}
`,
};

// Patches: each returns the new file content, or null if already applied.
// An anchor that can't be found throws, so nothing is written.
const patches = {
  'jekyll.yml': (s) => {
    if (new RegExp(`^${snake}:`, 'm').test(s)) return null;
    const anchor = '\n\n# Company names';
    if (!s.includes(anchor)) throw new Error('anchor "# Company names" not found');
    return s.replace(anchor, `\n${snake}: ${name}${anchor}`);
  },

  'app/_data/schemas/frontmatter/base.json': (s) => {
    const re = /("products":\s*\{[\s\S]*?"enum":\s*\[)([^\]]*)(\])/;
    const m = s.match(re);
    if (!m) throw new Error('products enum not found');
    if (m[2].includes(`"${slug}"`)) return null;
    return s.replace(re, `$1$2, "${slug}"$3`);
  },

  'app/_assets/stylesheets/index.css': (s) => {
    if (s.includes(`--color-${slug}-brand`)) return null;
    // Anchor on the pattern, not a product name: a brand line pointing at a semantic
    // color, followed by its background line. New products go after the last pair.
    const pairRe =
      /^( *)--color-[a-z-]+-brand: var\(--color-semantic-[a-z]+-primary\);\n *--color-[a-z-]+-background: var\(--color-semantic-[a-z]+-secondary\);\n/gm;
    const pairs = [...s.matchAll(pairRe)];
    if (!pairs.length) throw new Error('no "--color-*-brand / -background" product color pairs found');
    const last = pairs.at(-1);
    const end = last.index + last[0].length;
    const i = last[1];
    return (
      s.slice(0, end) +
      `${i}--color-${slug}-brand: var(--color-semantic-${color}-primary);\n` +
      `${i}--color-${slug}-background: var(--color-semantic-${color}-secondary);\n` +
      s.slice(end)
    );
  },

  'app/_assets/javascripts/apps/components/ProductIcon.vue': (s) => {
    if (s.includes(`@/icons/products/${slug}.svg`)) return null;
    const importRe = /^import .* from '@\/icons\/products\/[^']+\.svg'$/gm;
    const imports = [...s.matchAll(importRe)];
    if (!imports.length) throw new Error('no product icon imports found');
    const last = imports.at(-1);
    const objAnchor = 'const productIcons = {\n';
    if (!s.includes(objAnchor)) throw new Error('anchor "const productIcons = {" not found');
    const end = last.index + last[0].length;
    return (
      s.slice(0, end) +
      `\nimport ${camel} from '@/icons/products/${slug}.svg'` +
      s.slice(end).replace(objAnchor, `${objAnchor}  '${slug}': ${camel},\n`)
    );
  },
};

// Preflight everything before writing anything.
const plan = [];
try {
  for (const [p, content] of Object.entries(newFiles)) {
    if (fs.existsSync(file(p))) {
      console.log(`skip   ${p} (already exists)`);
    } else {
      plan.push({ p, content, kind: 'create' });
    }
  }
  for (const [p, fn] of Object.entries(patches)) {
    let next;
    try {
      next = fn(read(p));
    } catch (e) {
      throw new Error(`${p}: ${e.message}`);
    }
    if (next === null) {
      console.log(`skip   ${p} (already patched)`);
    } else {
      plan.push({ p, content: next, kind: 'patch' });
    }
  }
} catch (e) {
  fail(`${e.message}\nNothing was written.`);
}

for (const { p, content, kind } of plan) {
  if (!args['dry-run']) {
    fs.mkdirSync(path.dirname(file(p)), { recursive: true });
    fs.writeFileSync(file(p), content);
  }
  console.log(`${args['dry-run'] ? 'would ' : ''}${kind === 'create' ? 'create' : 'patch '} ${p}`);
}

console.log(`
Still to do by hand (or via the bootstrap-product skill):
  - Add the nav link in app/_data/top_navigation.yml
  - Add the homepage card in app/_data/homepage.yml
  - Replace the placeholder icon: app/_assets/icons/products/${slug}.svg
  - Flesh out app/_landing_pages/${slug}.yaml and app/_indices/${slug}.yaml
`);
