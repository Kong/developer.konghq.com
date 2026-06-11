# Kong Identity how-to patterns

Reference for the `kong-identity-how-to` skill. Contains the frontmatter schema, standard structure, Liquid block syntax, shared includes, and compact summaries of the five existing how-tos.

---

## Frontmatter schema (how-to)

Required fields:

```yaml
---
title: Configure the [Plugin Name] plugin with Kong Identity   # sentence case, descriptive
content_type: how_to
permalink: /how-to/configure-kong-identity-[slug]/
breadcrumbs:
  - /kong-identity/
description: Learn how to configure Kong Identity with [feature].

entities:
  - route
  - service
  - plugin

plugins:
  - plugin-slug   # omit for non-plugin how-tos

products:
  - gateway       # or event-gateway, dev-portal — first item sets the product index

works_on:
  - konnect

tags:
  - authentication

tools:
  - deck
  # - konnect-api  # uncomment if the how-to uses the Konnect API directly in body steps

tldr:
  q: How do I configure Kong Identity with [feature]?
  a: |
    [One or two sentences. Mention the key steps: create auth server + configure plugin + test.]

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Kong Identity directory
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/kong-identity.svg

faqs:
  - q: Can I retrieve my client's secret again?
    a: |
      No, the secret is only shared once when the client is created. Store it securely.

automated_tests: false    # always false for Kong Identity how-tos currently

related_resources:
  - text: Kong Identity
    url: /kong-identity/
  - text: Dynamic claim templating
    url: /kong-identity/#dynamic-claim-templates
---
```

Notes:
- `automated_tests: false` is correct for all current Kong Identity how-tos.
- `works_on: [konnect]` only — these don't support on-prem.
- Add `min_version: gateway: '3.x'` if the feature requires a specific Gateway version.
- For Dev Portal how-tos, add `- dev-portal` to `products:`.
- For Event Gateway how-tos, use `products: [event-gateway]`, remove `entities:` and `plugins:`.

---

## Standard how-to structure

### Gateway plugin how-tos (OIDC, Upstream OAuth, OAuth Introspection)

```
[frontmatter]

{% include /how-tos/steps/konnect-identity-server-scope-claim-client.md %}

## Create a principal  ← include only if this how-to uses a principal

{% konnect_api_request %} POST /v2/directories/$DIRECTORY_ID/principals {% endkonnect_api_request %}

## Create an identity for the principal  ← type depends on how-to (oidc, custom, etc.)

{% konnect_api_request %} POST /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities {% endkonnect_api_request %}

## Create credentials  ← only if the principal authenticates directly

{% konnect_api_request %} POST /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/basic-auths {% endkonnect_api_request %}
  or
{% konnect_api_request %} POST /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/api-keys {% endkonnect_api_request %}

## Configure the [Plugin Name] plugin

Get the control plane ID:
{% konnect_api_request %} GET /v2/control-planes?filter[name][contains]=quickstart {% endkonnect_api_request %}
export CONTROL_PLANE_ID='YOUR-CONTROL-PLANE-ID'

Enable the plugin globally:
{% konnect_api_request %} POST /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/ {% endkonnect_api_request %}

{% include /how-tos/steps/konnect-identity-generate-token.md %}

## Access the Gateway Service using the token
{% validation request-check %} ... {% endvalidation %}
```

### Event Gateway how-tos (OAuth, metadata integration, etc.)

```
[frontmatter with products: [event-gateway]]

## Create an auth server in Kong Identity  ← for OAuth flows; omit for principal-only flows
{% konnect_api_request %} POST /v1/auth-servers {% endkonnect_api_request %}
{% konnect_api_request %} POST /v1/auth-servers/$AUTH_SERVER_ID/scopes {% endkonnect_api_request %}
{% konnect_api_request %} POST /v1/auth-servers/$AUTH_SERVER_ID/claims {% endkonnect_api_request %}
{% konnect_api_request %} POST /v1/auth-servers/$AUTH_SERVER_ID/clients {% endkonnect_api_request %}

## Create a principal  ← if this how-to uses principals
{% konnect_api_request %} POST /v2/directories/$DIRECTORY_ID/principals {% endkonnect_api_request %}

## Create an identity for the principal
{% konnect_api_request %} POST /v2/directories/$DIRECTORY_ID/principals/$PRINCIPAL_ID/identities {% endkonnect_api_request %}

## [Event Gateway setup: backend cluster, virtual cluster, listener, listener policy, ACL/other policies]

## Configure kafkactl
{% validation custom-command %} ... {% endvalidation %}

## Validate
### [Authenticated access]
### [Unauthenticated access, if applicable]
```

