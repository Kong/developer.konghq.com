# agent-auth-cli versions

Manually syncs the agent-auth-cli documentation on developer.konghq.com with the installed binary and its GitHub releases.

## Runbook

Run the sync in this order:

1. Upgrade the CLI first so the extracted help matches the latest release:

   ```sh
   brew upgrade agent-auth-cli
   ```

   The tap is `kong/agent-auth-cli`.

2. Update the release data from the private `Kong/agent-auth-cli` repo:

   ```sh
   GH_TOKEN=<token> node fetch-versions.js
   ```

   `GH_TOKEN` needs read access to the private repository. Without it the request fails and the script exits with a message naming the token requirement. `gh auth token` can supply the token for a logged-in `gh` session.

3. Update the help text from the installed binary:

   ```sh
   node extract-help.js
   ```

   This regenerates `app/_includes/agent-auth-cli/help/**` from scratch, then prunes reference pages under `app/agent-auth-cli/` whose help includes no longer exist.

Commit the generated `app/_data/tools/agent-auth-cli.yml` and `app/_includes/agent-auth-cli/help/**` files with any page changes from pruning.

## Tests

```sh
npm test
```

The tests cover the shared library in `tools/lib/tool-versions.js` and the agent-auth-cli help parser in `extract-help.js` without the binary or the network.
