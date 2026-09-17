# Deploying a test gateway, env vars, and CLI tooling gaps

## Deploy command

Run from the repo root (`get.konghq.com`), with Docker running:

```bash
DEBUG=true KONNECT_DOMAIN=konghq.tech sh ai/index \
  -i <image-name> \
  -t <image-tag> \
  -k $KONNECT_TOKEN \
  -a <gateway-name> \
  --deck-output
```

What each piece does, traced through `ai/index` and the sourced `quickstart` script:

- `DEBUG=true` makes `ai/index` copy the **local** `./quickstart` file instead of downloading it from get.konghq.com. This means it requires `./quickstart` to exist in the repo root — confirm with `ls quickstart` before you rely on it. Without `DEBUG=true`, it downloads the *published* quickstart, which won't have unreleased fixes.
- `KONNECT_DOMAIN=konghq.tech` is read by `ai/index`'s own overridden functions (`fetch_konnect_cp`, `create_konnect_cp`, `deploy_konnect_certs`, `delete_konnect_cp`) — these hit `https://<region>.api.${KONNECT_DOMAIN}/v1/ai-gateways`, i.e. the *new* AI Gateway 2.0 API surface, not the older `/v2/control-planes` API that plain `quickstart` uses by default.
- `-i` / `-t` set the Docker image name/tag for the AI Gateway data-plane container (`kong-ai-gateway-dev:ai-2.0.0-rc.3`-style).
- `-k $KONNECT_TOKEN` supplies the Konnect PAT and flips the script into Konnect mode (vs. a local-only Docker deploy).
- `-a <gateway-name>` sets `APP_NAME`, which `ai/index`'s `customize_defaults` hook uses to set the default control-plane/AI-Gateway name (unless `-n` is also passed). **This is the literal name that gets created** — don't pass a doc's placeholder token (like `CP_NAME`) verbatim; substitute a real name first, and confirm with the user if a doc leaves this ambiguous.
- `--deck-output` sets `IS_WITH_DECK=true` in the underlying `quickstart` script.

### Confirm an image tag exists before deploying with it

If the user names a specific build (an `rc.N`, a `pr-<number>` build, a commit-hash tag, etc.), check it actually exists before running the deploy — a typo'd or already-pruned tag fails loudly mid-deploy, after you've already torn down whatever was running. Docker Hub's public tag-list API works without auth for these images:

```bash
curl -s "https://hub.docker.com/v2/repositories/kong/kong-ai-gateway-dev/tags?page_size=100&name=<partial-tag>" | jq -r '.count, (.results[] | "\(.name)\t\(.tag_last_pushed)")'
```

This is also the fastest way to answer "is there a newer build than the one I'm testing" — filter by name and sort by push date, rather than guessing at a version number. It's a real signal too: a data-plane image's push date can lag well behind the control plane's own rollout (the CP is a continuously-deployed SaaS service; the DP image follows a slower, separate release cadence), which is a plausible explanation any time the CP-stored config looks correct but the DP behaves like it doesn't understand part of it.

### The name-pattern gotcha

The Konnect API validates the AI Gateway `name` against `^[0-9a-z-]*$` — **lowercase letters, digits, and hyphens only**. No underscores, no uppercase. If a chosen name violates this, `create_konnect_cp` fails with a `400` like:

```json
{"detail":"Bad Request: name: must match pattern '^[0-9a-z-]*$'","field":"name"}
```

Check the tail of `/tmp/kong/kong-ai-quickstart/ai-gateway.log` for the raw API response if a deploy fails at "Unable to create control plane" — the log has the actual request/response bodies, which the terminal summary doesn't show.

### What the deploy does, and its blast radius

Before creating, the script **deletes any existing AI Gateway with the same name** (via `delete_konnect_cp`). If nothing exists with that name, it's a no-op (logged, not an error). This means picking a name that collides with someone else's live test gateway will destroy it — always confirm the name with the user if there's any ambiguity about whether it's already in use.

On success, it prints:

```bash
export AI_GATEWAY_ID="<uuid>"
export DECK_KONNECT_TOKEN=$KONNECT_TOKEN
export DECK_KONNECT_CONTROL_PLANE_NAME=<gateway-name>
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com   # <-- WRONG DOMAIN, see below
export KONNECT_PROXY_URL='http://localhost:8000'
```

It also writes `/tmp/kong/<app-name>/kong.env` with local proxy port variables (`KONG_PROXY`, `KONG_ADMIN_API`, etc.) — source that too.

## The `.tech` domain fix (do this every time)

The printed `KONNECT_CONTROL_PLANE_URL` always says `konghq.com`, because that line in `quickstart` (`echo "export KONNECT_CONTROL_PLANE_URL=https://$KONNECT_REGION.api.konghq.com"`) hardcodes the production domain and never reads `$KONNECT_DOMAIN`. This is a known bug, low priority to fix in the script itself — just always override it manually after deploying:

```bash
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.tech
```

Every API call you make by hand while testing must target this `.tech` URL — the gateway you just created lives there, not on `.com`. If a `curl`, `kongctl`, or `deck` command against the gateway comes back "not found," check this before assuming something's broken.

