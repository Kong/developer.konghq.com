# How-to scaffold patterns

1. [Frontmatter template](#frontmatter-template)
2. [Body skeleton](#body-skeleton)
3. [Chained API calls vs `entity_examples`](#chained-api-calls-vs-entity_examples)
4. [`entity_examples` vs `entity_example`](#entity_examples-vs-entity_example)
5. [kongctl `!ref` and `!lookup` scoping](#kongctl-ref-and-lookup-scoping)
6. [`{% validation %}` cheat sheet](#validation-cheat-sheet)
7. [kongctl / deck snippet style](#kongctl--deck-snippet-style)
8. [Vale](#vale)
9. [Placeholder conventions](#placeholder-conventions)

## Frontmatter template

Required by the `how_to` schema (`app/_data/schemas/frontmatter/how_to.json` + `base.json`):
`title`, `permalink`, `content_type: how_to`, `products`, `tldr: {q, a}`.

```yaml
---
title: <Do the thing>
permalink: /how-to/<slug>/          # check sibling files for this product's real pattern —
                                     # some products nest permalinks, e.g. /ai-gateway/v1/how-to/<slug>/
                                     # or /kongctl/<slug>/
description: <One sentence, what this how-to accomplishes>
content_type: how_to

products:
  - <see enum below>

works_on:                # required if products == [gateway] exactly
  - <on-prem|konnect>

tools:
  - <see enum below>

min_version:
  <product>: '<!-- TODO: confirm minimum version -->'

entities:
  - <entity type slugs used on the page, e.g. service, route, plugin>

plugins:
  - <plugin slug, if this how-to is about a specific plugin>

tags:
  - <slug>

tldr:
  q: How do I <accomplish the use case>?
  a: <One or two sentences, the shape of the answer>

related_resources:
  - text: <link text>
    url: <path>

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---
```

Enums (`app/_data/schemas/frontmatter/base.json`):
- `products`: `ai-gateway`, `gateway`, `insomnia`, `mesh`, `kic`, `catalog`, `observability`, `dev-portal`, `operator`, `konnect`, `event-gateway`, `konnect-reference-platform`, `metering-and-billing`, `identity`
- `works_on`: `on-prem`, `konnect`
- `tools`: `deck`, `inso-cli`, `kic`, `kongctl`, `operator`, `terraform`, `admin-api`, `konnect-api`, `kong-cli`

Other optional keys seen in practice, add only if relevant: `major_version` (product → integer), `faqs` (array of `{q, a}`), `next_steps` (array of `{text, url}`), `breadcrumbs` (array of paths), `published: false` (hide until ready), `automated_tests: false` (opt out of CI validation runs).

`prereqs` and `cleanup` are frontmatter-only — the layout renders them automatically. Never write `{% prereqs %}` or `{% cleanup %}` inline in the body.

## Body skeleton

Each `## H2` in a how-to body becomes a rendered, collapsible step. Order:

```
## <First config step>
## <Next config step>
...
## Validate          <- always last, always present
```

## Chained API calls vs `entity_examples`

Favor a chain of `{% konnect_api_request %}` (or `{% validation request-check %}`) calls, one per H2 step, over a kongctl/deck `entity_examples` block whenever the product has a real per-entity creation API and a later step needs an ID an earlier step generated. Each call `capture`s its own ID and the next call interpolates it as `$VARIABLE`. This is the default, not a fallback — it reads as one clean step per H2, and it has no `!ref`-scoping trap because every step is its own independent API call.

`app/_how-tos/event-gateway/kong-identity-oauth.md` is the reference model: it creates an auth server, a scope, a client, a backend cluster, a virtual cluster, a listener, and a listener policy as seven separate `{% konnect_api_request %}` steps, each one `capture`-ing the ID the next step needs (`$AUTH_SERVER_ID`, `$SCOPE_ID`, `$CLIENT_ID`, `$BACKEND_CLUSTER_ID`, `$VIRTUAL_CLUSTER_ID`...). Reread it before drafting any multi-step entity setup.

Reach for `{% entity_examples %}` instead when the product's config is kongctl/deck-declarative rather than a chain of standalone REST creates (Gateway plugins, AI Gateway v2 entities) — see the next two sections for how to use it correctly.

## `entity_examples` vs `entity_example`

Default to `{% entity_examples %}` (plural) for kongctl/deck-declarative entity/plugin config. It automatically renders the correct deck or kongctl command block for you from the page's `tools` — never hand-write a separate `kongctl apply`/`deck gateway apply` fenced command for an entity config step, the tag already produces that.

Only reach for `{% entity_example %}` (singular) when `entity_examples` genuinely can't cover the step: an entity type or format it doesn't support (only `deck`/`kongctl` are valid `entity_examples` formats — e.g. Admin-API-only entities like `event_hook` need the singular tag instead), or a deliberate multi-tool-tab reference. It is not a how-to default — it's the exception.

**`{% entity_examples %}`** (plural): multi-entity Gateway config in one block, rendered in a single format resolved from the page's `tools` (or an explicit `formats:`). Only `deck` and `kongctl` are supported formats.

```
{% entity_examples %}
entities:
  plugins:
    - name: <plugin-name>
      config:
        <!-- TODO: fill from schema/spec -->
variables:
  some_var:
    value: $SOME_ENV_VAR
{% endentity_examples %}
```

**`{% entity_example %}`** (singular): one entity, rendered as tabs across whichever tools apply (`admin-api`, `kic`, `ui`, `kongctl`, `deck`, `terraform`, `konnect-api`). Use this when you want more tool tabs than `entity_examples` supports.

```
{% entity_example %}
type: consumer
data:
  username: <!-- TODO -->
formats:
  - deck
{% endentity_example %}
```

## kongctl `!ref` and `!lookup` scoping

Two real bugs caught in testing, encode both:

**`!ref name#field` only resolves inside the same block.** kongctl applies one `entity_examples`/`entity_example` block as one unit — a `!ref` can only point at an entity declared earlier in that *same* block. Splitting a referenced entity into its own step (its own block) breaks the reference at apply time, even though it looks fine on the page. If a Model needs `!ref kong-air-key-auth#name`, the `kong-air-key-auth` auth strategy must be declared in that same `entity_examples` block, not a prior one.

```
# Wrong — two separate blocks, the !ref in the second one fails at apply time
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: kong-air-key-auth
    ...
{% endentity_examples %}

{% entity_examples %}
ai_gateway_models:
  - ref: kong-air-chat
    access:
      auth_strategies:
        - !ref kong-air-key-auth#name   # fails: not in this block
{% endentity_examples %}
```

```
# Right — one block, ref resolves
{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: kong-air-key-auth
    ...
ai_gateway_models:
  - ref: kong-air-chat
    access:
      auth_strategies:
        - !ref kong-air-key-auth#name   # resolves: same block
{% endentity_examples %}
```

Use `!lookup {id: !env SOME_ID}` only for an entity that already exists from a prior, separate apply (a prereq quickstart script, an earlier how-to) — never as a workaround for a same-doc `!ref` that won't resolve.

**An entity created via `entity_examples`/`entity_example` has no captured response.** kongctl/deck apply doesn't hand back a response body the way a raw API call does, so there's nothing to `capture:` from that step. If a later `{% konnect_api_request %}` step needs that entity's ID (for example, `/consumers/$CONSUMER_ID/credentials`), add an explicit GET step with `capture:` to look the ID up first — never reference a `$VARIABLE` that nothing in the doc actually exported. See [Extracting a generated value](#extracting-a-generated-value-capture--extract_body) for the `capture:` syntax.

## `{% validation %}` cheat sheet

Block tag, YAML body, only allowed when the page's `products` includes at least one of: `gateway`, `kic`, `ai-gateway`, `operator`, `event-gateway`, `metering-and-billing`. If the how-to's products don't qualify, flag it in the report back to the writer instead of inventing a workaround.

| id | required keys |
|---|---|
| `request-check` (default choice) | `url` |
| `unauthorized-check` | `url` |
| `rate-limit-check` | `iterations`, `url` |
| `grpc-check` | `method` |
| `custom-command` | `command`, `expected` |
| `vault-secret` | `secret`, `value` |
| `kubernetes-resource` | `kind`, `name` |
| `traffic-generator` | `iterations`, `url` |

Minimal example:

```
## Validate

{% validation request-check %}
url: /anything
status_code: 200
headers:
  - '<!-- TODO: auth header if needed -->'
{% endvalidation %}
```

### Extracting a generated value (`capture` / `extract_body`)

`{% konnect_api_request %}` and `{% validation request-check %}` both support `capture:` and
`extract_body:` on any mid-document step, not just the final Validate block. `capture:`
renders a real, copy-pasteable shell command that exports the value for the reader **and**
feeds the automated test harness — never write a manual "copy this value from the response"
instruction when this is available. Pair it with `extract_body:` when the source material
names the response field:

```
<!--vale off-->
{% konnect_api_request %}
url: /v1/some-resource
status_code: 201
method: POST
body:
  name: example
extract_body:
  - name: id
    variable: RESOURCE_ID
capture:
  - variable: RESOURCE_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->
```

This renders `RESOURCE_ID=$(curl ... | jq -r ".id")` for the reader, ready to reference as
`$RESOURCE_ID` in later steps. Use `command:` instead of `jq:` for a non-jq extraction
command. With more than one `capture` entry on the same block, it renders a shared
`_response=$(curl ...)` capture followed by one `export VAR=...` line per variable.

## kongctl / deck snippet style

Terse lead-in sentence, then a fence — no extra narration. "Preview then apply" pairing:

```
Preview the changes:

​```sh
kongctl diff --mode apply -f <file>.yaml
​```

Apply the configuration:

​```sh
kongctl apply -f <file>.yaml
​```
```

For decK: `deck gateway apply` for a quick single-entity demo step, `deck gateway sync <file>.yaml` for the full-state/production step.

## Vale

Wrap any tag block whose YAML-like content Vale will flag (field names, config values) in `<!--vale off-->` / `<!--vale on-->`:

```
<!--vale off-->
{% validation request-check %}
...
{% endvalidation %}
<!--vale on-->
```

Writers run `make vale` themselves before merge — the scaffold just needs to not generate obvious false positives.

## Placeholder conventions

- Frontmatter or config value unknown: inline `<!-- TODO: what's missing and why -->`. Never fabricate a plausible-looking value.
- Body step prose: exactly one short sentence, imperative, no elaboration. Calibration examples:
  - "Configure the plugin to route requests to the upstream model."
  - "Create a Route that matches incoming traffic for this service."
  - "Apply the configuration to your data plane."
- Never write multi-sentence explanations, rationale, or "why this matters" prose in a placeholder step — that's the writer's job.
