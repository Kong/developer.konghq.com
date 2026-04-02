---
name: write-how-to
description: >
  Fallback skill for writing or editing how-to guides on developer.konghq.com when no
  product-specific skill exists. Covers all products and guide types under app/_how-tos/.
  Before using this skill, check whether a product-specific skill exists for the guide's
  primary product (for example, ai-gateway-how-to-author for AI Gateway guides). Use this
  skill only when no product-specific skill applies.
argument-hint: <topic-description>
---

# How-To Guide Contributor

You help contributors write and edit how-to guides for developer.konghq.com. Guides live under
`app/_how-tos/`, organized by primary product.

**Before starting:** Check whether a product-specific skill exists for this guide's primary
product. If one does (for example, `ai-gateway-how-to-author` for AI Gateway), use that instead.
This skill is the fallback for products and topics not covered by a dedicated skill.

**Accuracy rule, no exceptions:** If the available repository context isn't sufficient to write
accurate documentation, stop and ask the contributor for the missing information before writing
anything. Don't infer, guess, or approximate config field names, valid values, version numbers,
upstream paths, or auth formats. If the information needed to document a feature is too sparse,
ask the contributor to share design docs, PRDs, schemas, implementation PRs, or reference links before proceeding.

## Authoritative sources

- **Plugin JSON schemas:** `app/_schemas/gateway/plugins/<version>/<PluginName>.json` (use the
  highest version at or below the guide's `min_version.gateway`). These are the source of truth for
  field names, types, defaults, and valid enum values. If a schema file doesn't exist for the
  plugin being documented, stop and ask the contributor for the implementation PR or schema before
  writing any config.
- **Plugin docs and example YAMLs:** `app/_kong_plugins/<plugin-slug>/index.md` and
  `app/_kong_plugins/<plugin-slug>/examples/`. Required to confirm field names and valid values.
  Never guess plugin config fields.
- **Mesh policy docs:** `app/_mesh_policies/<policy-slug>/`. For Mesh guides, the schema path is
  `app/.repos/kuma/app/assets/`, not `app/_schemas/gateway/plugins/`.
- **Product and feature reference pages** in the repo (check `app/` for the relevant product area).
- **API specs:** `/api-specs` contains the source of truth for public APIs. If the how to is for a new feature, ask the contributor for a link to the schema with the fields.
- **Terraform resources:** If the how-to is for Terraform, the following are the source of truth for public Terraform resources: https://github.com/Kong/terraform-provider-konnect, https://github.com/Kong/terraform-provider-konnect-beta, https://github.com/Kong/terraform-provider-kong-gateway, https://github.com/Kong/terraform-provider-kong-mesh. If the how to is for a new feature, ask the contributor for a link to the Terraform resource with the updated fields. 
- **Third-party docs:** If a third-party product is involved (ex. HashiCorp Vault, Azure, AWS, Google Cloud), ask the contributor to provide a link or paste the relevant sections either of the third-party documentation and/or example configs or notes that include the third-party values.

If any of these sources are missing, incomplete, or contradictory, stop and ask.

---

## Step 1: Build context

Before writing anything, read the following:

1. **Existing guides** in the same product area of `app/_how-tos/`. Identify the body pattern,
   frontmatter structure, and validation approach used in guides similar to the one being written. Ask the contributor if they have a currently published how-to that would be similar if unsure.
2. **Plugin docs and example YAMLs** in `app/_kong_plugins/<plugin-slug>/` for every plugin the
   guide will configure. Confirm config field names and valid values.
3. **Plugin JSON schemas** in `app/_schemas/gateway/plugins/<version>/` for every plugin involved.
   Use the highest version at or below the guide's minimum Gateway version.
4. **Prereq includes** in `app/_includes/prereqs/` and cleanup includes in
   `app/_includes/cleanup/`. Check what already exists before writing new inline content.
5. **Valid tags** in `app/_data/schemas/frontmatter/tags.json`. Read the `enum` array before
   writing any tag. Don't invent tags.
6. **`app/_data/series.yml`** if the guide might be part of a series.
7. **`app/_includes/how-tos/steps/`** for reusable step templates that can be included directly.
8. **Other authoritative sources:** If the contributor provides any other authoritative sources (ex. API specs, Terraform resources, decK YAML, kongctl configuration, third-party documentation), read those.

After reading, present a summary of what you found and ask the contributor if anything is missing
or needs clarification before moving on. **Wait for explicit approval before proceeding.**

---

## Step 2: Plan

Present a plan covering:

1. **Files to create:** Every file that will be written or modified, with full paths.
2. **Section order:** The exact H2 sections the guide will contain.
3. **Scope check:** Call out anything that should be a separate guide or series rather than
   included here.
4. **Testability:** State whether `automated_tests: false` is needed and why. See the
   [Automated tests](#automated-tests) section for conditions.

**Wait for explicit contributor approval before writing any file.**

---

## Step 3: Write

Follow all conventions in this skill.

Before presenting any file, run through every checklist item at the end of this skill. Go through
each item one by one against the actual file content. Fix any item that fails before presenting.

Tell the contributor "Running checklist..." and post the full checklist with each item marked pass
or fix. Fix all failures before presenting the file.

**Hard stop after writing — go to Step 4 before doing anything else.**

---

## Step 4: Review

**Required stop. Don't skip this step.**

After writing the first draft:

1. Post a review summary listing every file created or modified with its full path.
2. List any open questions or decisions the contributor should confirm.
3. **Wait for explicit contributor approval before doing anything else.**

Don't proceed to Step 5 until the contributor explicitly approves the draft or requests changes.
"Looks good" counts as approval.

---

## Step 5: Update related docs

**Only begin this step after the contributor approves the draft in Step 4.**

Check whether other pages should link to the new guide:

- Product landing pages in `app/_landing_pages/`
- Product indices in `app/_indices`
- Feature/use case related landing pages and indices
- Related reference pages that cover the same/similar topic
- Other how-to guides in the same series or product area

---

## Style

These rules have no exceptions.

- **Contractions are fine** throughout — write naturally. The only exception is danger or
  warning contexts where a mistake could cause data loss or security issues (e.g. "do not delete
  the database").
- Replace every em-dash with a period or comma. Zero tolerance.
- No gerund-leading instructions. Never "By configuring X..." or "By doing X...".
- No corporate language: streamline, enhance, seamless, leverage, robust, cutting-edge, empower.
- No inline code comments unless the contributor explicitly requests them.
- Sentence case headings: "Configure the Rate Limiting plugin", not "Configure the Rate Limiting Plugin".
- Never skip header levels (H1 for page title only; H2 → H3, not H1 → H3).
- Relative links only for internal Kong developer docs. Never use full `https://developer.konghq.com`
  URLs in body prose.
- Imperative mood throughout: "Enable the plugin", "Export the variable", "Run the command".
- No filler intro paragraph. The body starts with the first H2. An exception to this rule is for getting started type guides. 
- After each body header, include at least a sentence about what the user will be doing in that section. Include additional sentences, especially for getting started guides, to provide context around why something is being done or what something is.
- Gateway entities are capitalized: Service, Route, Plugin, Consumer, Consumer Group, Upstream,
  Certificate, SNI, Vault, Key, Key Set.
- Cross-link every Kong product, plugin, or entity to its reference page on first use per section.
- Use site variables for product names (see `jekyll.yml` for the full list):
  - `{{site.base_gateway}}` for Kong Gateway
  - `{{site.konnect_short_name}}` for Konnect
  - `{{site.ai_gateway}}` for AI Gateway
  - `{{site.mesh_product_name}}` for Kong Mesh
  - `{{site.kic_product_name}}` for Kong Ingress Controller

---

## Frontmatter

All how-to guides share this base structure. Adjust `products`, `works_on`, `plugins`, `entities`,
`tags`, `tools`, `prereqs`, and `cleanup` based on what the guide covers. 
Use `docs/front-matter-reference.md` as the format source of truth and reference.

### Prereqs

* For Kong product prerequisites that are more than just installing the product and obtaining a service account token or personal access token, make sure to explicitly describe the steps if they are long instead of vaguely describe them in paragraph format.
* For third-party products, if they must be set up in a way specific to Kong, you must provide the step-by-step instructions for them. 
  If their set up isn't specific to Kong (for example, you need an IAM role with certain assume role permissions, but those permissions aren't Kong-specific), you don't need detailed steps, generic steps that describe what is required with a relevant link to the third-party product will suffice.
* For how-tos on Konnect, add the required teams and/or roles for the how-to to work. Source of truth for roles/teams is `api-specs/konnect/identity/v3/openapi.yaml`
* Prerequisites must contain any environment variables that are used in the body of the how-to, but aren't already set in the body. 
  For example, if you configure a third-party provider and need an API key, access key, etc. for a Kong configuration, you must add the `export VARIABLE_NAME='YOUR NAME HERE' step to the associated prereq.

### TLDR

The `tldr` frontmatter `a` portion should be written in a way that someone who is familiar with the product can read the few sentences there and know exactly what they need to do without having to read the whole how-to. 
This section is for expert users.

### Tag validation

Before writing the `tags:` field, read `app/_data/schemas/frontmatter/tags.json` and use only
values present in the `enum` array. 
If a needed tag is missing, add it to the schema file in
alphabetical order and note this in the PR.

### Series guides

A series groups related how-tos into a numbered sequence. Use a series when a single workflow
spans multiple guides that must be read in order.

1. Check `app/_data/series.yml` for an existing series. If none exists, add a new entry:
   ```yaml
   <series-id>:
     title: <Series display title>
     url: /<permalink-of-position-1-guide>/
   ```
   The `url` must point to the position 1 guide's permalink. Add entries in alphabetical order.

2. Add `series:` to each guide's frontmatter. The `id` must match the key in `series.yml` exactly.
   Positions are 1-based with no gaps.

3. Add `breadcrumbs:` to each guide if the series lives under a section other than `/how-to/`.

4. Cross-link guides within the series using `related_resources`.

---

## Body structure

Start the body directly with the first H2. No introductory paragraph unless this is a getting started style guide.

**Section order** (include only the sections that apply):

1. `## <Action verb> <entity or subject>` for body headers
1. At least one sentence that explains what the user will be doing in this section and why.
1. Ordered list of steps:
   1. If the how-to uses decK or the API, use one `{% entity_examples %}` (or `{% konnect_api_request %}`
   or `{% control_plane_request %}`) block per major entity type. Add a one-sentence intro before
   the block only when the purpose isn't obvious from the heading.
   1. If the how-to uses Terraform, use an hcl block, for example:
      ```hcl
      echo '
      terraform {
      required_providers {
          konnect = {
          source  = "kong/konnect"
          }
      }
      }

      provider "konnect" {
      server_url            = "https://us.api.konghq.com"
      }
      ' > auth.tf
      ```
   1. If the how-to uses the UI, use the `docs/ui-steps-standards.md` when formatting and writing steps.
2. Additional configuration sections — one per extra plugin or entity or when one task is complete (for example, configuring HashiCorp Vault would be one section, configuring a Vault entity for Gateway would be a different section).
3. `## How it works` — optional and very rare. Use a `{% table %}` or short paragraph only when the behavior is
   non-obvious from the config alone.
4. `## Validate` — always present, always last.

### entity_examples variable syntax

```
{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      config:
        minute: ${minute_limit}
variables:
  minute_limit:
    value: $RATE_LIMIT_MINUTE
    description: The per-minute request limit
{% endentity_examples %}
```

- Inside `{% entity_examples %}`: use `${variable_name}` placeholders in config values.
- In the `variables:` block: use `$ENV_VAR_NAME` (no `DECK_` prefix — the tag adds it internally).
- In raw YAML passed to `deck gateway apply`: use `${{ env "DECK_ENV_VAR" }}` (explicit prefix required).
  These two syntaxes are not interchangeable.
- Every raw YAML block for `deck gateway apply` must start with `_format_version: "3.0"`.
- Plugin scoping (`service:` and `route:`) goes at the plugin entry level, not inside `config:`.

### navtabs

In extremely rare cases, use `{% navtabs %}` when steps differ by deployment, OS, or tool:

```
{% navtabs "tab-group-id" %}
{% navtab "On-prem" %}
...
{% endnavtab %}
{% navtab "Konnect" %}
...
{% endnavtab %}
{% endnavtabs %}
```

In 99% of cases, instead of using nav tabs, you should create separate how-tos. 
For example, instead of creating navtabs for decK, the API, and UI, these would be three separate how-tos: one for decK, one for the API, and one for the UI.

### Deployment-specific content

Use `{% konnect %}` / `{% on_prem %}` blocks to show content only for one deployment type:

```
{% konnect %}
content: |
  Konnect-specific instructions here.
{% endkonnect %}
```

---

## Validation

The `## Validate` section is always the last section. It must prove the feature works as intended,
ideally not just confirm that a resource was created or marked as ready. For example:

- Rate limiting: send enough requests to hit the limit and confirm the 429 response.
- Authentication: send a request without credentials and confirm the 401 response.
- Transformation: inspect the transformed header or response body.

Prefer `{% validation %}` Liquid tags over raw curl. For the full list of available validation
types, check `app/_includes/how-tos/validations/`.

| Tag | When to use |
|-----|-------------|
| `{% validation request-check %}` | General HTTP assertion (status code, headers, body) |
| `{% validation rate-limit-check %}` | Rate limiting (sends N requests, expects 429) |
| `{% validation unauthorized-check %}` | Auth enforcement (expects 401 or 403) |
| `{% validation custom-command %}` | Arbitrary bash command or SDK run |
| `{% validation env-variables %}` | Verify required environment variables are set |
| `{% validation kubernetes-resource %}` | Verify a K8s resource exists |
| `{% validation kubernetes-resource-property %}` | Check a specific K8s resource property |
| `{% validation kubernetes-wait-for %}` | Wait for a K8s resource to reach a condition |
| `{% validation grpc-check %}` | gRPC service validation |
| `{% validation vault-secret %}` | Verify a secret in HashiCorp Vault |
| `{% validation traffic-generator %}` | Generate test traffic for observability guides |

When raw curl is the only option: use `--no-progress-meter --fail-with-body` and `--json` for JSON
bodies. Use `$KONNECT_PROXY_URL` (Konnect) or `http://localhost:8000` (on-prem).

Add `{:.no-copy-code}` after code blocks showing example output only.

---

## UI how-tos

If the guide includes UI steps, read `docs/ui-steps-standards.md` before writing any UI
instructions. That file defines the formatting conventions for fields, buttons, dropdowns, toggles,
checkboxes, tabs, sidebar items, and more. Follow those conventions exactly.

Set `automated_tests: false` for any guide that contains UI-only steps.

---

## Automated tests

`automated_tests` defaults to `true`. Set `automated_tests: false` when the guide:

- Contains UI-only steps with no copy-paste commands
- Requires third-party SSO, OAuth browser flow, or webhook configuration
- Requires manual browser interaction
- Requires credentials or infrastructure the test runner can't provision automatically

When `automated_tests` is `true`, all bash commands in the guide must be executable in sequence from
top to bottom.

---

## Product-specific notes

These warnings prevent common mistakes for products whose conventions differ from the standard
Gateway/decK pattern.

### KIC (Kubernetes Ingress Controller)

KIC guides use `kubectl` and Kubernetes manifests (Ingress, HTTPRoute, KongPlugin CRDs), not decK.

- Set `tools: [kic]`, not `tools: [deck]`.
- Entity configs are YAML manifests applied with `kubectl apply`, not `{% entity_examples %}` blocks.
- Use `{% validation kubernetes-resource %}` and `{% validation kubernetes-wait-for %}` for
  validation steps.
- Check `app/_includes/prereqs/` for existing KIC prereq includes before writing inline prereqs.

### Mesh

Mesh guides configure policies, not plugins.

- Policy docs live in `app/_mesh_policies/<policy-slug>/`, not `app/_kong_plugins/`.
- The policy schema path is `app/.repos/kuma/app/assets/`, not `app/_schemas/gateway/plugins/`.
- `content_type: policy` applies to Mesh policy reference pages; how-to guides still use
  `content_type: how_to`.

### Operator

Operator guides configure {{site.base_gateway}} resources via Kubernetes CRDs, not decK.

- Set `tools: [operator]`, not `tools: [deck]`.
- Check `app/_includes/prereqs/` for existing operator prereq includes.
- Use `{% validation kubernetes-resource %}` for resource verification.

---

## Checklist

Run through every item before presenting any file. Tell the contributor "Running checklist...",
then post the full list with each item marked pass or fix. Fix all failures before presenting.

**Accuracy and sources**
- [ ] Plugin JSON schema read from `app/_schemas/gateway/plugins/<version>/` for every plugin
  configured. If absent, contributor was asked for the schema or implementation PR before writing
  any config.
- [ ] Plugin docs and example YAMLs read to confirm field names and valid values. Nothing was
  inferred or guessed.
- [ ] Mesh policy schema read from `app/.repos/kuma/app/assets/` for Mesh guides (if applicable).
- [ ] Third-party docs or product reference confirmed, or contributor asked to supply them.
- [ ] For API how-tos, API docs read, or contributor asked to supply them.
- [ ] For Terraform how-tos, Terraform resources read, or contributor asked to supply them.
- [ ] For UI how-tos, screenshots or rough field steps are read, or contributor asked to supply them.
- [ ] For decK how-tos for entities other than plugins, YAML configurations are read or contributor asked to supply them.

**Workflow**
- [ ] Step 1 complete: existing guides, plugin docs, schemas, prereqs, tags.json, and series.yml read.
  Summary presented and contributor approved.
- [ ] Step 2 complete: plan presented and contributor approved before writing started.
- [ ] Step 3 complete: draft written and checklist run through.
- [ ] Step 4 complete: stopped after writing, review summary posted, waiting for contributor approval.
- [ ] Step 5 complete: related pages checked for cross-links only after contributor approval.

**Frontmatter**
- [ ] `content_type: how_to` present.
- [ ] `permalink` present and matches the file slug exactly.
- [ ] `products` is correct for the guide's scope.
- [ ] `works_on` present when `products` includes `gateway`.
- [ ] `tldr.q` and `tldr.a` both present and accurate.
- [ ] All tags verified against `app/_data/schemas/frontmatter/tags.json`. Missing tags added to
  schema in alphabetical order.
- [ ] `min_version` confirmed from plugin docs, schema, or contributor — not guessed.
- [ ] `plugins` lists every plugin the guide configures.
- [ ] `entities` lists every gateway entity type created or referenced.
- [ ] `automated_tests: false` set when the guide contains UI-only, SSO, webhook, or
  unprovisionable steps.
- [ ] Cleanup block present when guide creates gateway entities or infrastructure.
- [ ] Series: `series.id` matches key in `series.yml` exactly; positions are 1-based with no gaps.
- [ ] `prereqs.entities` included only when a pre-existing entities are required.

**Body**
- [ ] No filler intro paragraph except for getting started guides — body starts with the first H2.
- [ ] `{% entity_examples %}` config uses `${variable_name}` placeholders; `variables.value` uses
  `$VAR` (no `DECK_` prefix).
- [ ] Raw `deck gateway apply` blocks use `${{ env "DECK_..." }}` syntax.
- [ ] Every `${variable}` placeholder has a matching `variables:` entry.
- [ ] `{% validation %}` tags used instead of raw curl wherever applicable.
- [ ] Validation proves the feature works, not just that a resource was created.
- [ ] `{:.no-copy-code}` applied after code blocks showing example output only.
- [ ] UI steps follow `docs/ui-steps-standards.md` conventions.
- [ ] KIC guides use kubectl/manifest patterns, not `{% entity_examples %}`.
- [ ] Mesh guides use policy docs and schema, not plugin docs.

**Style**
- [ ] No em-dashes anywhere in the file.
- [ ] No gerund-leading sentences.
- [ ] No corporate language.
- [ ] Sentence case on all headings.
- [ ] Imperative mood throughout.
- [ ] Contractions used naturally; avoided only in danger/warning contexts.
- [ ] Site variables used for product names (e.g. `{{site.base_gateway}}`).
- [ ] Gateway entities capitalized (Service, Route, Plugin, Consumer, Vault, etc.).
- [ ] Kong products and plugins cross-linked on first use per section.
- [ ] Relative links only — no full `https://developer.konghq.com` URLs in body prose.
