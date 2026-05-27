---
name: kong-identity-how-to
description: >
  Write or revise Kong Identity how-to guides for developer.konghq.com. Use this skill
  any time someone asks to draft, write, create, update, or revise a how-to guide that
  involves Kong Identity — including OIDC, Upstream OAuth, OAuth Introspection, Event
  Gateway OAuth, Dev Portal DCR, or any new Kong Identity integration. Always use this
  skill before writing any Kong Identity how-to content, even if the request seems
  straightforward. Also use it when an engineer or PM shares a draft or raw configs and
  asks for help turning them into documentation.
---

Read `references/how-to-patterns.md` before doing anything else. It contains the frontmatter schema, standard structure, Liquid block syntax, shared includes, and compact summaries of the five existing how-tos. You need this context to draft correctly.

## Overview

This skill produces how-to guide files (`.md`) that follow the conventions of the Kong Identity how-tos on `developer.konghq.com`. It works for both new how-tos and revisions to existing ones.

The most important rule: **do not draft any content until you have the exact configs**. Guessed or placeholder configs waste everyone's time because the assigned writer will test end-to-end and it won't work. Env var placeholders like `$CONTROL_PLANE_ID` are fine when that value is fetched in an earlier step of the same how-to — what's not acceptable is inventing what a config field value should be.

---

## Step 1: Determine mode

Ask the user: are they writing a new how-to, or revising an existing one?

- **New**: run the full interview below before drafting anything.
- **Revision**: ask what needs to change. If the change touches any config value (a plugin field, a scope, a claim value, a client setting, a request body), require the exact value before making the edit. The same no-guessing rule applies.

---

## Step 2: Identify the how-to type

Determine which product and plugin or feature combination this covers:

- Gateway + OIDC plugin
- Gateway + Upstream OAuth plugin
- Gateway + OAuth 2.0 Introspection plugin
- Event Gateway + OAuth
- Dev Portal + DCR
- Something new (treat it like a new how-to; the interview still applies)

The how-to type determines which shared includes apply and how the validation step is inferred. See `references/how-to-patterns.md` for the structural pattern for each type.

---

## Step 3: Interview — do not skip, do not draft until complete

Work through these questions in order. Wait for the user's answers before moving on. If a question doesn't apply based on a previous answer, skip it.

### 3a. Directory and principal prereq

Ask: Does the user have the steps for creating a Kong Identity directory and principal, or will a tech writer create the prereq include separately?

- If the user has the steps, ask for the exact API request bodies so you can verify correctness.
- If a writer will create the include, note this clearly in your pre-draft summary and leave a comment in the draft: `{% include prereqs/kong-identity-directory-principal %}` — the writer will create this file.

### 3b. Auth server, scope, claim, and client setup

Ask: Does this how-to require Kong Identity auth server, scope, claim, and client configuration to work?

Most how-tos do (the OIDC, Upstream OAuth, OAuth Introspection, and Event Gateway ones all use the shared `konnect-identity-server-scope-claim-client.md` include). Dev Portal DCR creates the auth server inline with a different purpose. If unsure, ask.

If yes, ask:
- Auth server: exact `name`, `audience`, and `description` values
- Scope: exact `name`, `description`, `default`, `include_in_metadata`, `enabled` values
- Claim: exact `name`, `value`, `include_in_token`, `include_in_all_scopes`, `include_in_scopes` values — or confirm no custom claim is needed
- Client: exact `grant_types`, `allow_scopes`, `access_token_duration`, `response_types` values

If any of these differ from what the shared include uses (for example, a different grant type or additional claim fields), note the differences and ask for the exact values.

### 3c. Plugin or product config

