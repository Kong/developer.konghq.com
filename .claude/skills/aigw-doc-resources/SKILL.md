---
name: aigw-doc-resources
description: >
  Points Claude at the right resource for an AI Gateway (AIGW) docs task in
  developer.konghq.com — migrating a v1 doc to v2, drafting a new AIGW how-to,
  or testing one. This is a resource map only (where the API spec is, where
  the test harness is, which directories are v1 vs v2, which other skill
  actually does the work) — it does not itself review, write, or test
  anything. Use it whenever working under app/_how-tos/ai-gateway/,
  app/ai-gateway/, app/_ai_gateway_entities/, or app/_ai_gateway_policies/,
  or whenever asked where the AIGW spec, test harness, or a v1/v2 doc lives.
  Triggers on "where's the AIGW spec", "migrate this AIGW doc", "draft an AI
  Gateway how-to", "test this AIGW doc", or any AI Gateway docs task where the
  first question is "what do I have to work with here".
---

# AIGW docs resource map

This is a pointer skill, not a rules or testing skill. It exists so Claude
doesn't have to re-derive where things live every session. For the actual
work, jump to the skill named in section 3.

## 1. Hard rule: this repo documents AIGW 2.0 only

Anything under a `v1/` path — `app/_how-tos/ai-gateway/v1/`,
`app/ai-gateway/v1/` — is legacy AIGW 1.0 content. Never cite it as current
behavior, and never assume its config shape (plugin fields, IDs, entity
names) carries over unchanged to v2. It's migration source material only.

v2 is Konnect-only (no on-prem data planes) and uses **Policies**, not
**Plugins**, for anything AI-specific (AI Proxy / AI Proxy Advanced / AI A2A
Proxy / AI MCP Proxy are the only exceptions — those stay plugins in v2 too).

## 2. Docs repo map

- Current v2 how-tos: `app/_how-tos/ai-gateway/*.md`
- Legacy v1 how-tos (migration source only): `app/_how-tos/ai-gateway/v1/*.md`
- v2 reference/concept pages: `app/ai-gateway/*.md` (e.g. `v2-migration-guide.md`, `configuration.md`, `ai-providers/`)
- v1-parallel reference pages: `app/ai-gateway/v1/*.md`
- Entity reference pages: `app/_ai_gateway_entities/` (AI Agent, AI Auth Strategy, AI Consumer, AI Model, AI Policy, AI Provider, AI Vault, etc.)
- **Policy schema source of truth**: `app/_ai_gateway_policies/<policy-slug>/index.md` — e.g. `app/_ai_gateway_policies/ai-rag-injector/index.md`. Check here for a policy's actual v2 config fields before assuming a v1 plugin's fields carry over.
- Migration tracker: `app/_config/releases/ai-gateway/v1.yml` — per-v1-file `status: pending` / `canonical_url`. Update the relevant entry whenever a v2 replacement is authored.
- **Naming convention**: a v1 how-to named `use-x-plugin.md` (permalink ending `-plugin/`) becomes `use-x-policy.md` (permalink ending `-policy/`) in v2 — not just "plugin" → "Policy" in prose. Confirmed examples: `use-ai-prompt-guard-plugin.md` → `use-ai-prompt-guard-policy.md`, `use-ai-aws-guardrails-plugin.md` → `use-ai-aws-guardrails-policy.md`. The four plugin-only exceptions (AI Proxy, AI Proxy Advanced, AI A2A Proxy, AI MCP Proxy) keep "plugin" in the v2 filename too. `ai-gateway-migration-review` checks this rule — but it's easy to still get wrong when drafting a brand-new v2 file from scratch (pattern-matching a v2 sibling's *content* doesn't automatically catch that the sibling's *filename* also changed), so check it explicitly before naming a new file.

## 3. Related skills — defer to these, don't duplicate their logic here

- **Reviewing/fixing an existing AIGW file for migration correctness** (frontmatter shape, plugin→policy renaming, entity naming, unmigrated links) → `ai-gateway-migration-review` (repo-committed).
- **Scaffolding a brand-new how-to from scratch** (any product, not just AIGW) → `how-to-starter` (repo-committed). Its `references/scaffold-patterns.md` is also the canonical reference for `{% entity_examples %}` syntax, the `!ref`/`!lookup` same-block scoping rule, and the `{% validation %}` cheat sheet — worth reading even when *revising* an AIGW doc's kongctl blocks, not just when scaffolding a new page.
- **Testing an AIGW how-to end-to-end against a live prerelease gateway** → `aigw-doc-testing` (repo-committed).
- **Testing the `use-claude-code-with-ai-gateway-*` CLI-routing doc family specifically** → `ai-cli-gateway-testing` (private).

## 4. API spec

- Canonical source: https://github.com/Kong/platform-api/blob/main/build/complete/konnect/public.yaml
- Local clone: `~/docs/platform-api` — general platform-api spec-tooling repo (`definitions/`, `overlays/`, `computed/`). Does not currently contain a dedicated AI Gateway definition/overlay directory of its own — useful for the toolchain, not a shortcut to the AIGW spec.
- **Faster path**: a local pre-fetched copy of the actual Konnect AI Gateway OpenAPI spec lives at `~/docs/ai-gateway-test-harness/ref/konnect-ai-gateway.json`. Prefer grepping this over fetching the GitHub URL or the full platform-api spec.

## 5. Test harness

- Repo: https://github.com/Kong/ai-gateway-test-harness/
- Local clone: `~/docs/ai-gateway-test-harness` (actively maintained). Useful subpaths:
  - `ref/kongctl/*.yaml` — realistic declarative config examples (providers, models, policies, agents, vaults, gateway, mcp_servers). Good source of real config shapes when drafting or migrating a how-to.
  - `ref/codex.md`, `ref/claude_code_guide.md` — provider CLI guides.
  - Its own `CLAUDE.md` / `ONBOARDING.md` document the harness's own conventions in more depth than this skill needs to repeat.
