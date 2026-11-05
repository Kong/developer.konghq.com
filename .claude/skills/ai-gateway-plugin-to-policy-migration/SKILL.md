---
name: ai-gateway-plugin-to-policy-migration
description: Use when migrating, converting, or porting a Kong Gateway plugin page (app/_kong_plugins/<plugin>/) to an AI Gateway 2.x AI Policy page (app/_ai_gateway_policies/<policy>/) on developer.konghq.com, including live testing against a test gateway and a prose pass. Triggers on "migrate this plugin as an AI policy", "plugin to policy", "convert <plugin> to an AI policy", "AI policy page for <plugin>", or a plugin name plus AI Gateway.
argument-hint: <plugin-name> [full | draft-only | test-only]
allowed-tools: Read, Grep, Glob, AskUserQuestion
---

# Plugin-to-policy migration

Migrate a plugin page to an AI Policy page, test the policy live, then polish the prose.
The page is written from what you observe on a live gateway, not from what the plugin page claims.

`$ARGUMENTS` holds the plugin name and optionally a mode. If the plugin is missing, ask for it.

Supporting files (read them when the step says so, not up front):
- `references/frontmatter.md`: policy page frontmatter template
- `references/api-shapes.md`: Konnect AI Gateway request shapes and the kongctl check
- `references/harness-ops.md`: data plane, mock upstream, scripting, safety, cleanup, run state file
- `references/known-traps.md`: product behaviors that look like failures or false passes
- `references/reference-runs.md`: two worked migrations (request-termination, canary)
- `assets/results-table.md`: templates for the inventory, results table, summary, engineering message

## Gates

The user stays in control through gates. At each gate, stop, present the listed items, and wait for an answer. Do not continue on silence or on approval given for an earlier gate.

| Gate | When | You present |
|---|---|---|
| 0 | Before anything | Confirmation to run, and the mode |
| 1 | After Step 1 | Plain-language testing plan (what the policy does, 4 to 6 checks, what is left out), valid-policy-type check |
| 2 | Before Step 4 | Gateway, data plane and every resource you will create, whether the CA bundle or a mock is needed |
| 3 | After Step 4 and 4b | Results table, contradicted and untested claims, suspected bugs, proposed page content |
| 4 | Before cleanup and before any `kongctl apply` | Exact list of what you will delete or apply |
| 5 | After the prose report | Flags to edit |

Nothing is committed or pushed unless the user gives an explicit instruction for it each time.

## Step 0: Confirm before running (Gate 0)

This skill can create and delete resources on a shared test gateway, restart the test data plane, and apply kongctl manifests. Ask the user with `AskUserQuestion`, even when they invoked the skill by name. State the plugin, the policy page you will create or edit, and that live testing and cleanup are part of the run.

Modes:
- **full** (default): inventory, live matrix, page, prose pass.
- **draft-only**: no gateway access. Write the page from the schema and plugin page, and mark every behavior untested in the summary. Skip Steps 4 and 4b.
- **test-only**: inventory, live matrix and results report. Do not edit the page.
- **cancel**.

Do not read the harness `.env` or touch the gateway until the user answers.

## Where things live

Check these paths in the repo before relying on them, since the layout can change.

- Policy pages: `app/_ai_gateway_policies/<policy>/index.md`, published at `/ai-gateway/policies/<policy>/`. Do not create `app/ai-gateway/policies/`: the collection owns the URL.
- The reference (schema) page is generated at `/ai-gateway/policies/<policy>/reference/`. Never hand-write it or a `reference.md`.
- Optional `examples/` next to `index.md`. Most policies use inline `{% entity_example %}` blocks.
- Stubs often exist. Read `app/_ai_gateway_policies/<policy>/index.md` before creating anything. A frontmatter-only stub is normal.
- Scope support: `app/_data/policies/ai-gateway/scopes.json` (array of `{name, scopes}`). Read it, do not duplicate it by hand.
- Priority: `app/_data/policies/ai-gateway/priorities.json` is a flat map of policy type to number (`"canary": 20`). There is no `priority.yml`.
- Never edit generated content: `app/_schemas/`, `*/schema.json`, `*/changelog.json`, `app/_references/`. The next sync overwrites it.

## Step 1: Gather inputs

1. Read `app/_kong_plugins/<plugin>/index.md` and `examples/*.yaml`.
2. Get the config schema: `app/_schemas/gateway/plugins/<latest>/<PascalCasePluginName>.json` (for example `3.14/RequestTermination.json`). The plugin dir may have no `schema.json`.
3. Read the policy's entry in `scopes.json`.
4. Use `app/_ai_gateway_policies/ip-restriction/index.md` as the pattern for a simple policy page.
5. Check the plugin is a valid policy type: it needs an entry in `scopes.json`. Auth plugins such as `key-auth` and `jwt` are configured through AI Auth Strategies. `ai-proxy` and `ai-proxy-advanced` are not migrated. If the plugin is not valid, stop and tell the user.
6. Build an option inventory (template in `assets/results-table.md`). List every schema field, every mode or enum value, and every plugin-page claim. Mark each item that depends on a Gateway-only concept (Service, Route, Upstream entity, ACL plugin, Consumer groups through ACL, Forward Proxy). Those are the likeliest to behave differently, so test them first. The inventory becomes the test matrix and the "not tested" list.

