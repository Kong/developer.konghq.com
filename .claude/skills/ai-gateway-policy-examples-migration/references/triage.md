# Triage

Run these checks again for every request, and do not rely on the numbers below.

## Per plugin

1. **Policy entry.** Look for the plugin slug in `app/_data/policies/ai-gateway/scopes.json`. No entry means it is not an AI Policy. When this skill was written, 37 of 143 plugins had no entry:
   - `ai-proxy`, `ai-proxy-advanced`, `ai-a2a-proxy`, `ai-mcp-proxy`: replaced by the AI Model, AI Agent and AI MCP Server entities.
   - `oauth2`, `vault-auth`, `key-auth-enc` and similar: authentication is handled by AI Auth Strategies, not policies.
   - Many third-party vendor plugins (`akamai-api-security`, `datadome`, `moesif`, and others).
   Tell the user the reason, and do not guess a replacement entity beyond what you can verify in `app/_ai_gateway_entities/`.
2. **Overview body.** Read `app/_ai_gateway_policies/<policy>/index.md`. If there is nothing after the frontmatter, the generator returns no examples for the policy (`overview_content.empty?`). When this skill was written, 62 of 110 policy pages were stubs. The outcome is "blocked": migrate the page first.
   Also read the frontmatter and the body for signs that users cannot create the policy: `published: false`, or a note that it "doesn't support entity-scoped attachment" or has no 2.x equivalent (check `app/ai-gateway/v2-migration-guide.md` too). `ai-mcp-oauth2` is the known case: `scopes.json` still lists it and the page has body text, but users don't create it (auth strategies and `access.metadata` generate its config). The outcome is "Not a creatable AI Policy": skip it and say why.
3. **Schema.** Look in `app/_schemas/ai-gateway/policies/` for a file whose name matches the slug with dashes removed, case-insensitive (`ai-sanitizer` matches `AiSanitizer.json`). No match means the validator reports a finding for the policy, so ask the user before continuing.
4. **Scopes.** Read the policy's scopes from `scopes.json`. `models` becomes `ai-model`, `agents` becomes `ai-agent`, `mcp-servers` becomes `ai-mcp-server`, `consumers` becomes `ai-consumer`, `consumer-groups` becomes `ai-consumer-group`. `global` stays.
5. **Existing examples.** List `app/_ai_gateway_policies/<policy>/examples/`. Do not overwrite a file there without asking.

## Per example

- Parse the plugin example as YAML. If it fails to parse (a tab character, seen on `opentelemetry` and `zipkin` examples), report the file and skip it. Do not fix the plugin example.
- Compare each `config` key with the policy schema. A key that the plugin has and the policy schema does not have is a reason to skip or ask.
- Look for Gateway-only concepts in `config`, `requirements` and the prose: Service, Route, Consumer targets, Upstream entity, ACL plugin, Forward Proxy, `targets: [global]`.
