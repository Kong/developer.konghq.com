# Navigating the AIGW spec, and a debugging playbook

## Navigating a large OpenAPI spec efficiently

The AIGW 2.0 spec is typically 10k+ lines — too big for a single `Read`. Don't try to read it front-to-back.

- Read the first ~30-80 lines first (`info`, `servers`, start of `paths`) to confirm version and get oriented.
- List every path with a quick search rather than scrolling:
  ```bash
  rg -n "^  ('/|/)" <spec-file>
  ```
  (both quoted `'/ai-gateways/{gatewayId}':` and bare `/ai-gateways:` style keys appear in these specs, so match both forms.)
- To find a specific schema, search for its exact name followed by a colon (schema names are unique block headers under `components/schemas`):
  ```bash
  rg -n "CreateAIGatewayAgentRequest:" <spec-file>
  ```
  then `Read` with `offset`/`limit` starting at that line.
- Common AIGW 2.0 surface as of the version tested here: gateway CRUD, `nodes`, `expected-config-version`, `debug-cp-output`, `data-plane-certificates`, `models`, `model-providers`, `agents` (`type: a2a | http`), `consumers`, `consumer-groups`, `credentials`, `identity`, `vaults`, `config-stores` (+ secrets), `mcp-servers`, `policies`. Treat this list as a starting map, not gospel — re-derive it from the actual spec file each time, since AIGW 2.0 is actively evolving.
- `debug-cp-output` explicitly requires "a privileged internal service-client token" per its own spec description — a regular PAT gets a `401`. Don't spend time trying to auth into it; it's not meant for this workflow.

## Cross-checking a doc's request body against the spec

Before running a `POST`/`PUT` from a how-to doc, find the matching `Create*Request` (or `Update*Request`) schema and check:

- **Property names** match exactly (including nesting, e.g. `config.route.paths` vs a flatter shape).
- **`additionalProperties: false`** blocks — if present on an object, every key the doc sends must be one of the schema's declared properties, or the request will likely reject.
- **`required`** fields are all present in the doc's example.
- **`enum`** values (e.g. an agent `type` of `a2a` vs `http`) are valid.
- **Identifier patterns** — e.g. an `AIGatewayEntityIdentifier` field is commonly restricted to something like `^[A-Za-z0-9._-]{1,256}$`, while the top-level gateway `name` itself has been seen restricted to the stricter `^[0-9a-z-]*$` (lowercase + hyphens only, no underscores or dots) — these two patterns are *not* the same, so don't assume one implies the other. Re-check the actual pattern in the spec rather than assuming from memory.

Catching a mismatch this way, before running anything, is much cheaper than debugging a `400` after the fact — and it separates "the doc is wrong" from "the gateway has a real bug" before you've spent time on the wrong hypothesis.

## Before running a `{% entity_examples %}` block written for `kongctl`

The Jekyll tag renders the block's raw YAML body almost verbatim into `kongctl apply -f - << 'EOF' ... EOF` — it does **not** expect (and will mis-render) a top-level `entities:` wrapper key. Resource-type keys (`ai_gateway_model_providers`, `ai_gateway_policies`, `ai_gateway_models`, etc.) must sit flat at the top level of the block, exactly like a real kongctl declarative file. If a doc's block has everything nested under `entities:`, that's a bug in the doc, not something to work around when testing — flag it and fix the doc rather than hand-editing your test copy silently.

`kongctl`'s `!secret` tag only works on fields the CLI has specifically allowlisted as "reviewed write-only fields" — a field's JSON schema marking it `x-encrypted` does **not** guarantee `!secret` support yet. A real example: the AI Model Provider's own `config.auth.headers[].value` supports `!secret`, but the AI RAG Injector Policy's `config.embeddings.auth.header_value` (same conceptual shape, also `x-encrypted` in its schema) does not, and `kongctl apply` rejects it outright:

```
Error: failed to load configuration: failed to process !secret tags in <file>: resource ai_gateway_policy "<name>" field /config/embeddings/auth/header_value is not a reviewed write-only field and cannot use !secret
```