**Gate 1:** present a plain-language testing plan, using the "Testing plan (Gate 1)" template in `assets/results-table.md`. The user must be able to understand and approve it without knowing Kong internals.
- Open with what the policy does in two or three sentences, and list its settings in one line each.
- List 4 to 6 numbered checks. Each check is one sentence that says what you will do and what result you expect. Spell out what a term means the first time you use it (for example "global scope: the policy applies to all traffic").
- Do not use tables, schema paths, option names without an explanation, or abbreviations such as "SAN" or "DP" in the plan.
- Say what you will leave out of testing, what will therefore be marked "not tested", and what you will not port to the page.
- Propose a minimal set and a fuller set, and recommend one. The full inventory table stays in your working notes and in the final summary, not in the Gate 1 message.
- End with one or two direct questions. Ask the user to confirm or trim.

## Step 2: Frontmatter

Read `references/frontmatter.md` and apply the template. Write only frontmatter and a skeleton until the Step 4 matrix has results (or, in draft-only mode, until the user approves the structure).

## Step 3: Body

Write the body from the verified results of Step 4b. In draft-only mode, write from the schema and plugin page and mark every behavior untested in the summary.

Before removing a plugin note about a `kong.conf` setting (for example `untrusted_lua`), check whether AI Gateway has the same setting. The reference at `/ai-gateway/configuration/#<setting-with-hyphens>` is generated from `app/_kong-conf/ai-gateway/<version>.json`. If it exists, keep the note and link it. Check the real default and accepted values on the data plane (`docker exec <dp> grep <setting> /usr/local/kong/.kong_env`) instead of copying the plugin's requirement, which may not apply (Exit Transformer works under the default `untrusted_lua = strict`). A shared include exists for Lua policies: `md/ai-gateway/v2/policies/sandbox.md`.

Remove, do not port (these describe Gateway mechanics that do not exist on AI Gateway):
- Forward Proxy interaction, dynamic plugin ordering, Service/Route/Consumer wording.
- Links to how-tos and to `/plugins/...` pages.
- The plugin's "use cases" table with `?format=deck&target=...` links. Keep use cases to what the policy does, unless the user supplies real scenarios. A `## Use cases` section is an editorial choice: check whether other policy pages have one, and add it only when the user asks. When asked, use a two-column `{% table %}` (in `<!--vale off-->`), a one-sentence lead-in, and rows that name the reader's problem ("A user reports a failed request"), not the setting ("Set `echo_downstream`"). Scope each row to the entity types you verified, so no row promises behavior that a Limitations bullet takes back.

Port and adapt:
- The opener: "The X [AI Policy](/ai-gateway/entities/ai-policy/) ..." with `{{site.ai_gateway}}`. Entity names use "AI {Name}".
- Parameter explanations, grouped by task (custom response, trigger, debug), not by schema order.
- A `## Scopes` section listing the scopes from `scopes.json`, linking `/ai-gateway/entities/ai-policy/#ai-policy-scopes`.
- A `## Execution order` section only if the policy has a notable priority and you verified the order live. Link `/ai-gateway/entities/ai-policy/#ai-policy-priority`.

Examples use `entity_example` with `type: policy` and exactly these formats, in this order. `deck` is excluded because AI Policies are not deck-managed, and `konnect-api` alone leaves kongctl users without an example:

```
{% entity_example %}
type: policy
data:
  name: example-name
  display_name: Example display name
  type: <policy-type>
  global: true
  config:
    ...
formats:
  - konnect-api
  - kongctl
{% endentity_example %}
```

A `kongctl` format you have not applied is untested content. Apply it (kongctl check in `references/api-shapes.md`, behind Gate 4) or list it in the summary as not run.

Parameter links: `[`config.<param>`](/ai-gateway/policies/<policy>/reference/#schema--config-<param-with-hyphens>)`. Link each parameter on first prose mention. The anchors resolve only after the generated reference page exists, so a local dev build (which skips reference generation in `jekyll-dev.yml`) cannot verify them.

## Step 4: Test live

Skip in draft-only mode.

An untested plugin option must not appear on the page as supported behavior. Read `references/harness-ops.md`, `references/api-shapes.md` and `references/known-traps.md` first.

**Gate 2:** before touching the gateway, tell the user which gateway and data plane you will use, the resource names (prefix `rt-`) you will create, and whether you need the CA bundle change or a mock upstream. Wait for approval. Create the run state file from `harness-ops.md`.

Test, for every migrated policy:
1. A control with no policy, so the policy's response is distinguishable from the upstream's.
2. Each schema parameter and each enum or mode value, one at a time, with at least 8 repeats for rate or probabilistic behavior. Include options that depend on Gateway-only concepts. Their failure is a finding.
3. Each scope in `scopes.json` you can set up: Model, Agent, MCP server, Consumer, Consumer Group, global.
4. Streaming and non-streaming requests.
5. A real provider run, in addition to a mock or fake provider.
6. Interaction with other policies (execution order).
7. Where the policy changes upstream traffic: what stays the same on the redirected request (Host header, TLS server name, path, body) for each entity type. These differ between Model, Agent and MCP server.

