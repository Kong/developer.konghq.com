# Harness operations

Test harness: `~/ai-gateway-test-harness`. Read its `CLAUDE.md` and `TEST_HARNESS.md`, and use the `aigw-doc-testing` skill alongside this file.

## Setup
- Credentials: `source ~/ai-gateway-test-harness/.env` (gives `KONGCTL_DEFAULT_KONNECT_PAT`, `KONNECT_CONTROL_PLANE_ID`, upstream keys). The shell's `KONNECT_TOKEN` may be invalid. Never print the PAT or provider keys, and never write them into files.
- Save env helpers (`B`, `H`, `api`, `pol`, `req`) to a scratchpad `env.sh` and `source` it per call.
- zsh gotcha: `${!var}` and inline loops break. Write each test as a bash script file, or use `bash -c`.
- A foreground call times out at 120 s. Use `timeout 115 bash script.sh`, or background the run and poll with `timeout 115 bash -c 'until grep -q DONE out; do sleep 5; done'`. Real-provider requests are slow, so keep samples small for the real path.
- Wait 30-45 s after every policy, model, agent or MCP change before testing. A matching `config_version` does not prove the change is live.
- Print counts per outcome class (for example `C` canary, `P` primary, `X` error).
- Use a resource name prefix (`rt-`) on everything you create. Do not touch resources you did not create. Do not attach policies to other people's models.

## Data plane
- The test data plane is the `kong-ai-quickstart-gateway` container (`docker ps -a`; `docker start` it if stopped). It runs as user `kong`.
- Confirm it belongs to the gateway and is synced: `GET .../nodes` shows `STATE_IN_SYNC`. If the proxy returns 404 for every model route, restart the container.
- Never run `docker exec -u root ... kong reload` or any other Kong command as root. It rewrites `/usr/local/kong/.kong_env` as root, and the container then fails to start with "could not load config file ... Permission denied". Recovery: copy the file out with `docker cp`, rewrite it with uid/gid 1001 and mode 0640 through a tar stream (do not write it to disk, it holds secrets), and `docker cp -` it back.
- To trust a test certificate, back up `/etc/ssl/certs/ca-certificates.crt` to `/tmp/ca.bak`, append the PEM, and `docker restart` the container. The data plane regenerates `.ca_combined` on start. Restore the bundle and restart again when finished.
- Upstream TLS verification is on. A redirected request keeps the provider's TLS server name, so the test cert needs SANs for the provider hostname (for example `api.openai.com`) and `host.docker.internal`.

## Mock upstream
Use it for any policy that redirects or alters upstream traffic.
- A small TLS server on the host (for example port 9443). It echoes the request path and `Host` header and supports `stream: true` with an SSE reply. The container reaches it as `host.docker.internal`.
- Start with `python3 -I mock.py` from the scratchpad, stop with `pkill -f mock.py`, and check `lsof -i :<port>` after restarting. A stale mock holding the port makes a new cert silently not take effect.
- Return a marker string that differs from the real upstream, so every request classifies as primary, canary or error.

## Safety
- A global policy affects every entity on a shared gateway. Gate it behind an opt-in condition (for example `percentage: 0` plus an override header, or a `condition`) and remove it as soon as the test ends.
- Run a control for every scope with no policy attached before attaching it.
- Check the policy's scope limits in `scopes.json` and the plugin schema before attaching to a scope. An unsupported scope wedged the data plane's sync once.
- Cleanup order: detach the policy from entities (or delete the entities), then delete the policy (deleting a referenced policy returns `400`), then consumers, groups and auth strategies. List each collection afterward and confirm nothing with your prefix remains. Also stop the mock, delete key files and the test cert, and restore the CA bundle.

## Run state file
Keep `scratchpad/migration-state.md` during live testing: resources created (type, name, UUID), CA bundle modified (yes/no), mock running (yes/no), step reached. Update it after each create. If a run is interrupted, use it to clean up.
