---
name: aigw-doc-testing
description: Test Konnect AI Gateway (AIGW) 2.0 how-to docs end-to-end against a live prerelease gateway in the get.konghq.com repo — deploying a disposable test gateway via ai/index, cross-checking doc request bodies against the OpenAPI spec, running each step as a real user would, and diagnosing control-plane-vs-data-plane bugs. Use this whenever the user wants to try out, verify, QA, or troubleshoot an AI Gateway / AIGW how-to doc, tutorial, or guide before or after it publishes — including phrases like "run through this doc", "test this AIGW guide", "does this how-to still work", "try this against the latest AI Gateway spec", or when they hand you a doc plus a spec and ask you to validate them together. Also covers the case where the user explicitly says a doc predates a spec change (e.g. "this was written before the spec change, figure out how to configure it with the new spec/provider model") — here the job is to adapt the doc's intent to the current schema, not just flag drift as a bug. Also use it if the user just asks to "deploy a test AI Gateway" or "spin up an AIGW instance" in this repo, even without mentioning a doc.
---

# Testing AI Gateway 2.0 how-to docs

This skill captures a working end-to-end recipe for testing Konnect AI Gateway (AIGW) 2.0 how-to docs in this repo against a real, disposable gateway — deployed with a prerelease build, targeting the `.tech` test domain. It exists because AIGW 2.0 is new enough that docs, the Console UI, and even the CLIs (`kongctl`, `deck`) can drift out of sync with the actual API — the value here isn't just running commands, it's knowing where that drift tends to show up and how to isolate it fast when something doesn't work.

## When a doc test starts, do this in order

1. **Read the doc's frontmatter fully** — `prereqs`, `entities`, `min_version`, `cleanup`. Inline prereqs and `include_content` references (e.g. a companion `docker-compose.yaml` for a local test agent) may already exist as untracked files in the repo. Run `git status` before assuming a prereq is missing — someone may have already dropped it in.
2. **Get the current OpenAPI spec loaded** (usually a local file the user hands you, e.g. `~/Downloads/aigw*.yaml`). See `references/spec-and-debugging.md` for how to navigate it — it's typically 10k+ lines, too big to `Read` in one shot.
3. **Deploy a disposable test gateway** if one isn't already running. See `references/deploy-and-tooling.md` for the exact command, flags, and the naming-pattern gotcha that will otherwise fail the deploy.
4. **Before running any request body from the doc**, cross-check it against the spec's matching `Create*Request`/`Update*Request` schema — property names, required fields, enums, `additionalProperties: false` blocks, and identifier patterns. Catching a mismatch here is cheap; debugging it after a 400/404 downstream is not.
5. **Run every step as a real user would**, in order, using the env vars the deploy prints out (corrected per the `.tech` gotcha below). Don't skip ahead or batch steps just because they seem safe — the point of the exercise is to catch exactly what a doc reader would hit.
6. **If something doesn't match the spec, looks like an unfilled placeholder (e.g. a literal `CP_NAME` or `<YOUR_...>` left in verbatim), or would delete/overwrite an existing resource, stop and ask before running it.** Guessing at intent defeats the purpose of testing the doc as a real reader would experience it.
7. **When a step fails, don't stop at "it failed"** — isolate *where* it failed using the debugging playbook in `references/spec-and-debugging.md`. A 404 on a gateway route could be a control-plane bug, a data-plane propagation bug, or the upstream/agent itself — these need different fixes and different bug reports.
8. **Before treating a surprising error as a brand-new bug, search Slack (or wherever engineering discussion lives) for the exact error string.** AIGW 2.0 moves fast enough that a lot of what looks fresh has already been partially investigated — and a "confirmed" fix from one of those threads still needs to be verified live, not assumed to fully hold on whatever build you're currently testing. See the worked example in `references/spec-and-debugging.md`.
9. **When you're ready to write up a bug for engineers, produce a `kongctl` declarative dump scoped to just the gateway in question** (`--filter-name <gateway-name>`, `--output-file <path>`) as supporting evidence — it independently confirms exactly what config the control plane actually stored, which is often the first thing engineering will ask for. Scope it to the one gateway, not the whole org: an unfiltered dump pulls in every other engineer's test resources too, which is noise at best and their data at worst. See `references/deploy-and-tooling.md` for the exact command.