If you hit this, don't assume the doc's field name or nesting is wrong — dry-run with plain `!env` instead of `!secret` on that specific field to confirm the rest of the config is otherwise valid, then flag the `!secret` gap itself as the finding (worth a product ask: get the field added to kongctl's allowlist, since the schema already signals it should be secret-able).

## Debugging playbook

### "Control plane says synced, but the proxy doesn't work"

If you create something (an agent, a route, etc.), get a clean `201`, and then a proxied request through the gateway (`http://localhost:8000/...`) 404s with something like `"no Route matched with those values"`, don't assume the config you sent was wrong. Check propagation first:

```bash
curl -s "https://<region>.api.konghq.tech/v1/ai-gateways/${AI_GATEWAY_ID}/nodes" \
  -H "Authorization: Bearer ${KONNECT_TOKEN}" -H "Accept: application/json"

curl -s "https://<region>.api.konghq.tech/v1/ai-gateways/${AI_GATEWAY_ID}/expected-config-version" \
  -H "Authorization: Bearer ${KONNECT_TOKEN}" -H "Accept: application/json"
```

If the node's `config_version` **matches** `expected_config_version` and `compatibility_status` is `FULLY_COMPATIBLE`, but the route still 404s — that's a genuine control-plane-to-data-plane propagation bug, not a config-authoring mistake. Worth escalating as-is.

A good secondary check to strengthen that conclusion: independently confirm the control-plane-side config is actually correct by dumping it with a prerelease `kongctl` (see `deploy-and-tooling.md`) rather than relying only on the `GET` you used to create it. If the dump shows the config exactly as intended, you've ruled out "the API silently mangled what I sent" as an explanation too.

### Isolating a gateway-routing bug from an upstream/agent bug

When a route through the gateway 404s (or otherwise misbehaves), also send the *exact same request* directly to the upstream/agent, bypassing the gateway entirely (e.g. `localhost:<upstream-port>/` instead of `localhost:8000/<route-path>`, accounting for whatever `strip_path` would have done). This tells you which layer is actually failing:

- If the upstream also fails the same way → it's not a gateway bug.
- If the upstream behaves differently (accepts the request, or fails for a *different*, legitimate reason) → the gateway-routing question and the upstream's own bug are two separate things, and you now have independent evidence to describe each precisely instead of one confused report.

### Don't trust example commands blindly — verify against the actual protocol

A Console UI's or doc's example request is itself just another artifact that can be wrong or stale. If an example fails, check whether it's even shaped correctly for the protocol in question before concluding the feature is broken. For example, an A2A agent's endpoint expects a JSON-RPC envelope (`jsonrpc`, `id`, `method: "message/send"`, `params.message` with `kind`/`messageId` fields) — a flat `{"message": {...}}` body without that envelope will get a real, correct protocol-level rejection from the agent (e.g. `"Invalid Request: jsonrpc must be 2.0"}`), which means the *example* is the bug, not the gateway or the agent. Sending the same request directly to the upstream (bypassing the gateway) is a fast way to confirm this, and doubles as the upstream-isolation check above.

### Search for prior context before reporting something as a new bug

Before writing up a surprising error as a fresh finding, search Slack (or wherever the team's engineering discussion lives) for the exact error string. AIGW 2.0 moves fast enough that a lot of rough edges have already been partially root-caused by the backend team days or weeks before you hit them — treating a known, already-discussed issue as brand new wastes escalation effort and can lead you to describe it less precisely than the people who already dug into it. Concretely: an error that looks identical on the surface (e.g. the same exception message) can have a prior thread that already explains *part* of it — read that thread fully before concluding what's still open versus already resolved.

**Case in point** (`"failed the initial dns/balancer resolve for 'ai-gateway.upstream.local'"`): this looked like a standalone data-plane bug the first several times it was hit. A prior Slack thread (about a week earlier) had already established that AIGW's `ai-model-selector` plugin requires an explicit `model` field in the client's request body — without it, no target gets selected and the request falls through to a placeholder host (`ai-gateway.upstream.local`) that was never meant to actually resolve, producing this exact, confusing DNS-shaped error message. That part is a **doc/request-shape gap**, not a backend bug: add `"model": "<target-name>"` (matching the `targets[].name` configured on the AI Gateway model entity, not the model entity's own `name`/`alias`) to the request body.

**But don't stop at the first plausible explanation — verify live.** Adding the correct `model` field does change the error (a wrong model name now gets a clear `"cannot use own model - must be: <target-name>"` rejection instead of the DNS message), confirming that part of the theory. But retesting with the *correct* `model` value can still reproduce the *exact same* DNS failure afterward — meaning there are two layered issues here, not one: a real doc gap (missing `model` field) sitting on top of a still-genuine, still-open backend bug in resolving the target's upstream once it's correctly selected. Only confirm an issue is fully resolved by re-running the test and checking the doc's actual expected outcome (e.g. the promised `200`) — not just by seeing a different, more specific error appear.

### `make run` fails with "Liquid syntax error ... tag was never closed"

If Jekyll refuses to build a doc with an error like `'konnect_api_request' tag was never closed`, don't assume a real `{% ... %}` block is malformed — first check for a **literal mention of a tag name inside an HTML comment** (e.g. a `<!-- TODO: replace this with a {% konnect_api_request %} step -->` note left for a future editor). Liquid parses `{% %}`/`{{ }}` delimiters before HTML comments are stripped, so writing a tag name with its braces inside a comment gets parsed as a real, unclosed tag — even though it's invisible on the rendered page. Fix: drop the braces in the comment text (name the tag in plain words) rather than writing it as if it were live Liquid. The reported error line number can be misleading (it may point well past the actual offending line), so grep the whole file for `{%` and `{{` outside of real, matching tag pairs rather than trusting the line number alone.

### General principle

Every one of these checks exists to answer one question: **which specific layer is wrong** — the doc's example, the request shape vs. the spec, the control plane's stored config, the control-plane-to-data-plane propagation, or the upstream/agent itself? A bug report that names the layer is immediately actionable; one that just says "it doesn't work" isn't.