Ask for the exact configuration for the plugin or product being set up. Accept:
- A curl command (you'll convert it to a `konnect_api_request` block)
- A YAML/JSON snippet (you'll convert it to an `entity_examples` or `konnect_api_request` block)
- A decK config (use as-is in an `entity_examples` block)

Env var placeholders like `$CONTROL_PLANE_ID`, `$ISSUER_URL`, `$CLIENT_ID` are fine when those variables are exported in earlier steps of the same how-to.

Do not accept: vague descriptions ("configure the OIDC plugin with the usual settings"), partial configs ("just the important fields"), or anything that requires you to guess a value.

### 3d. Any steps unique to this how-to type

Ask: Are there any steps beyond the standard Kong Identity setup that this how-to needs?

Examples:
- OIDC: any authorization server config beyond what the shared include covers
- Event Gateway: virtual cluster config, listener, listener policy, ACL policy
- Dev Portal DCR: DCR provider config, auth strategy config, linking to a published API

For each additional step, require the exact API request body or UI steps.

### 3e. Pre-draft confirmation

Before drafting, summarize what you collected and flag anything still missing:

```
Here's what I have:
- ✅ Directory/principal prereq: [have steps / writer will create include]
- ✅ Auth server, scope, claim, client: [using shared include / custom values listed]
- ✅ Plugin config: [summary of key fields]
- ✅ Additional steps: [list or "none"]
- ⚠️ Still missing: [anything you don't have]
```

Only proceed to drafting when the user confirms everything is present.

---

## Step 4: Draft the how-to

### Structure

Follow this order (see `references/how-to-patterns.md` for full frontmatter schema and Liquid block examples):

```
[frontmatter]

[prereqs block]
  - Directory and principal (include or placeholder)
  - example-service and example-route entities (most how-tos)
  - any product-specific prereqs (Dev Portal setup, kafkactl, etc.)

[body]
  - OIDC/Upstream OAuth/OAuth Introspection: use {% include /how-tos/steps/konnect-identity-server-scope-claim-client.md %}
  - DCR/Event Gateway: write auth server creation steps inline
  - Configure the plugin or product (exact configs from interview)
  - Generate token (use {% include /how-tos/steps/konnect-identity-generate-token.md %} or write inline)
  - Validate
```

### Validation section

Infer the validation approach from the how-to type — do not ask the user:

- **OIDC / Upstream OAuth / OAuth Introspection**: generate a client credentials token from `$ISSUER_URL/oauth/token`, make a request to the protected endpoint with `Authorization: Bearer $ACCESS_TOKEN`, expect 200. Use `{% validation request-check %}`.
- **Event Gateway OAuth**: use kafkactl to list topics with and without auth; expect the authenticated context to return topics and the unauthenticated context to return empty. Use `{% validation custom-command %}`.
- **Dev Portal DCR**: navigate to the Dev Portal, create an application, copy the client ID and secret, generate a token, make an authorized API request. Use a mix of steps and `{% validation request-check %}`.

### Liquid block conversion

When the user provides curl or YAML, convert to the appropriate block:

- Konnect API call → `{% konnect_api_request %}` block (add `capture:` for any IDs or URLs you'll need later)
- Plugin config → `{% entity_examples %}` block with `formats: [deck]`
- Final auth validation request → `{% validation request-check %}` block
- Shell commands → `{% validation custom-command %}` block or a fenced `bash` code block

Wrap blocks that contain field names or values that Vale will flag with `<!--vale off-->` / `<!--vale on-->`. See `references/how-to-patterns.md` for complete syntax examples.

### Style rules to enforce (don't explain to the user — just apply them)

- Sentence case for all headings (capitalize only first word and proper nouns)
- Export env vars for any value referenced in a later step
- Active voice
- No em dashes — use a comma, parentheses, or a period instead
- `{:.no-copy-code}` directly under any expected-output code block
- No screenshots of third-party UIs
- Link text should describe the destination, not say "click here"

---

## For revisions

When revising an existing how-to:

1. Read the existing file before suggesting any changes.
2. Ask what specifically needs to change.
3. If the change involves a config value (plugin field, scope, claim, client setting, request body), require the exact value before editing.
4. If the change is structural (adding a section, reordering steps, updating prose), you can proceed without additional configs — but still follow the style rules above.
5. Preserve any `include` calls and shared block patterns that already exist in the file.