Save the corrected set to a scratchpad file so it survives across separate Bash tool calls (shell state doesn't persist between calls):

```bash
cat > /path/to/scratchpad/aigw-env.sh <<EOF
export AI_GATEWAY_ID="<uuid>"
export DECK_KONNECT_TOKEN=\$KONNECT_TOKEN
export DECK_KONNECT_CONTROL_PLANE_NAME=<gateway-name>
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.tech
export KONNECT_PROXY_URL='http://localhost:8000'
EOF
```

## GA/production local gateways vs prerelease `.tech` gateways

Not every local AI Gateway you're handed is the prerelease `ai/index` workflow above. A `docker ps` container running a **stable, non-`rc.` image tag** (e.g. `kong/kong-ai-gateway:2.0.3`, versus `kong-ai-gateway-dev:ai-2.0.0-rc.3`) may well be a real GA gateway hooked up to **production** Konnect (`us.api.konghq.com`), created by the generic `quickstart` script rather than the `ai/index` prerelease deploy path. Check before assuming `.tech`:

```bash
curl -s "https://us.api.konghq.com/v1/ai-gateways/${AI_GATEWAY_ID}" \
  -H "Authorization: Bearer ${KONNECT_TOKEN}" -H "Accept: application/json"
```

A `200` with a real `min_runtime_version` here means it's genuinely GA/production — don't force the `.tech` domain override onto it, and don't be surprised `KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com` this time is actually correct rather than the usual bug. This kind of local setup is arguably a *better* test environment for a published (non-prerelease-flagged) how-to, since it's exactly what a real reader would have.

## Vectordb-backed policies need the real vector database, not just "a" database

Testing a policy with a `vectordb` block (AI RAG Injector, AI Semantic Cache, AI Semantic Prompt/Response Guard) against Redis requires **Redis Stack** (`redis/redis-stack-server`), not plain `redis-server`/Homebrew's `redis-server`. Plain Redis is missing the RediSearch module, and the policy fails to create its vector index with:

```
Failed to load the 'redis' vector database driver: failed to initialize vector database strategy: failed to create index: ERR unknown command 'FT.CREATE', with args beginning with: ...
```

This is easy to miss: with `stop_on_failure: false` (the schema default for at least AI RAG Injector), the request still returns a normal `200` — it just silently skips retrieval/grounding instead of erroring. Don't conclude "it works" from a `200` alone on one of these policies; grep the data-plane logs for the policy's own warn/error lines (`docker logs <container> | grep -i <policy-name-or-lua-file>`), and independently confirm the vector index actually exists and is populated (`redis-cli FT.INFO idx:vss_kong_rag_injector`, or the pgvector equivalent) before treating the test as a pass.

**A vectordb driver's failed-init state is cached per Kong worker.** If you fix the backend after a failed first request (e.g., swap plain Redis for Redis Stack), a new request on the same already-warm worker won't retry — restart the data-plane container to force a clean re-init and confirm the fix actually took.

## Tooling: what can and can't introspect an AI Gateway 2.0 resource

- **Stable `kongctl` (e.g. Homebrew-installed) does not support `ai-gateways`.** `kongctl dump declarative --resources ai-gateways` on a stable build fails with `unsupported resource type: ai-gateways`.
- **A prerelease `kongctl` build does support it.** Install one with:
  ```bash
  curl -fsSL https://get.konghq.com/kongctl | sh -s -- --version <prerelease-version>
  ```
  This installs to `~/.local/bin/kongctl`. Then:
  ```bash
  kongctl dump declarative --resources ai-gateways --include-child-resources \
    --pat "$KONNECT_TOKEN" --base-url https://us.api.konghq.tech \
    [--filter-name <name>] --output-file <path>
  ```
  Note `-o/--output` is **not** supported for `dump` — you must use `--output-file`, and omitting it prints to stdout. `--filter-name` (supports `*` wildcards) scopes the dump to one gateway instead of the whole org — use it whenever you're producing a dump for someone else to look at, so you're not handing over other engineers' test resources.

- **Watch for PATH shadowing.** If a Homebrew-managed `kongctl` is also on `PATH` ahead of `~/.local/bin`, it silently wins and you'll be back to "unsupported resource type" even with the prerelease build installed. Check with `which -a kongctl` and `echo $PATH`. A shell **alias does not reliably fix this** in hook-based or command-proxying environments (e.g. an `rtk`-style command rewriter) — the proxy spawns the subprocess via its own `PATH` lookup, which is invisible to shell aliases entirely. The real fix is reordering `PATH` in the shell rc file (`.zshrc`) so `~/.local/bin` comes before `/opt/homebrew/bin`, then `source ~/.zshrc`. Remember non-interactive shells (including most automated tool-runners) don't auto-source `.zshrc` — you may need to `source ~/.zshrc` explicitly at the top of each command block for the rest of the session too.

- **`deck` (decK) has no concept of `/v1/ai-gateways` either**, as of v1.50.0. `deck gateway dump --konnect-control-plane-name <name> ...` looks up the classic `/v2/control-planes` resource and fails with `Error: control plane not found: <name>` for anything that's only an AI Gateway. Don't spend time trying to make decK work here — use the prerelease `kongctl` or raw API calls instead.

- **The classic Kong Admin API (port 8001, etc.) is not exposed on the AI Gateway 2.0 data-plane image.** A `curl` to it connects successfully at the TCP level but gets an empty reply — no HTTP response at all. This is expected: AIGW 2.0 is a fully Konnect-managed control-plane model, not the classic Kong Route/Service Admin API. Don't chase this as a bug; it's by design. If you need to inspect what config the data plane actually has, use `GET /v1/ai-gateways/{id}/nodes` and the prerelease `kongctl` dump instead (see `spec-and-debugging.md`).
