---
title: Set up a {{site.identity}} auth server for tiered AI budgets
permalink: /ai-gateway/set-up-kong-identity-for-riot-budgets/
content_type: how_to
description: Create a {{site.identity}} auth server with dynamic claims and per-client labels to drive tiered AI budget enforcement.

products:
  - identity
  - ai-gateway

works_on:
  - konnect

series:
  id: riot-budgets-identity-2-0
  position: 1

tags:
  - ai
  - governance
  - authentication
  - kong-identity
  - openid-connect
  - metering

tldr:
  q: How do I issue tokens that carry tiered budget claims from {{site.identity}}?
  a: |
    Create a {{site.identity}} auth server with dynamic claims that read per-client labels, then create one client per caller with the labels that determine its tier, cap, org pool, and group membership. An `openid-connect` AI Identity Provider can then project those claims onto request headers for budget enforcement.

tools:
  - konnect-api

related_resources:
  - text: "{{site.identity}}"
    url: /identity/
  - text: AI Identity Provider entity
    url: /ai-gateway/entities/ai-identity-provider/
  - text: AI Rate Limiting Advanced policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/

faqs:
  - q: Why use labels and dynamic claims instead of one claim per persona?
    a: |
      A dynamic claim reads a label off whichever client requests the token, so one claim definition serves every client. Without labels, each new tier, cap, or org value would need its own claim and its own scope-gating logic.
  - q: Can I retrieve a client's secret again?
    a: |
      No, the secret is only shared once when the client is created. Store it securely.
  - q: Can I reuse this auth server for other AI Models, AI Agents, or AI MCP Servers?
    a: |
      Yes. Create additional clients under the same auth server for new callers, or reference the same `issuer` from multiple `openid-connect` AI Identity Providers.

automated_tests: false

---

## Create an auth server in {{site.identity}}

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Riot Budgets"
  audience: "riot-budgets"
  description: "Auth server for tiered AI budget enforcement"
extract_body:
  - name: 'id'
    variable: AUTH_SERVER_ID
  - name: 'issuer'
    variable: ISSUER_URL
capture:
  - variable: AUTH_SERVER_ID
    jq: ".id"
  - variable: ISSUER_URL
    jq: ".issuer"
{% endkonnect_api_request %}
<!--vale on-->

## Configure the auth server with a scope

Configure a default scope using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "riot-access"
  description: "Scope for Riot budget clients"
  default: true
  include_in_metadata: false
  enabled: true
extract_body:
  - name: 'id'
    variable: SCOPE_ID
capture:
  - variable: SCOPE_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Configure dynamic claims

Each claim reads a label off the requesting client and falls back to a default when the label isn't set. Create all four with the [`/v1/auth-servers/$AUTH_SERVER_ID/claims` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClaim), one request per claim.

`riot_tier` reads the client's `tier` label, defaulting to the baseline tier:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "riot_tier"
  value: '${ .Client.Labels.tier | default "baseline" }'
  include_in_token: true
  include_in_all_scopes: true
  include_in_scopes: []
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

`riot_cap` reads the client's `cap` label, defaulting to empty when no individual cap applies:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "riot_cap"
  value: '${ .Client.Labels.cap | default "" }'
  include_in_token: true
  include_in_all_scopes: true
  include_in_scopes: []
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

`riot_org` reads the client's `riotOrg` label, defaulting to unassigned:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "riot_org"
  value: '${ .Client.Labels.riotOrg | default "unassigned" }'
  include_in_token: true
  include_in_all_scopes: true
  include_in_scopes: []
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

`kong_groups` reads the client's `groups` label into a JSON array:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "kong_groups"
  value: '${ list (.Client.Labels.groups | default "") | compact }'
  include_in_token: true
  include_in_all_scopes: true
  include_in_scopes: []
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> `kong_groups` renders as a JSON array (`[]` when no `groups` label is set, `["suspended"]` when it is). `compact` drops empty entries, since label values can't contain JSON syntax like `[` or `"`.

## Create a client for each persona

Create one client per persona using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient). Each client's `labels` drive the claims configured previously.

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Carol"
  grant_types:
    - client_credentials
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  labels:
    tier: "4x"
extract_body:
  - name: 'client_secret'
    variable: CAROL_CLIENT_SECRET
  - name: 'id'
    variable: CAROL_CLIENT_ID
capture:
  - variable: CAROL_CLIENT_SECRET
    jq: ".client_secret"
  - variable: CAROL_CLIENT_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Repeat for the remaining four personas, changing only `name` and `labels`:

<!--vale off-->
{% table %}
columns:
  - title: Persona
    key: persona
  - title: Labels
    key: labels
rows:
  - persona: "Dave"
    labels: "`tier: \"4x\"`, `cap: \"strict\"`"
  - persona: "Erin"
    labels: "`tier: \"4x\"`, `riotOrg: \"live-balance\"`"
  - persona: "Frank"
    labels: "`tier: \"4x\"`, `riotOrg: \"live-balance\"`"
  - persona: "Grace"
    labels: "`tier: \"4x\"`, `groups: \"suspended\"`"
{% endtable %}
<!--vale on-->

Export each client's ID and secret the same way as Carol's, substituting the persona's name in the variable (`$DAVE_CLIENT_ID`, `$DAVE_CLIENT_SECRET`, and so on).

## Verify claim resolution before requesting tokens

Confirm each client's claims resolve as expected before using them for budget enforcement, using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients/$CLIENT_ID/test-claim` endpoint](/api/konnect/kong-identity/v1/#/operations/testClaimForClient). For example, test Dave's client:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients/$DAVE_CLIENT_ID/test-claim
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  riot_tier: '${ .Client.Labels.tier | default "baseline" }'
  riot_cap: '${ .Client.Labels.cap | default "" }'
  riot_org: '${ .Client.Labels.riotOrg | default "unassigned" }'
  kong_groups: '${ list (.Client.Labels.groups | default "") | compact }'
{% endkonnect_api_request %}
<!--vale on-->

The response resolves to `riot_tier: "4x"`, `riot_cap: "strict"`, `riot_org: "unassigned"`, and `kong_groups: []`, confirming Dave gets his tier and his individual cap, but isn't part of an org pool.

You now have `$ISSUER_URL` and a `client_id`/`client_secret` pair per persona. Use these to create an AI Identity Provider that projects the claims onto request headers for budget enforcement.
