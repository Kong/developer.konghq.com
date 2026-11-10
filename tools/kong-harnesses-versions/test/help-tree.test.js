import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { writeHelpTree, escapeLiquid } from '../../lib/tool-versions.js';

function tempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'kong-harnesses-help-'));
}

test('removes the existing includes directory before writing', () => {
  const includesDir = path.join(tempDir(), 'includes');
  fs.mkdirSync(includesDir, { recursive: true });
  fs.writeFileSync(path.join(includesDir, 'stale.md'), 'old content', 'utf8');

  writeHelpTree({
    tree: [{ name: 'doctor', help: 'Check one profile end to end.' }],
    includesDir,
    fence: '```',
  });

  assert.equal(fs.existsSync(path.join(includesDir, 'stale.md')), false);
  assert.equal(fs.existsSync(path.join(includesDir, 'doctor', 'index.md')), true);
});

test('writes command nodes to index.md and subcommand leaves to named files', () => {
  const includesDir = path.join(tempDir(), 'includes');

  writeHelpTree({
    tree: [
      { name: 'doctor', help: 'Check one profile end to end.' },
      {
        name: 'profile',
        help: 'Manage public connection profiles.',
        subcommands: [
          { name: 'create', help: 'Build and install a profile.' },
          { name: 'delete', help: 'Remove one installed profile.' },
        ],
      },
    ],
    includesDir,
    fence: '```',
  });

  assert.equal(fs.existsSync(path.join(includesDir, 'doctor', 'index.md')), true);
  assert.equal(fs.existsSync(path.join(includesDir, 'profile', 'index.md')), true);
  assert.equal(fs.existsSync(path.join(includesDir, 'profile', 'create.md')), true);
  assert.equal(fs.existsSync(path.join(includesDir, 'profile', 'delete.md')), true);
});

test('writes nested subcommand directories and flat leaf subcommand files', () => {
  const includesDir = path.join(tempDir(), 'includes');

  writeHelpTree({
    tree: [
      {
        name: 'get',
        help: 'Display Kong resources.',
        subcommands: [
          {
            name: 'ai-gateway',
            help: 'AI Gateway commands.',
            subcommands: [
              { name: 'agents', help: 'Agent help.' },
              { name: 'routes', help: 'Route help.' },
            ],
          },
          { name: 'api', help: 'API help.' },
        ],
      },
    ],
    includesDir,
    fence: '```',
  });

  // A subcommand with children gets its own directory: index.md plus one file per child.
  assert.equal(fs.existsSync(path.join(includesDir, 'get', 'ai-gateway', 'index.md')), true);
  assert.equal(fs.existsSync(path.join(includesDir, 'get', 'ai-gateway', 'agents.md')), true);
  assert.equal(fs.existsSync(path.join(includesDir, 'get', 'ai-gateway', 'routes.md')), true);

  // A leaf subcommand still gets a flat named file.
  assert.equal(fs.existsSync(path.join(includesDir, 'get', 'api.md')), true);

  // The nesting rule leaves no misplaced files behind.
  assert.equal(fs.existsSync(path.join(includesDir, 'get', 'ai-gateway.md')), false);
  assert.equal(fs.existsSync(path.join(includesDir, 'get', 'ai-gateway', 'agents', 'index.md')), false);
});

test('wraps help content in the given fence', () => {
  const includesDir = path.join(tempDir(), 'includes');

  writeHelpTree({
    tree: [{ name: 'doctor', help: 'Check one profile end to end.' }],
    includesDir,
    fence: '```ansi',
  });

  assert.equal(
    fs.readFileSync(path.join(includesDir, 'doctor', 'index.md'), 'utf8'),
    '```ansi\nCheck one profile end to end.\n```',
  );
});

test('escapes ${{ ... }} sequences into raw wrapping', () => {
  const includesDir = path.join(tempDir(), 'includes');

  writeHelpTree({
    tree: [{ name: 'token', help: 'Print ${{ env.PROFILE_NAME }} for the profile.' }],
    includesDir,
    fence: '```',
  });

  assert.equal(
    fs.readFileSync(path.join(includesDir, 'token', 'index.md'), 'utf8'),
    '```\nPrint {% raw %}${{ env.PROFILE_NAME }}{% endraw %} for the profile.\n```',
  );
});

test('escapeLiquid wraps each interpolation sequence separately', () => {
  assert.equal(
    escapeLiquid('first ${{ one }} then ${{ two }}'),
    'first {% raw %}${{ one }}{% endraw %} then {% raw %}${{ two }}{% endraw %}',
  );
});