### Dev Portal DCR

```
[frontmatter with products: [gateway, dev-portal]]

## Create an auth server in Kong Identity
{% konnect_api_request %} POST /v1/auth-servers {% endkonnect_api_request %}

## Configure the Kong Identity Dynamic Client Registration in Dev Portal
[UI steps — numbered list]

## Apply the auth strategy to an API
[UI steps — numbered list]

## Validate
[UI steps: navigate to Dev Portal, create app, generate token, make authorized request]
```

---

## Liquid block syntax

### konnect_api_request

Use for all Konnect API calls. Wrap with `<!--vale off-->` / `<!--vale on-->`.

```
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: openid-connect
  config:
    issuer: $ISSUER_URL
    auth_methods:
    - bearer
    audience:
    - http://myhttpbin.dev
capture:
  - variable: PLUGIN_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->
```

Use `capture:` to extract values (IDs, URLs) needed in later steps. Use `status_code:` matching the expected response (200 for GET, 201 for POST).

### entity_examples (plugin config via decK)

Use when the how-to specifies plugin config via decK. Do not wrap with vale comments.

```
{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      config:
        issuer: $ISSUER_URL
        auth_methods:
          - bearer
        audience:
          - http://myhttpbin.dev
formats:
  - deck
{% endentity_examples %}
```

### validation request-check

Use as the final validation step for Gateway how-tos.

```
{% validation request-check %}
url: /anything
method: GET
status_code: 200
display_headers: true
headers:
  - "Authorization: Bearer $ACCESS_TOKEN"
{% endvalidation %}
```

### validation custom-command

Use for shell command validation (Event Gateway kafkactl, etc.).

```
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context vc-oauth list topics
expected:
  return_code: 0
  message: |
    TOPIC              PARTITIONS     REPLICATION FACTOR
    products-topic     1              1
render_output: false
{% endvalidation %}
```

### Export code blocks

Export env vars immediately after any step that returns an ID, URL, or secret.

```sh
export AUTH_SERVER_ID='YOUR-AUTH-SERVER-ID'
export ISSUER_URL='YOUR-ISSUER-URL'
```

After a step that uses `capture:` in the `konnect_api_request` block, the variable is captured automatically — no manual export step needed.

---

## Shared includes and when to use them

| Include path | What it contains | When to use |
|---|---|---|
| `prereqs/kong-identity-directory` | Creates a directory; exports `DIRECTORY_ID` | All Kong Identity how-tos as a prereq |
| `/how-tos/steps/konnect-identity-server-scope-claim-client.md` | Creates auth server, scope, claim, and client; exports `AUTH_SERVER_ID`, `ISSUER_URL`, `CLIENT_ID`, `CLIENT_SECRET` | Gateway plugin how-tos that use an OAuth flow (OIDC, Upstream OAuth, OAuth Introspection) |
| `/how-tos/steps/konnect-identity-generate-token.md` | Generates a client credentials token; exports `ACCESS_TOKEN` | Gateway plugin how-tos, after plugin is configured |

Principal creation always goes in the how-to body, not in a shared include, because the principal's identity type, metadata, and credentials vary between how-tos.

Event Gateway and Dev Portal DCR how-tos write their auth server creation steps inline rather than using the shared include, because they need different request bodies or additional capture fields.

---

## Existing how-to summaries

