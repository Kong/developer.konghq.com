---
title: Set up a {{site.identity}} auth server for tiered AI budgets
permalink: /ai-gateway/set-up-kong-identity-for-tiered-ai-budgets/
content_type: how_to
description: Create a {{site.identity}} auth server with dynamic claims and per-client labels to drive tiered AI budget enforcement.

products:
  - identity
  - ai-gateway

works_on:
  - konnect

series:
  id: tiered-ai-budgets-identity-2-0
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
    Create a {{site.identity}} auth server with dynamic claims that read per-client labels, then create one client for each person or service that will call your AI Models, with the labels that determine its tier, cap, org pool, and group membership. An `openid-connect` AI Identity Provider can then project those claims onto request headers for budget enforcement.

tools:
  - konnect-api

related_resources:
  - text: "{{site.identity}}"
    url: /identity/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: AI Rate Limiting Advanced policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: Enforce tiered AI budgets on an AI Model with {{site.identity}}
    url: /ai-gateway/enforce-tiered-ai-budgets-with-kong-identity/

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
  - q: Could an external IdP like Okta drive these same four claims instead?
    a: |
      Yes, and nothing downstream would change. Kong reads `budget_tier`, `budget_cap`, `budget_org`, and `kong_groups` as header values and never sees where they came from. Okta could compute the same four claims from real group membership (`isMemberOfGroupName`) or from user profile attributes; the per-client labels used here are effectively that same attribute-driven model already, just with no group membership concept at all.
  - q: Why doesn't {{site.ai_gateway}} itself contain any tier, cap, or org logic?
    a: |
      By design. {{site.identity}} computes tier, cap, org, and entitlement class at token-issue time; Kong only ever matches the resulting header values. Anything the auth server can compute before signing arrives as a tamper-proof value Kong can act on, with no Kong object, no sync, and no drift.
  - q: Why does every claim expression end in a literal default?
    a: |
      Because a missing default doesn't fail loudly. No claim means no header, which means no rate-limiting match at all for that caller, not a soft fallback to some limit. A fail-safe policy matched on the subject header alone is worth carrying downstream precisely because of this: it bounds a caller whose claims come back missing instead of leaving them unlimited.

---

## Overview

This guide sets up the identity side of tiered AI budget enforcement: a {{site.identity}} auth server that issues each caller a token carrying its tier, individual spend cap, shared org pool, and group membership as claims. 
In the next guide in the series, you will apply tiered AI budgets on an AI Model with {{site.identity}}, then read the claims as request headers to enforce the actual budgets.

A **claim** is a piece of data included in a token when it's issued, for example a caller's tier. A **label** is a key-value tag attached directly to a client (the application or service registered with the auth server that requests tokens) when it's created. This guide defines four dynamic claims that each read one label off the requesting client at token-issue time, so one claim definition serves every client instead of needing a new claim per caller.

The following example clients illustrate the model:

* **Carol** has only the default `tier: 4x` label, the common case.
* **Dave** also has `tier: 4x`, but an additional `cap: strict` label caps his individual spend below the tier ceiling.
* **Erin** and **Frank** share an `orgUnit: live-balance` label, pooling their spend against one shared budget.
* **Grace** has a `groups: suspended` label, which blocks her from every model entirely.

{{site.ai_gateway}} reads the resulting claims purely as request headers and never sees whether they came from client labels here or, for example, real group membership in an IdP like Okta, so nothing downstream changes if you swap identity providers later.

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
  name: "Tiered AI Budgets"
  audience: "tiered-ai-budgets"
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

A client requests a token under an OAuth2 scope. Configure one now, so each client created later can be granted it and later token requests can pass `scope=budgets-access`, using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "budgets-access"
  description: "Scope for tiered AI budget clients"
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

`budget_tier` reads the client's `tier` label, defaulting to the baseline tier:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "budget_tier"
  value: '${ .Client.Labels.tier | default "baseline" }'
  include_in_token: true
  include_in_all_scopes: true
  include_in_scopes: []
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

`budget_cap` reads the client's `cap` label, defaulting to empty when no individual cap applies:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "budget_cap"
  value: '${ .Client.Labels.cap | default "" }'
  include_in_token: true
  include_in_all_scopes: true
  include_in_scopes: []
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

`budget_org` reads the client's `orgUnit` label, defaulting to unassigned:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "budget_org"
  value: '${ .Client.Labels.orgUnit | default "unassigned" }'
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
  value: '${ .Client.Labels.groups | default "" | splitList "," | compact | toJson }'
  include_in_token: true
  include_in_all_scopes: true
  include_in_scopes: []
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

