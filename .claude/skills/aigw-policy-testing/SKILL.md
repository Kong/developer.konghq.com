---
name: aigw-policy-testing
description: >
  Produces a standalone runbook (a new markdown file, not a docs-site page) with every
  step needed to manually test one AI Gateway (AIGW) 2.0 Policy end-to-end: prerequisites,
  third-party tool requirements, the simplest possible config (local wherever the policy
  allows it), and a final Validate step with the expected result. Use this whenever asked
  to "write a test runbook/plan for the <X> policy", "how do I test the AI Prompt Guard
  policy", "create steps to validate this AI Gateway policy", or when migrating a Kong
  Gateway plugin to its Policy equivalent and a manual test plan is needed for it.
  Distinct from `aigw-doc-testing` (runs an *existing how-to doc* against a live
  gateway and reports drift) and from `ai-gateway-migration-review` (audits doc prose for
  v1->v2 correctness) — this skill authors a brand-new, self-contained runbook for one
  policy, not tied to any existing doc page. Only ever targets AI Gateway **v2** (the
  Policy schemas under `app/_schemas/ai-gateway/policies/`) — never used for v1. Prefers
  the simplest local setup for backing services (a local Docker container over a hosted
  dependency) while defaulting the LLM backend itself to a real OpenAI account, matching
  every other published v2 how-to. Triggers on "write a runbook to test the AI Semantic
  Cache policy", "give me a test plan for AI AWS Guardrails", "I'm migrating the
  rate-limiting-advanced plugin to a policy, help me test it", or "how would I validate
  the ai-custom-guardrail policy locally".
---

# Creating an AI Gateway policy testing runbook

This skill only ever targets AI Gateway **v2** — the Policy schemas under
`app/_schemas/ai-gateway/policies/`. Never treat `app/_how-tos/ai-gateway/v1/` or
`app/ai-gateway/v1/` plugin config as authoritative for field names or config shape; at
most, borrow a v1 doc's *test intent* (what scenario it proved) when adapting a migration
runbook, and rebuild the config from the v2 schema.

The deliverable is **one markdown file** — a literal, copy-pasteable runbook (plain bash /
curl / kongctl, no Jekyll `{% %}` tags, no frontmatter) that a person or another agent can
follow top to bottom to stand up a minimal AI Gateway, configure exactly one Policy, send
requests that exercise it, and confirm a specific expected result. It is not a docs-site
page — save it wherever the user asks (default: the scratchpad, named
`<policy-slug>-test-runbook.md`), and don't add it under `app/`.

## Step 1: Identify the policy and read its schema

1. Get the exact policy under test from the user. If they only name a Kong Gateway
   *plugin* (e.g. "the rate-limiting-advanced plugin") they're migrating, the v2 Policy
   slug is normally identical — v2 reuses most plugin config as-is under
   `ai_gateway_policies`. One exception: **AI Proxy, AI Proxy Advanced, AI A2A Proxy, and
   AI MCP Proxy don't exist as Policies (or plugins) in v2 at all** — plugins as a concept
   are gone, and that particular functionality is built directly into the AI Model, AI
   Agent, and AI MCP Server entities themselves (e.g. attaching a generic Policy like
   Request Size Limiting to an AI Agent is how you govern A2A traffic — see
   `app/_how-tos/ai-gateway/limit-a2a-body-size.md`). If the user names one of those four,
   there's no standalone Policy schema to test — point them at the relevant entity's docs
   (`app/_ai_gateway_entities/ai-model.md`, `ai-agent.md`, `ai-mcp-server.md`) instead of
   producing a Policy runbook for it.
2. Find its JSON schema in `app/_schemas/ai-gateway/policies/`. Filenames are PascalCase
   with irregular acronym casing (`ACL.json`, `AiA2aProxy.json`, `RateLimitingAdvanced.json`)
   — don't guess the casing. Strip hyphens from the slug and glob case-insensitively:
   ```bash
   find app/_schemas/ai-gateway/policies -maxdepth 1 -iname "$(echo '<slug>' | tr -d '-').json"
   ```
