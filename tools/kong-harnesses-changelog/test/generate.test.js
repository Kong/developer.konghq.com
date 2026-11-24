import test from 'node:test';
import assert from 'node:assert/strict';
import { generateChangelog, renderChangelog, compareVersions } from '../generate.js';

const changelog = `# Changelog

## [0.19.0](https://github.com/Kong/kong-harnesses/compare/v0.18.0...v0.19.0) (2026-11-25)

### Features

* **login:** refresh the token before it expires ([#430](https://github.com/Kong/kong-harnesses/issues/430)) ([d706a0e](https://github.com/Kong/kong-harnesses/commit/d706a0e1234))

### Bug Fixes

* stop the profile prompt from looping ([#421](https://github.com/Kong/kong-harnesses/issues/421)) ([d5854a9](https://github.com/Kong/kong-harnesses/commit/d5854a9abcd))

### ⚠ BREAKING CHANGES

* the profile file format changes

## [0.18.0](https://github.com/Kong/kong-harnesses/compare/v0.17.0...v0.18.0) (2026-11-21)

### Features

* add the statusline command ([#400](https://github.com/Kong/kong-harnesses/issues/400)) ([a1b2c3d](https://github.com/Kong/kong-harnesses/commit/a1b2c3defff))

### Performance

* cache the token lookup ([b2c3d4e](https://github.com/Kong/kong-harnesses/commit/b2c3d4efff))

## [0.9.0](https://github.com/Kong/kong-harnesses/compare/v0.8.0...v0.9.0) (2026-11-06)

### Features

* a feature that predates the floor
`;

function entryFor(json, version, message) {
  return json[version]['kong-harnesses'].find((entry) => entry.message === message);
}

test('parses a version heading and keeps one entry per bullet under the component', () => {
  const json = generateChangelog(changelog);

  assert.deepEqual(Object.keys(json), ['0.19.0', '0.18.0']);
  assert.equal(json['0.18.0']['kong-harnesses'].length, 2);
  assert.equal(entryFor(json, '0.18.0', 'add the statusline command').type, 'feature');
});

test('maps the known sections to their type keys', () => {
  const json = generateChangelog(changelog);

  assert.equal(entryFor(json, '0.19.0', '**login:** refresh the token before it expires').type, 'feature');
  assert.equal(entryFor(json, '0.19.0', 'stop the profile prompt from looping').type, 'bugfix');
  assert.equal(entryFor(json, '0.19.0', 'the profile file format changes').type, 'Breaking Change');
  assert.equal(entryFor(json, '0.18.0', 'cache the token lookup').type, 'performance');
});

test('passes an unknown section through lowercased', () => {
  const markdown = `## [0.20.0](url) (2026-11-26)

### Dependencies

* bump a transitive package
`;

  const json = generateChangelog(markdown, { minVersion: '0.18.0' });

  assert.equal(entryFor(json, '0.20.0', 'bump a transitive package').type, 'dependencies');
});

test('strips a PR and commit reference chain from a bullet', () => {
  const json = generateChangelog(changelog);
  const entry = entryFor(json, '0.19.0', 'stop the profile prompt from looping');

  assert.equal(entry.message, 'stop the profile prompt from looping');
});

test('strips a commit-only reference chain from a bullet', () => {
  const json = generateChangelog(changelog);
  const entry = entryFor(json, '0.18.0', 'cache the token lookup');

  assert.equal(entry.message, 'cache the token lookup');
});

test('keeps the bold scope prefix of a message', () => {
  const json = generateChangelog(changelog);
  const entry = entryFor(json, '0.19.0', '**login:** refresh the token before it expires');

  assert.ok(entry.message.startsWith('**login:**'));
});

test('keeps only versions at or above the floor', () => {
  const json = generateChangelog(changelog, { minVersion: '0.18.0' });

  assert.deepEqual(Object.keys(json), ['0.19.0', '0.18.0']);
  assert.equal(json['0.9.0'], undefined);
});

test('compares versions by numeric segment, not lexically', () => {
  assert.equal(compareVersions('0.9.0', '0.18.0'), -1);
  assert.equal(compareVersions('0.18.0', '0.18.0'), 0);
  assert.equal(compareVersions('0.19.0', '0.18.0'), 1);
});

test('skips a prerelease heading', () => {
  const markdown = `## [0.20.0-rc.1](url) (2026-11-26)

### Features

* a prerelease feature

## [0.20.0](url) (2026-11-27)

### Features

* the stable feature
`;

  const json = generateChangelog(markdown, { minVersion: '0.18.0' });

  assert.deepEqual(Object.keys(json), ['0.20.0']);
});

test('collapses a duplicate message within a version and type', () => {
  const markdown = `## [0.20.0](url) (2026-11-26)

### Features

* the same message
* the same message
`;

  const json = generateChangelog(markdown, { minVersion: '0.18.0' });

  assert.equal(json['0.20.0']['kong-harnesses'].length, 1);
});

test('writes byte-identical output when run again on unchanged input', () => {
  assert.equal(renderChangelog(changelog), renderChangelog(changelog));
});

test('defaults the floor to 0.18.0', () => {
  const json = generateChangelog(changelog);

  assert.equal(json['0.9.0'], undefined);
  assert.deepEqual(Object.keys(json), ['0.19.0', '0.18.0']);
});
