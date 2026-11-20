import test from 'node:test';
import assert from 'node:assert/strict';
import { publicChangelog } from '../fetch-changelog.js';

const releasePleaseChangelog = `# Changelog

## [0.17.1](https://github.com/Kong/kong-harnesses/compare/v0.17.0...v0.17.1) (2026-11-19)


### ⚠ BREAKING CHANGES

* **profile:** run login again after the upgrade


### Bug Fixes

* **profile:** accept plain http for a gateway on loopback ([#417](https://github.com/Kong/kong-harnesses/issues/417)) ([802a984](https://github.com/Kong/kong-harnesses/commit/802a9848c49528cc52bb72365b6100ea68e30183))
* **ksai:** let autofix change the Go module files
* **docs:** follow the [Claude Code settings](https://code.claude.com/docs/en/settings) {{ unchanged }}


### Documentation

* **release:** say how a release lists its upgrade steps

## [0.17.0](https://github.com/Kong/kong-harnesses/compare/v0.16.1...v0.17.0) (2026-11-18)


### Continuous Integration

* run the tests on Windows
`;

test('publishes only the user-facing sections and entries, without links into the internal repository', () => {
  assert.equal(
    publicChangelog(releasePleaseChangelog),
    '<!--vale off-->\n{% raw %}\n' +
      '## 0.17.1 (2026-11-19)\n\n' +
      '### ⚠ BREAKING CHANGES\n\n' +
      '* **profile:** run login again after the upgrade\n\n' +
      '### Bug Fixes\n\n' +
      '* **profile:** accept plain http for a gateway on loopback\n' +
      '* **docs:** follow the [Claude Code settings](https://code.claude.com/docs/en/settings) {{ unchanged }}\n' +
      '{% endraw %}\n<!--vale on-->\n',
  );
});

test('matches the repository link whatever the owner case, and keeps links to other repositories', () => {
  assert.equal(
    publicChangelog(
      '## 1.0.0\n\n### Features\n\n' +
        '* fix ([#1](https://github.com/kong/kong-harnesses/pull/1))\n' +
        '* see [the plugin](https://github.com/Kong/kong-harnesses-plugin)\n',
    ),
    '<!--vale off-->\n{% raw %}\n## 1.0.0\n\n### Features\n\n' +
      '* fix\n' +
      '* see [the plugin](https://github.com/Kong/kong-harnesses-plugin)\n' +
      '{% endraw %}\n<!--vale on-->\n',
  );
});

test('refuses a changelog that would end the raw block early', () => {
  assert.throws(() => publicChangelog('## 1.0.0\n\n### Features\n\n* show {% endraw %}\n'), /endraw/);
});