3. Read `properties.config.properties` for the real field names, `required`, `enum`
   values, and defaults. This is the source of truth for what the runbook's config step
   writes — don't invent field names from memory or from a possibly-stale v1 plugin doc.
4. Note anything in the schema that implies a **backing dependency** the policy needs to
   actually exercise (a `vectordb` block, a webhook `request.url`, AWS/Azure/GCP
   credential fields, an external judge/guardrail API key). This becomes the
   "third-party tool requirements" section of the runbook — see
   `references/dependencies-and-mocking.md` for how to satisfy each kind as cheaply and
   locally as possible.

## Step 2: Reuse real, already-tested material before writing anything from scratch

Check, in order, and prefer whatever you find over a hand-written example:

1. `app/_ai_gateway_policies/<slug>/index.md` — may already have a worked
   `{% entity_examples %}` config for this policy (skip if it's still an empty stub).
2. `app/_how-tos/ai-gateway/*.md` — a full how-to that configures this policy end-to-end
   (e.g. `use-ai-prompt-guard-policy.md`) is the best possible source: its config and
   test prompts are already validated. Adapt its `entity_examples` block into plain
   kongctl YAML for the runbook — drop only the Liquid `{% entity_examples %}` wrapper.
   **Keep `!lookup`/`!ref` tags as real kongctl YAML tags** rather than resolving them to
   literal values; they're a real part of what the runbook exercises. See
   `references/dependencies-and-mocking.md` for the one scoping rule to get right
   (`!ref` only resolves within the same kongctl apply block).
3. **Migration case** — if the user says they're migrating a Kong Gateway plugin: search
   `app/_how-tos/gateway/` for an existing tutorial using that plugin, and
   `app/_kong_plugins/<slug>/examples/*.yaml` (or `app/_schemas/gateway/plugins/<version>/<Name>.json`
   for the old plugin schema) for its example config. Adapt the plugin's test scenario to
   the Policy's schema rather than starting over — call out in the runbook's Overview what
   changed (config shape, `type: plugin` -> `type: ai_gateway_policies` entity kind, any
   renamed/removed fields you found by diffing the two schemas).
4. Only write a new example from the schema directly if none of the above exist.

## Step 3: Work out prerequisites

Every runbook needs the same baseline — see `references/dependencies-and-mocking.md` for
the exact commands:

- Docker running.
- A Konnect account and personal access token (`KONNECT_TOKEN`), since AIGW 2.0 is
  Konnect-only — there's no fully offline/on-prem setup, "local" here means a local
  *data-plane* container talking to a Konnect-managed control plane.
- `curl`, `jq`.
- `kongctl` (prefer it over `deck`/raw API calls, matching every real v2 how-to).

Default the LLM backend to a real **OpenAI** account (`app/_includes/md/ai-gateway/v2/prereqs/openai-kongctl.md`)
— it's the API key every other v2 how-to already assumes, so a runbook built on it stays
consistent with the rest of the docs and with whatever example config Step 2 reused.
Then add whatever Step 1 flagged as policy-specific: a Redis Stack container for any
`vectordb`-backed policy, a tiny local mock server for a webhook-shaped guardrail, or a
real third-party credential when there's no way around it (e.g. AI AWS Guardrails needs a
real `guardrails_id` — say so plainly rather than pretending a local stand-in exists).

Also ask the user, before writing the runbook, whether it should target **production**
Konnect (`.com`) or the **prerelease `.tech`** domain — don't assume. Default to
production unless they say otherwise; see `references/dependencies-and-mocking.md` for
the `.tech` override.

## Step 4: Write the runbook

Use this section order. Every runbook ends with Validate — never leave it implicit.