Each request returns the created claim. For example, creating `budget_tier` returns:

```json
{
  "id": "8f16f156-2f83-4b76-8f00-df5301c46017",
  "name": "budget_tier",
  "value": "${ .Client.Labels.tier | default \"baseline\" }",
  "include_in_token": true,
  "include_in_all_scopes": true,
  "include_in_scopes": [],
  "enabled": true
}
```
{:.no-copy-code}

{:.info}
> **Notes:**
> * `toJson` is required here. `splitList` and `compact` turn the label's raw string into a list, but a Go template renders a list as `[suspended]`, unquoted and comma-free, which isn't valid JSON. Without `toJson`, that non-JSON text gets treated as a literal string claim instead of an array, and `consumer_groups_claim` silently fails to bind anything to it.
> * A claim referencing a label the client doesn't have at all is omitted from the token entirely, it doesn't fall through to `default`. `default` only catches an empty value, not a missing label. This applies to every claim here, not just `kong_groups`.

## Create a client for each persona

Create one client for each of the five personas introduced in the overview, using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient). Each client's `labels` drive the claims configured previously.

First, create a client for Carol:
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
  response_types:
    - none
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

Repeat for the remaining four personas, changing only `name` and `labels`.

Create a client for Dave:
<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Dave"
  grant_types:
    - client_credentials
  response_types:
    - none
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  labels:
    tier: "4x"
    cap: "strict"
extract_body:
  - name: 'client_secret'
    variable: DAVE_CLIENT_SECRET
  - name: 'id'
    variable: DAVE_CLIENT_ID
capture:
  - variable: DAVE_CLIENT_SECRET
    jq: ".client_secret"
  - variable: DAVE_CLIENT_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create a client for Erin:
<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Erin"
  grant_types:
    - client_credentials
  response_types:
    - none
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  labels:
    tier: "4x"
    orgUnit: "live-balance"
extract_body:
  - name: 'client_secret'
    variable: ERIN_CLIENT_SECRET
  - name: 'id'
    variable: ERIN_CLIENT_ID
capture:
  - variable: ERIN_CLIENT_SECRET
    jq: ".client_secret"
  - variable: ERIN_CLIENT_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create a client for Frank:
<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Frank"
  grant_types:
    - client_credentials
  response_types:
    - none
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  labels:
    tier: "4x"
    orgUnit: "live-balance"
extract_body:
  - name: 'client_secret'
    variable: FRANK_CLIENT_SECRET
  - name: 'id'
    variable: FRANK_CLIENT_ID
capture:
  - variable: FRANK_CLIENT_SECRET
    jq: ".client_secret"
  - variable: FRANK_CLIENT_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create a client for Grace:
<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Grace"
  grant_types:
    - client_credentials
  response_types:
    - none
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  labels:
    tier: "4x"
    groups: "suspended"
extract_body:
  - name: 'client_secret'
    variable: GRACE_CLIENT_SECRET
  - name: 'id'
    variable: GRACE_CLIENT_ID
capture:
  - variable: GRACE_CLIENT_SECRET
    jq: ".client_secret"
  - variable: GRACE_CLIENT_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Each client's ID and secret are now exported as `$DAVE_CLIENT_ID`/`$DAVE_CLIENT_SECRET`, `$ERIN_CLIENT_ID`/`$ERIN_CLIENT_SECRET`, `$FRANK_CLIENT_ID`/`$FRANK_CLIENT_SECRET`, and `$GRACE_CLIENT_ID`/`$GRACE_CLIENT_SECRET`, alongside Carol's.

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
  budget_tier: '${ .Client.Labels.tier | default "baseline" }'
  budget_cap: '${ .Client.Labels.cap | default "" }'
  budget_org: '${ .Client.Labels.orgUnit | default "unassigned" }'
  kong_groups: '${ .Client.Labels.groups | default "" | splitList "," | compact | toJson }'
{% endkonnect_api_request %}
<!--vale on-->

The response resolves to `budget_tier: "4x"` and `budget_cap: "strict"`. Dave has no `orgUnit` or `groups` label, so `budget_org` and `kong_groups` are absent from the response entirely rather than showing their defaults, confirming Dave gets his tier and his individual cap, but isn't part of an org pool.

You now have `$ISSUER_URL` and a `client_id`/`client_secret` pair per persona. Use these in [Enforce tiered AI budgets on an AI Model with {{site.identity}}](/ai-gateway/enforce-tiered-ai-budgets-with-kong-identity/) to project the claims onto request headers for budget enforcement.
