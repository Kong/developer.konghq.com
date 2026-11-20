# kong-harnesses versions

Keeps the kong-harnesses documentation on developer.konghq.com in sync with the installed binary and its GitHub releases.

The [`sync-kong-harnesses`](../../.github/workflows/sync-kong-harnesses.yml) workflow runs both scripts on a daily schedule and on manual dispatch: it regenerates the help includes, then refreshes the release data and the changelog from the `Kong/kong-harnesses` releases, and opens a pull request. GitHub runs a schedule only from the default branch, so the same workflow file is also on `main`. Its `base` job sends the sync to `release/kong-harnesses` while that branch exists, else to the default branch. A manual run can name the branch in `dev_site_base_branch`, which must have the scripts in this folder. Runs for the same base branch wait for each other. Each base branch gets its own sync pull request, from the branch `sync-kong-harnesses/releases/<base branch>`. No earlier workflow used a branch named `sync-kong-harnesses` or `sync-kong-harnesses/releases`, which would block that name.

The `kong-harnesses-versions` job downloads the newest release for Linux, and checks the archive against `SHA256SUMS.txt` and against the build provenance in `kong-harnesses_<tag>.sigstore.json`, as `scripts/install-release.sh` in `Kong/kong-harnesses` does. `gh attestation verify` checks that provenance. The job reads the releases with a Kong docs GitHub App token (`GH_APP_KONG_DOCS_ID`), and also sets it as `GH_TOKEN` for `fetch-versions.js`. The install step and `fetch-versions.js` both read every page of releases and take only `vX.Y.Z` tags of releases that aren't drafts or pre-releases, and the job fails when the release data names another latest release than the binary it checked. It opens the pull request with a second GitHub App token.

The manual runbook below does the same work by hand, and stays the way to sync from a local binary.

## How to run the sync

Run the steps in this order:

1. Upgrade the CLI first so the extracted help matches the latest release:

   ```sh
   brew upgrade kong-harnesses
   ```

   The tap is `kong/kong-harnesses`.

2. Update the release data from the `Kong/kong-harnesses` releases:

   ```sh
   GH_TOKEN=<token> node fetch-versions.js
   ```

   Set `GH_TOKEN` to a GitHub token. Without it the script sends the request with no token, and when the request fails it exits with a message that asks for `GH_TOKEN`. `gh auth token` can supply the token for a logged-in `gh` session.

3. Update the help text from the installed binary:

   ```sh
   node extract-help.js
   ```

   This regenerates `app/_includes/kong-harnesses/help/**` from scratch, then prunes reference pages under `app/kong-harnesses/` whose help includes no longer exist.

4. Update the changelog from `CHANGELOG.md` on `main`, up to the highest published release, which `fetch-versions.js` also marks as the latest:

   ```sh
   GH_TOKEN=<token> node fetch-changelog.js
   ```

   This writes `app/_data/kong-harnesses/changelog.json`, which the [changelog page](../../app/kong-harnesses/changelog.md) prints as a Liquid variable. It reads `main`, not the release tag, so a correction to an earlier entry reaches the page, and it leaves out a release that release-please wrote but that is not published yet. Jekyll does not parse a variable as a template, so Liquid syntax in a commit subject stays text. Vale checks only Markdown pages, so the commit subjects in this file do not fail the spelling check. The repository is internal, so the script removes every link into it, as the Mesh changelog does, and stops with an error when it finds a link that it cannot remove. It keeps only the sections for users (**⚠ BREAKING CHANGES**, **Features**, **Bug Fixes** and **Performance**), so the steps an upgrade needs stay under **⚠ BREAKING CHANGES**. It drops every other section, the changes to the repository's own tooling, reviews and dependency pins (the `ci`, `ksai`, `threat-model` and `deps` scopes) outside **⚠ BREAKING CHANGES**, and a release with nothing left.

Commit the generated `app/_data/tools/kong-harnesses.yml`, `app/_includes/kong-harnesses/help/**` and `app/_data/kong-harnesses/changelog.json` files with any page changes from pruning.

## Tests

```sh
npm test
```

The tests cover the shared library in `tools/lib/tool-versions.js`, the kong-harnesses help parser in `extract-help.js` and the changelog filter in `fetch-changelog.js` without the binary or the network.
