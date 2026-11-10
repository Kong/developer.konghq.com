# kongctl versions

Keeps the kongctl documentation on developer.konghq.com in sync with the installed binary and the public `Kong/kongctl` GitHub releases.

The daily [`sync-kongctl`](../../.github/workflows/sync-kongctl.yml) workflow runs both scripts: it regenerates the help includes and prunes stale pages, then refreshes the release data. A local `GH_TOKEN` is only needed for the internal `Kong/kong-harnesses` repo, not for `Kong/kongctl`.

## How to run the sync

1. Update the help text from the installed binary:

   ```sh
   node extract-help.js
   ```

   This regenerates `app/_includes/kongctl/help/**` from scratch with usage-scoped help (the section from `Usage:` up to `Global Flags:`), then prunes reference pages under `app/kongctl/` whose help includes no longer exist.

2. Update the release data:

   ```sh
   node fetch-versions.js
   ```

   This rewrites `app/_data/tools/kongctl.yml` with one release entry per major.minor series, marking the newest series `latest`. The site only consumes the `latest` entry.

Both scripts are thin entry points over the shared library in `tools/lib/tool-versions.js`, which `tools/kong-harnesses-versions` uses too.

## Tests

```sh
npm test
```

The tests in `test/` cover the shared command-tree builder (depth-2 recursion, usage scoping, skipping hidden and deprecated commands) with a mocked `exec`, without the binary or the network.

## Equivalence proof for sync-logic changes

When changing the sync logic (the entry points or `tools/lib/tool-versions.js`), prove the generated output is unchanged by comparing old-script output to new-script output from the same installed binary — never either against the committed files, because the local binary may be a dev build that drifts from the committed help:

1. **Before the change**, run the current scripts and snapshot their output outside the repo:

   ```sh
   node extract-help.js && node fetch-versions.js
   mkdir -p /tmp/kongctl-sync-snapshot
   cp -R ../../app/_includes/kongctl/help /tmp/kongctl-sync-snapshot/help
   cp ../../app/_data/tools/kongctl.yml /tmp/kongctl-sync-snapshot/kongctl.yml
   git restore ../../app/_includes/kongctl/help ../../app/_data/tools/kongctl.yml ../../app/kongctl
   ```

   Run both fetches back-to-back so the GitHub API can't move between them.

2. **After the change**, run the new scripts and compare:

   ```sh
   node extract-help.js && node fetch-versions.js
   diff -r /tmp/kongctl-sync-snapshot/help ../../app/_includes/kongctl/help
   diff /tmp/kongctl-sync-snapshot/kongctl.yml ../../app/_data/tools/kongctl.yml
   ```

   The help includes must be byte-identical. The yml may differ only in extra older series rows (`syncReleases` keeps up to 10 series); the `latest` entry must be unchanged.

3. `git restore` the generated files so the commit contains only the code change.

The node:test suite locks the structure (three-level nesting, usage-scoped help, ansi fences) so the equivalence is regression-checked in CI, not just proven once.