```markdown
# Test runbook: <Policy display name> (`<policy-slug>`)

## Overview
What this policy does, one or two sentences, and what this runbook proves.
(Migration runbooks: one line on what changed from the old plugin.)

## Prerequisites
- Standard baseline (Docker, Konnect PAT, curl, jq, kongctl)
- Policy-specific: <backing service / third-party credential, named plainly>

## 1. Start AI Gateway
<quickstart command with the chosen -a name and domain (prod or .tech) — see
references/dependencies-and-mocking.md>

## 2. Start <backing service>, on the same Docker network
<only if the policy needs one — this is the ONLY reason to fetch the Docker network at
all. If no later step starts another container, skip fetching it entirely: don't add a
`docker inspect .../NetworkSettings.Networks` step just because it's standard practice
elsewhere. When this step is present, fetch the real network name from the running
gateway container here, immediately before the command that needs it — see
references/dependencies-and-mocking.md>

## 3. Configure the AI Model Provider, AI Model, and the policy under test
<minimal kongctl declarative YAML, applied inline via
`kongctl apply -f - --pat "$KONNECT_TOKEN" --auto-approve <<'EOF' ... EOF` — no
intermediate .yaml file, and `--auto-approve` so the runbook doesn't stall on an
interactive confirmation prompt>

## Validate
### Request that should be allowed/pass through
<one concrete curl (use `-i` so status + body are visible from a single call — don't
send it once to "demonstrate" and again to "check"), immediately followed by the exact
expected result: status code, response body/header, or a specific log line to grep for>

### Request that should be blocked/transformed/triggered on
<same pattern — every policy with a decision to make needs at least this second case,
one command with its expected result stated right below it>

<add further subsections the same way for any other scenario the policy needs proven
(e.g. a vectordb hit vs. miss) — never a separate numbered "send" step followed by a
separate "confirm" step re-sending the same request>.

## Cleanup
<tear down the CP, any extra containers, and the docker network>
```

Fill in real values everywhere — no `<!-- TODO -->` placeholders. This is a runbook meant
to be run as-is, not a docs scaffold. If something is genuinely unknown (e.g. the user
hasn't said which cloud region their AWS Guardrail lives in), ask rather than guessing.

## Step 5: Sanity-check before handing it back

Two separate things to check — the policy schema only covers one of them:

1. **`config.*` fields** against the schema from Step 1: every field you wrote must
   exist in `properties.config.properties`, every `required` field must be present, and
   every enum value must be valid.
2. **Entity envelope fields** (`ref`, `name`, `display_name`, `enabled`, `global`,
   `ai_gateway`, `type`, and, on a Model, `formats`/`capabilities`/`policies`/`targets`)
   — these aren't in `app/_schemas/ai-gateway/policies/<Policy>.json` at all, so the
   schema check above won't catch a missing one. Cross-check these against a real,
   working `entity_examples` block from an existing how-to (Step 2) instead — e.g.
   `display_name` is required on `ai_gateway_policies` and `ai_gateway_models` entries
   (confirmed live: dropping it fails `kongctl apply` with `missing required fields:
   display_name`), but not on `ai_gateway_model_providers`. See
   `references/dependencies-and-mocking.md` for the confirmed shape.

This is the same cross-check `aigw-doc-testing` does against the OpenAPI spec — catching
a typo'd or missing field here is free; catching it after telling the user to run
`kongctl apply` is not. If a live AI Gateway is already available in the session,
actually run the runbook's steps before handing it back rather than trusting it
unverified — but producing the file is the job even without one.

## Reference

- **`references/dependencies-and-mocking.md`** — the exact quickstart command with a
  chosen `-a` name and domain (prod vs `.tech`), how to fetch the real Docker network
  name from the running gateway container rather than assuming a naming pattern, the
  printed env vars, the default OpenAI backend, the Redis Stack requirement for
  `vectordb` policies, a mock-webhook pattern for request/response-shaped guardrails, and
  which third-party dependencies have no local stand-in at all.
