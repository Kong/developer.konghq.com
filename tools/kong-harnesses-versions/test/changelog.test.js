import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { publicChangelog, syncChangelog } from '../fetch-changelog.js';

function exported(markdown, published = ['1.0.0']) {
  return publicChangelog(markdown, { published: new Set(published), highest: published.at(-1) });
}

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

test('publishes only the user-facing sections and entries, with no links', () => {
  assert.equal(
    exported(releasePleaseChangelog, ['0.17.1']),
    '## 0.17.1 (2026-11-19)\n\n' +
      '### ⚠ BREAKING CHANGES\n\n' +
      '* **profile:** run login again after the upgrade\n\n' +
      '### Bug Fixes\n\n' +
      '* **profile:** accept plain http for a gateway on loopback\n' +
      '* **docs:** follow the Claude Code settings {{ unchanged }} {% endraw %}\n',
  );
});

test('removes every link and keeps its text, except a reference number or commit hash', () => {
  const entries = [
    ['* fix([#1](https://github.com/kong/kong-harnesses/pull/1))', '* fix'],
    ['* see <https://github.com/Kong/kong-harnesses/issues/2>', '* see'],
    ['* see <HTTPS://GitHub.com/Kong/kong-harnesses/issues/2> now', '* see now'],
    ['* see https://github.com/Kong/kong-harnesses/issues/3 first', '* see first'],
    ['* see [the issue][issue]\n\n[issue]: https://github.com/Kong/kong-harnesses/issues/4', '* see the issue'],
    ['* see [the PR](https://github.com/Kong/kong-harnesses/pull/5 "title") first', '* see the PR first'],
    ["* see [the PR](https://github.com/Kong/kong-harnesses/pull/6 'title') first", '* see the PR first'],
    ['* see [the PR](https://github.com/Kong/kong-harnesses/pull/7 (title)) first', '* see the PR first'],
    ['* see [the PR](<https://github.com/Kong/kong-harnesses/pull/7\t>) first', '* see the PR first'],
    ['* fix (closes [#12](https://github.com/Kong/kong-harnesses/issues/12)) now', '* fix (closes) now'],
    ['* fix, see [c0ffee1](https://github.com/Kong/kong-harnesses/commit/c0ffee1) and [the guide](https://github.com/Kong/kong-harnesses/blob/main/docs/a.md)', '* fix, see and the guide'],
    ['* see [defaced](https://github.com/Kong/kong-harnesses/pull/1)', '* see defaced'],
    ['* see [x](git+https://github.com/Kong/kong-harnesses) first', '* see x first'],
    ['* see [x](https://github&#46;com/Kong/kong&#45;harnesses) first', '* see x first'],
    ['* use the value from ([the migration guide](https://github.com/Kong/kong-harnesses/blob/main/docs/m.md)).', '* use the value from (the migration guide).'],
    ['* see ![the diagram](https://raw.githubusercontent.com/Kong/kong-harnesses/main/a.png)', '* see the diagram'],
    ['* see [the plugin](https://github.com/Kong/kong-harnesses-plugin)', '* see the plugin'],
    // Only http and https addresses go. Any other address stays for the rendered check to refuse.
    ['* accept ssh://user@host targets', '* accept ssh://user@host targets'],
    ['* see (https://example.com/foo) ok', '* see ok'],
    ['* see https://example.com/a_(b) ok', '* see ok'],
    ['* released in [2026](https://example.com/release-year)', '* released in 2026'],
    ['* see ![alt][img]\n\n[img]: https://github.com/Kong/kong-harnesses/a.png', '* see alt'],
    ['* see [x][r]\n\n    [r]: https://github.com/Kong/kong-harnesses', '* see x'],
    ['* see [x][r]\n\n> [r]: https://github.com/Kong/kong-harnesses', '* see x'],
    ['* a ` [x](https://github.com/Kong/./kong-harnesses) `` d', '* a ` x `` d'],
  ];
  for (const [entry, expected] of entries) {
    assert.equal(exported(`## 1.0.0\n\n### Features\n\n${entry}\n`), `## 1.0.0\n\n### Features\n\n${expected}\n`);
  }
});

test('pairs code spans as kramdown does and leaves their text as it is', () => {
  assert.equal(
    exported('## 1.0.0\n\n### Features\n\n* run `` a ` <path> `` and see <path>\n'),
    '## 1.0.0\n\n### Features\n\n* run `` a ` <path> `` and see &lt;path>\n',
  );
});

test('drops an entry that held only a reference, and a section with no entry left', () => {
  assert.equal(
    exported(
      '## 1.0.0\n\n### Features\n\n* [#12](https://github.com/Kong/kong-harnesses/issues/12)\n* add\n\n### Bug Fixes\n\n* [#13](https://github.com/Kong/kong-harnesses/issues/13)\n',
    ),
    '## 1.0.0\n\n### Features\n\n* add\n',
  );
});

