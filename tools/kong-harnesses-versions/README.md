# kong-harnesses versions

Keeps the kong-harnesses documentation on developer.konghq.com in sync with the installed binary and its GitHub releases.

The [`sync-kong-harnesses`](../../.github/workflows/sync-kong-harnesses.yml) workflow runs both scripts on a daily schedule and on manual dispatch: it regenerates the help includes, then refreshes the release data from the internal `Kong/kong-harnesses` releases, and opens a pull request. GitHub runs a schedule only from the default branch, so the same workflow file is also on `main`. Its `base` job sends the sync to `release/kong-harnesses` while that branch exists, else to the default branch. A manual run can name the branch in `dev_site_base_branch`.

The `kong-harnesses-versions` job downloads the newest release for Linux, and checks the archive against `SHA256SUMS.txt` and against the build provenance in `kong-harnesses_<tag>.sigstore.json`, as `scripts/install-release.sh` in `Kong/kong-harnesses` does. The repository is internal, so GitHub's private Sigstore instance signs that provenance, and `gh attestation verify` checks it. The job reads the releases with a Kong docs GitHub App token (`GH_APP_KONG_DOCS_ID`) that can only read `Kong/kong-harnesses`, and also sets it as `GH_TOKEN` for `fetch-versions.js`. It opens the pull request with a second token that can only write to this repository.

The manual runbook below does the same work by hand, and stays the way to sync from a local binary.

## How to run the sync

Run the steps in this order:

1. Upgrade the CLI first so the extracted help matches the latest release:

   ```sh
   brew upgrade kong-harnesses
   ```

   The tap is `kong/kong-harnesses`.

2. Update the release data from the internal `Kong/kong-harnesses` repo:

   ```sh
   GH_TOKEN=<token> node fetch-versions.js
   ```

   `GH_TOKEN` needs read access to the internal repository. Without it the request fails and the script exits with a message naming the token requirement. `gh auth token` can supply the token for a logged-in `gh` session.

3. Update the help text from the installed binary:

   ```sh
   node extract-help.js
   ```

   This regenerates `app/_includes/kong-harnesses/help/**` from scratch, then prunes reference pages under `app/kong-harnesses/` whose help includes no longer exist.

Commit the generated `app/_data/tools/kong-harnesses.yml` and `app/_includes/kong-harnesses/help/**` files with any page changes from pruning.

## Tests

```sh
npm test
```

The tests cover the shared library in `tools/lib/tool-versions.js` and the kong-harnesses help parser in `extract-help.js` without the binary or the network.
