import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { publicChangelog, syncChangelog } from '../fetch-changelog.js';

const releasePleaseChangelog = `# Changelog

## [0.17.1](https://github.com/Kong/kong-harnesses/compare/v0.17.0...v0.17.1) (2026-11-19)


### ⚠ BREAKING CHANGES

* **profile:** run login again after the upgrade


### Bug Fixes

* **profile:** accept plain http for a gateway on loopback ([#417](https://github.com/Kong/kong-harnesses/issues/417)) ([802a984](https://github.com/Kong/kong-harnesses/commit/802a9848c49528cc52bb72365b6100ea68e30183))
* **ksai:** let autofix change the Go module files
* **deps:** update Go
* **docs:** follow the [Claude Code settings](https://code.claude.com/docs/en/settings) {{ unchanged }} {% endraw %}


### Documentation

* **release:** say how a release lists its upgrade steps

## [0.17.0](https://github.com/Kong/kong-harnesses/compare/v0.16.1...v0.17.0) (2026-11-18)


### Continuous Integration

* run the tests on Windows
`;

test('publishes only the user-facing sections and entries, without links into the internal repository', () => {
  assert.equal(
    publicChangelog(releasePleaseChangelog),
    '## 0.17.1 (2026-11-19)\n\n' +
      '### ⚠ BREAKING CHANGES\n\n' +
      '* **profile:** run login again after the upgrade\n\n' +
      '### Bug Fixes\n\n' +
      '* **profile:** accept plain http for a gateway on loopback\n' +
      '* **docs:** follow the [Claude Code settings](https://code.claude.com/docs/en/settings) {{ unchanged }} {% endraw %}\n',
  );
});

test('removes every form of link into the internal repository and keeps links to other repositories', () => {
  const entries = [
    ['* fix([#1](https://github.com/kong/kong-harnesses/pull/1))', '* fix'],
    ['* see <https://github.com/Kong/kong-harnesses/issues/2>', '* see'],
    ['* see https://github.com/Kong/kong-harnesses/issues/3 first', '* see first'],
    ['* see [the issue][issue]\n\n[issue]: https://github.com/Kong/kong-harnesses/issues/4', '* see the issue'],
    ['* see [the PR](https://github.com/Kong/kong-harnesses/pull/5 "title") first', '* see the PR first'],
    ["* see [the PR](https://github.com/Kong/kong-harnesses/pull/6 'title') first", '* see the PR first'],
    ['* see [the PR](https://github.com/Kong/kong-harnesses/pull/7 (title)) first', '* see the PR first'],
    ['* see [the plugin](https://github.com/Kong/kong-harnesses-plugin)', '* see [the plugin](https://github.com/Kong/kong-harnesses-plugin)'],
  ];
  for (const [entry, expected] of entries) {
    assert.equal(publicChangelog(`## 1.0.0\n\n### Features\n\n${entry}\n`), `## 1.0.0\n\n### Features\n\n${expected}\n`);
  }
});

test('refuses a changelog with a link into the internal repository that it cannot remove', () => {
  assert.throws(
    () => publicChangelog('## 1.0.0\n\n### Features\n\n* see `github.com/Kong/kong-harnesses`\n'),
    /internal kong-harnesses repository/,
  );
});

test('refuses a changelog with a link that removing an internal URL left broken', () => {
  assert.throws(() => publicChangelog("## 1.0.0\n\n### Features\n\n* see [the PR]( 'title')\n"), /left broken/);
});

test('reads the changelog at the highest published release, not the newest one', async () => {
  const requested = [];
  const fetch = async (url) => {
    requested.push(url);
    if (url.includes('/releases?')) {
      return Response.json([
        { tag_name: 'v0.16.2', draft: false, prerelease: false },
        { tag_name: 'v1.0.0-beta', draft: false, prerelease: false },
        { tag_name: 'v0.19.0', draft: true, prerelease: false },
        { tag_name: 'v0.18.0-rc.1', draft: false, prerelease: true },
        { tag_name: 'v0.17.1', draft: false, prerelease: false },
      ]);
    }
    return new Response('## 0.17.1\n\n### Features\n\n* add\n');
  };
  const outFile = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'changelog-')), 'changelog.json');

  assert.equal(await syncChangelog({ outFile, fetch, env: {} }), 'v0.17.1');
  assert.match(requested[1], /CHANGELOG\.md\?ref=v0\.17\.1$/);
  assert.deepEqual(JSON.parse(fs.readFileSync(outFile, 'utf8')), { markdown: '## 0.17.1\n\n### Features\n\n* add\n' });
});