test('leaves out the repository tooling scopes, also with a nested scope', () => {
  assert.equal(
    exported('## 1.0.0\n\n### Bug Fixes\n\n* **deps(actions):** bump\n* **ci(release):** retry\n* **cli(help):** fix\n'),
    '## 1.0.0\n\n### Bug Fixes\n\n* **cli(help):** fix\n',
  );
});

test('leaves a code span as it is, for the rendered check to judge', () => {
  assert.equal(
    exported('## 1.0.0\n\n### Features\n\n* run `[a](https://github.com/Kong/kong-harnesses)` here\n'),
    '## 1.0.0\n\n### Features\n\n* run `[a](https://github.com/Kong/kong-harnesses)` here\n',
  );
});

test('reads the changelog on main up to the highest published release, not the newest one', async () => {
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
    return new Response('## [0.18.0](x) (2026-12-01)\n\n### Features\n\n* not out yet\n\n## 0.17.1\n\n### Features\n\n* add\n');
  };
  const outFile = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'changelog-')), 'changelog.json');

  assert.equal(await syncChangelog({ outFile, fetch, env: {} }), 'v0.17.1');
  assert.match(requested[1], /CHANGELOG\.md\?ref=main$/);
  assert.deepEqual(JSON.parse(fs.readFileSync(outFile, 'utf8')), { markdown: '## 0.17.1\n\n### Features\n\n* add\n' });
});

test('keeps an upgrade step whatever its scope', () => {
  assert.equal(
    exported('## 1.0.0\n\n### ⚠ BREAKING CHANGES\n\n* **deps:** install Go 1.30 first\n\n### Bug Fixes\n\n* **deps:** update Go\n'),
    '## 1.0.0\n\n### ⚠ BREAKING CHANGES\n\n* **deps:** install Go 1.30 first\n',
  );
});

test('escapes an HTML-like placeholder outside code spans, so Kramdown shows it', () => {
  assert.equal(
    exported('## 1.0.0\n\n### Features\n\n* run profile get <profile> or `profile get <profile>`\n'),
    '## 1.0.0\n\n### Features\n\n* run profile get &lt;profile> or `profile get <profile>`\n',
  );
});

test('publishes only the sections of published releases', () => {
  const changelog =
    'preamble\n\n' +
    '## 0.19.0\n\n### Features\n\n* later\n\n' +
    '## 0.18.0-rc.2\n\n### Features\n\n* not out\n\n' +
    '## [0.18.0-rc.1](x)\n\n### Features\n\n* candidate\n\n' +
    '## 0.17.1\n\n### Features\n\n* add\n';
  assert.equal(exported(changelog, ['0.18.0-rc.1', '0.17.1']), '## 0.17.1\n\n### Features\n\n* add\n');
  // 0.18.0 never shipped, so its candidate stays out even below a later release.
  assert.equal(
    exported(changelog, ['0.18.0-rc.1', '0.17.1', '0.19.0']),
    '## 0.19.0\n\n### Features\n\n* later\n\n## 0.17.1\n\n### Features\n\n* add\n',
  );
  assert.equal(
    exported('## 0.18.0\n\n### Features\n\n* final\n\n## [0.18.0-rc.1](x)\n\n### Features\n\n* candidate\n', ['0.18.0-rc.1', '0.18.0']),
    '## 0.18.0\n\n### Features\n\n* final\n\n## 0.18.0-rc.1\n\n### Features\n\n* candidate\n',
  );
  assert.throws(() => exported('## Unreleased\n\n### Features\n\n* secret\n'), /no version/);
});

test('refuses a changelog with no section for the highest published release', () => {
  assert.throws(() => exported('# Changelog\n'), /no section for 1\.0\.0/);
  assert.throws(() => exported('## 0.17.1\n\n### Features\n\n* add\n', ['0.17.1', '0.18.0']), /no section for 0\.18\.0/);
});

test('leaves out a release with no section for users, and refuses a changelog with nothing left', () => {
  const changelog = '## 1.0.0\n\n### Documentation\n\n* explain\n\n## 0.9.0\n\n### Features\n\n* add\n';
  assert.equal(exported(changelog, ['0.9.0', '1.0.0']), '## 0.9.0\n\n### Features\n\n* add\n');
  assert.throws(() => exported('## 1.0.0\n\n### Documentation\n\n* explain\n'), /no entries for users/);
});

test('keeps the spaces of an entry when it removes a link', () => {
  assert.equal(
    exported("## 1.0.0\n\n### Features\n\n* run `printf 'a  b'`  twice ([#1](https://github.com/Kong/kong-harnesses/pull/1))\n"),
    "## 1.0.0\n\n### Features\n\n* run `printf 'a  b'`  twice\n",
  );
});
