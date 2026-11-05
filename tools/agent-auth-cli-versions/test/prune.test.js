import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { pruneStalePages } from '../../lib/tool-versions.js';

const includePattern = /{%\s*include_cached\s+agent-auth-cli\/help\/([^\s%]+)\s*%}/g;

function setupDirs() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'agent-auth-cli-prune-'));
  const docsDir = path.join(root, 'docs');
  const includesDir = path.join(root, 'includes');
  fs.mkdirSync(docsDir, { recursive: true });
  fs.mkdirSync(path.join(includesDir, 'token'), { recursive: true });
  fs.writeFileSync(path.join(includesDir, 'token', 'index.md'), 'token help', 'utf8');
  return { root, docsDir, includesDir };
}

test('deletes a page whose include no longer exists', () => {
  const { docsDir, includesDir } = setupDirs();
  fs.writeFileSync(
    path.join(docsDir, 'doctor.md'),
    'Doctor page\n\n{% include_cached agent-auth-cli/help/doctor/index.md %}\n',
    'utf8',
  );

  const removed = pruneStalePages({ docsDir, includesDir, includePattern });

  assert.equal(removed, 1);
  assert.equal(fs.existsSync(path.join(docsDir, 'doctor.md')), false);
});

test('keeps a page whose includes all exist', () => {
  const { docsDir, includesDir } = setupDirs();
  fs.writeFileSync(
    path.join(docsDir, 'token.md'),
    'Token page\n\n{% include_cached agent-auth-cli/help/token/index.md %}\n',
    'utf8',
  );

  const removed = pruneStalePages({ docsDir, includesDir, includePattern });

  assert.equal(removed, 0);
  assert.equal(fs.existsSync(path.join(docsDir, 'token.md')), true);
});

test('keeps a page with no help includes at all', () => {
  const { docsDir, includesDir } = setupDirs();
  fs.writeFileSync(path.join(docsDir, 'notes.md'), 'Just some prose, no includes.', 'utf8');

  const removed = pruneStalePages({ docsDir, includesDir, includePattern });

  assert.equal(removed, 0);
  assert.equal(fs.existsSync(path.join(docsDir, 'notes.md')), true);
});

test('removes a directory left empty by pruning', () => {
  const { docsDir, includesDir } = setupDirs();
  fs.mkdirSync(path.join(docsDir, 'profile'), { recursive: true });
  fs.writeFileSync(
    path.join(docsDir, 'profile', 'create.md'),
    'Profile page\n\n{% include_cached agent-auth-cli/help/profile/create.md %}\n',
    'utf8',
  );

  const removed = pruneStalePages({ docsDir, includesDir, includePattern });

  assert.equal(removed, 1);
  assert.equal(fs.existsSync(path.join(docsDir, 'profile')), false);
});