## When the doc is explicitly outdated: adapt it, don't just flag it

Sometimes the user hands you a doc and tells you upfront that it predates a spec change. That flips the goal: schema mismatches here are *expected*, not bugs to report. The job is to reconstruct what the doc was trying to accomplish using the current spec — not to patch the old doc's JSON field-by-field, and not to file a drift report the way you would for a doc that's supposed to still be current.

1. **Identify the capability the old doc was going for**, independent of its specific request bodies — e.g. "authenticate outbound calls to a model provider with an API key," not "call this specific old endpoint with this specific old body."
2. **Find the current spec's equivalent resource for that capability before assuming it's just a renamed field.** AIGW 2.0 has, at least once, pulled a whole concept out into its own first-class resource rather than just renaming a field in place — e.g. `model_providers` is a separate entity (its own `type` like `anthropic`/`openai`, its own `config.auth` block for header name/type) that other entities reference, rather than provider auth living inline wherever the old doc put it. If you go looking for the old field and it's gone, check whether the *shape* of the feature moved before concluding it was removed.
3. **Write the new request body from the current spec's schema directly**, then cross-check it the same way as any other doc (required fields, enums, `additionalProperties: false`, identifier patterns — `references/spec-and-debugging.md`).
4. **Test the adapted version for real** — deploy, run the adapted steps end to end, confirm the outcome the original doc promised actually works now.
5. **Explain what changed and why in terms of the capability**, not just a field diff — that's what makes the adaptation actually usable by whoever updates the published doc afterward.

## The one gotcha that trips up everything else: the `.tech` domain

Prerelease AIGW testing happens on `konghq.tech`, not `konghq.com`. The deploy script gets this right for its own AI-Gateway-specific calls, but at least one downstream script (the generic `quickstart` decK-env output) hardcodes `.com` and will silently point you at the wrong domain. **Every manual API call and CLI invocation you make while testing an AIGW 2.0 doc must explicitly target `https://<region>.api.konghq.tech`.** Don't trust an auto-printed URL without checking it says `.tech`. Full detail in `references/deploy-and-tooling.md`.

## Session mechanics

The Bash tool's shell state doesn't persist between calls, so once you've deployed and have `AI_GATEWAY_ID`, `KONNECT_TOKEN`, etc. in hand, write them to a small `.sh` file in the scratchpad and `source` it at the top of every subsequent command block, e.g.:

```bash
source /path/to/scratchpad/aigw-env.sh 2>/dev/null
curl -s "https://us.api.konghq.tech/v1/ai-gateways/${AI_GATEWAY_ID}/agents" -H "Authorization: Bearer ${KONNECT_TOKEN}" ...
```

Upstream test credentials for doc prereqs (WeatherAPI key, and whatever else future docs need) live separately, in `~/.aigw-test-keys.env` — a durable file outside any git repo, meant to persist across sessions (unlike the per-session scratchpad file above). Source it too at the start of a session: `source ~/.aigw-test-keys.env 2>/dev/null`. Append new keys there as new docs need them; never put real key values in this skill's own files or in memory.

This skill is team-shared, but `~/.aigw-test-keys.env` is not — it's a per-person convention, not a file that ships with the skill or already exists on a new teammate's machine. If it's missing, create it yourself (own Konnect PAT, own upstream API keys) rather than assuming someone else's copy or values apply to you.

## Reference files

- **`references/deploy-and-tooling.md`** — the exact deploy command and its flags, the CP-name pattern restriction, what env vars get printed and how to fix the `.tech` one, and the `kongctl`/`deck` tooling gaps you'll hit if you try to inspect the gateway with anything other than raw API calls or a prerelease `kongctl`.
- **`references/spec-and-debugging.md`** — how to navigate a large AIGW OpenAPI spec efficiently, how to cross-check a doc's request body against it, and a debugging playbook for "control plane says synced but the proxy doesn't work" and similar bugs, including how to tell a gateway-routing bug apart from an upstream/agent bug, why you shouldn't trust a UI's or doc's example request without checking it against the actual protocol, why a model route needs an explicit `model` field in the request body (and the layered-bug trap that hides behind it), and why to search for prior context before reporting something as new.