Confirm the intended effect, not only that "it did something". Record the exact observed behavior per scope in the results table (option, scope, result, evidence). Record behavior you observed (for example, `echo` exposes internal routing details) as reader guidance for the page. Keep verification meta-commentary ("confirmed", "tested") out of the page.

## Step 4b: Reconcile with the plugin's claims

Skip in draft-only mode. Mark every claim copied or adapted from the plugin page:
- **Verified:** keep it.
- **Contradicted:** fix or remove it, and tell the user (for example, the plugin's "`untrusted_lua` must be `on`" does not hold on the default `strict`).
- **Untested:** test it now, or soften or remove it. Never carry it into the page as fact.

Add AI Gateway 2.x behavior the plugin page never had: scope effects, auth ordering, what runs before the policy, which entity types are affected.

Suspected product bugs or unclear intent (an option that silently does nothing, a scope that behaves unexpectedly):
- Do not publish them on the page as notes or warnings, and do not publish first and ask afterward. One failed setup does not prove the feature is unsupported, and behavior may change.
- Report them to the user with the exact repro and a draft engineering message in question form (template in `assets/results-table.md`).
- Options confirmed not to work that are only a Gateway-only leftover (for example `upstream_fallback` needing an Upstream entity) can go in a short Limitations list when the user agrees.
- If the user explicitly asks to publish a suspected bug as a Limitations bullet (for example, the header missing on AI MCP Server tool calls), do it, but say in the Step 5 accuracy section that engineering has not confirmed it. Write it in positive phrasing, one sentence per line, and name the exact entity type or mode you tested (for example, an AI MCP Server that converts REST APIs to tools), not all of them. Then reconcile the opener and scope sections so they don't contradict the bullet.
- Surface editorial choices (keep a note or drop it, add a section) as questions. Do not decide them silently.

**Gate 3:** present the results table, the contradicted and untested claims, suspected bugs, and the proposed page content. In test-only mode, stop after the report and Gate 4.

## Cleanup (Gate 4)

Present the exact list of resources to delete (and any kongctl manifest you want to apply). Wait for approval, then follow the cleanup order in `harness-ops.md` and confirm nothing with your prefix remains.

## Step 5: Prose pass

Skip in test-only mode. Run it after Step 4b, every time. If you change the page afterward (new results, feedback), re-run the checks on the changed passages, then `vale`.

Run the `prose-drafting` skill in revision mode. Produce a report first and do not edit. Present flags as problem, fix, reason, with an accuracy section (claims not tested, notes the user has not approved) before the mechanics section.

**Gate 5:** wait for the user's go-ahead before editing.

Checks that mattered:
- Anthropomorphism: "lands on", "goes to", "reaches", "decides", "wins". Name the mechanism ("sends", "is assigned to").
- One sentence per line, no "not X, Y" constructions, no negative phrasing. Use contractions in informational text, as the style guide asks (`app/contributing/style-guide.md`).
- The first sentence after each heading names its subject.
- Link entity names (AI Model, AI Agent, AI MCP Server, AI Consumer) on first mention, and use the "AI {Name}" form consistently.
- The opener frames the problem the reader has, not the feature.
- No em dashes, no "once" (use "when"), positive phrasing ("The default status code is `503`", not "If you don't set...").
- Every example has a lead-in saying what it shows.
- Add the interpretive layer: which scope to choose, what global scope risks, what runs before the policy.
- Use cases framed by problem, but only real ones. Flag rows phrased as settings, jargon such as "front door", and rows that overstate a scope the Limitations section restricts. Examples with names you never ran (a custom header name) are illustrative, so say so in the accuracy section.

Then run `rtk vale <file>` and fix findings. If frontmatter changed, run `node tools/frontmatter-validator/index.js <file>`.

## Final summary

Use the summary template in `assets/results-table.md`.

## Checklist

- [ ] Gate 0 answered, mode chosen
- [ ] File at `app/_ai_gateway_policies/<policy>/index.md`, frontmatter from `references/frontmatter.md`
- [ ] Scopes section matches `scopes.json`
- [ ] No how-to links, no `/plugins/` links, no deck format
- [ ] Parameters linked to `/ai-gateway/policies/<policy>/reference/#schema--config-...`
- [ ] Option inventory approved (Gate 1); every item tested live or listed as untested
- [ ] Each behavior claim tested per scope; results table kept
- [ ] Suspected bugs reported to the user with a draft engineering message, not published on the page
- [ ] Cleanup approved (Gate 4); test resources deleted, mock stopped, keys and test cert removed, CA bundle restored, data plane `STATE_IN_SYNC`
- [ ] Claims reconciled (Step 4b); unverified claims removed or softened
- [ ] Every `entity_example` has `formats: [konnect-api, kongctl]`, and the kongctl manifest was applied or listed as not run
- [ ] Prose pass done after reconciling, re-run after later edits, `vale` clean
- [ ] Nothing committed or pushed without an explicit instruction