### 1. Configure the OIDC plugin with Kong Identity
**File:** `app/_how-tos/gateway/configure-kong-identity-oidc.md`
**Plugin:** `openid-connect`
**What makes it distinct:** Uses the shared `konnect-identity-server-scope-claim-client.md` include. Plugin config: `issuer: $ISSUER_URL`, `auth_methods: [bearer]`, `audience: [http://myhttpbin.dev]`. Applied globally to the control plane. Validation: generate token, make authenticated request, expect 200.
**Key config fields:** `issuer`, `auth_methods`, `audience`

### 2. Configure the Upstream OAuth plugin with Kong Identity
**File:** `app/_how-tos/gateway/configure-kong-identity-upstream-oauth.md`
**Plugin:** `upstream-oauth`
**What makes it distinct:** Uses the shared include. Plugin config passes `oauth.token_endpoint`, `oauth.grant_type`, `oauth.client_id`, `oauth.client_secret`, `oauth.scopes`, and `behavior.upstream_access_token_header_name`. The plugin fetches the token on behalf of the upstream — different from OIDC which validates an inbound token.
**Key config fields:** `oauth.token_endpoint`, `oauth.grant_type`, `oauth.client_id`, `oauth.client_secret`, `oauth.scopes`, `behavior.upstream_access_token_header_name`

### 3. Configure the OAuth 2.0 Introspection plugin with Kong Identity
**File:** `app/_how-tos/gateway/configure-kong-identity-oauth-introspection.md`
**Plugin:** `oauth2-introspection`
**What makes it distinct:** Uses the shared include. Requires Base64-encoding the client ID and secret before configuring the plugin (`echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64`). Plugin config: `introspection_url: $ISSUER_URL/introspect`, `authorization_value: Basic $ENCODED_CREDENTIALS`, `consumer_by: client_id`, `custom_claims_forward: [Claim]`.
**Key config fields:** `introspection_url`, `authorization_value`, `consumer_by`, `custom_claims_forward`

### 4. Set up Event Gateway with Kong Identity OAuth
**File:** `app/_how-tos/event-gateway/kong-identity-oauth.md`
**What makes it distinct:** No shared include — writes auth server, scope, claim, and client steps inline (identical API calls but with `capture:` blocks to extract IDs). Additional steps: create backend cluster, virtual cluster (with JWKS endpoint from `$ISSUER_URL/.well-known/jwks`), listener, listener policy, ACL policy using `topic_prefix` claim. Validation uses kafkactl with and without OAuth context.
**Prereqs:** Install kafkactl (version ≥ 5.17.0), start local Kafka cluster via docker-compose.

### 5. Automatically create Dev Portal applications with Kong Identity DCR
**File:** `app/_how-tos/dev-portal/kong-identity-dcr.md`
**What makes it distinct:** Does not use the shared gateway plugin include. Creates an auth server for DCR purposes (different audience/purpose). Dev Portal configuration is done via the Konnect UI (not API): create DCR provider, create auth strategy, apply strategy to a published API. Prereqs are extensive (create portal, configure security settings, publish API, create developer account). Validation is UI-based (create DCR app as a developer, generate token, make authorized request).
**Key difference from gateway how-tos:** No `entity_examples` or plugin config blocks — this is entirely UI steps + one `konnect_api_request` for the auth server.

---

## Style reminders specific to Kong Identity how-tos

- Section headings use sentence case: "Configure the OIDC plugin", not "Configure The OIDC Plugin"
- Export env vars immediately after any step that returns a value used later: `export CLIENT_SECRET='YOUR-CLIENT-SECRET'`
- Warn users once that the client secret is shown only once: use the existing FAQ `faqs: - q: Can I retrieve my client's secret again?`
- When introducing an auth server, note: "We recommend creating different auth servers for different environments or subsidiaries. The auth server name is unique per each organization and each Konnect region."
- Link to the Kong Identity API reference when introducing an API endpoint for the first time: `[/v1/auth-servers endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer)`
- No em dashes anywhere — rephrase with a comma, parentheses, or a period
- `{:.no-copy-code}` under any code block showing expected output the user won't copy
