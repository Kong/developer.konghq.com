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

automated_tests: false

---

## Overview

{{site.identity}} has no group-membership concept, so this guide drives all four claims from per-client labels: a label stands in for what a group membership would represent with a different IdP. `budget_tier`, `budget_cap`, and `budget_org` each read one label with a literal default; `kong_groups` reads a `groups` label into an array for ACL matching. {{site.ai_gateway}} reads the resulting claims as header values and never sees how they were computed, so nothing downstream changes if you later drive the same four claims from an IdP that does have groups, like Okta.

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

Configure a default scope using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

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

Each claim reads a label off the requesting client and falls back to a default when the label isn't set:

<!-- vale off -->
{% table %}
columns:
  - title: Claim
    key: claim
  - title: Label
    key: label
  - title: Default
    key: default
  - title: Notes
    key: notes
rows:
  - claim: "`budget_tier`"
    label: "`tier`"
    default: "`baseline`"
    notes: "—"
  - claim: "`budget_cap`"
    label: "`cap`"
    default: "empty"
    notes: "—"
  - claim: "`budget_org`"
    label: "`orgUnit`"
    default: "`unassigned`"
    notes: "—"
  - claim: "`kong_groups`"
    label: "`groups`"
    default: "empty array"
    notes: "Converted to a JSON array for `consumer_groups_claim`"
{% endtable %}
<!-- vale on -->

Create all four with a reusable function:

<!--vale off-->
```sh
create_claim() {
  local name="$1" value="$2"
  local body
  body=$(jq -n --arg name "$name" --arg value "$value" \
    '{name: $name, value: $value, include_in_token: true, include_in_all_scopes: true, include_in_scopes: [], enabled: true}')
  curl -s -X POST "https://us.api.konghq.com/v1/auth-servers/$AUTH_SERVER_ID/claims" \
    -H "Authorization: Bearer $KONNECT_TOKEN" \
    -H "Content-Type: application/json" \
    --data "$body" | jq -c '{id, name}'
}

create_claim "budget_tier"  '${ .Client.Labels.tier | default "baseline" }'
create_claim "budget_cap"   '${ .Client.Labels.cap | default "" }'
create_claim "budget_org"   '${ .Client.Labels.orgUnit | default "unassigned" }'
create_claim "kong_groups"  '${ .Client.Labels.groups | default "" | splitList "," | compact | toJson }'
```
<!--vale on-->

{:.info}
> `toJson` is required here. `splitList` and `compact` turn the label's raw string into a list, but a Go template renders a list as `[suspended]`, unquoted and comma-free, which isn't valid JSON. Without `toJson`, that non-JSON text gets treated as a literal string claim instead of an array, and `consumer_groups_claim` silently fails to bind anything to it.

{:.info}
> A claim referencing a label the client doesn't have at all is omitted from the token entirely, it doesn't fall through to `default`. `default` only catches an empty value, not a missing label. This applies to every claim here, not just `kong_groups`.

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

Repeat for the remaining four personas with a reusable function instead of four more requests. Paste the whole block, the function definition and all four calls, into your shell at once. Client names must be unique per auth server, so rerunning this with a name that already exists fails with `409 Resource Conflict`:

<!--vale off-->
```sh
create_client() {
  local name="$1" labels="$2"
  response=$(curl -s -X POST "https://us.api.konghq.com/v1/auth-servers/$AUTH_SERVER_ID/clients" \
    -H "Authorization: Bearer $KONNECT_TOKEN" \
    -H "Content-Type: application/json" \
    --json "{
      \"name\": \"$name\",
      \"grant_types\": [\"client_credentials\"],
      \"response_types\": [\"none\"],
      \"allow_all_scopes\": false,
      \"allow_scopes\": [\"$SCOPE_ID\"],
      \"labels\": $labels
    }")
  local id secret
  id=$(echo "$response" | jq -r '.id // empty')
  secret=$(echo "$response" | jq -r '.client_secret // empty')
  if [ -z "$id" ] || [ -z "$secret" ]; then
    echo "Failed to create client \"$name\": $response" >&2
    return 1
  fi
  upper=$(echo "$name" | tr a-z A-Z)
  export "${upper}_CLIENT_ID=$id"
  export "${upper}_CLIENT_SECRET=$secret"
}

create_client "Dave"  '{"tier": "4x", "cap": "strict"}'
create_client "Erin"  '{"tier": "4x", "orgUnit": "live-balance"}'
create_client "Frank" '{"tier": "4x", "orgUnit": "live-balance"}'
create_client "Grace" '{"tier": "4x", "groups": "suspended"}'
```
<!--vale on-->

Each client's ID and secret are now exported as `$DAVE_CLIENT_ID`/`$DAVE_CLIENT_SECRET`, `$ERIN_CLIENT_ID`/`$ERIN_CLIENT_SECRET`, `$FRANK_CLIENT_ID`/`$FRANK_CLIENT_SECRET`, and `$GRACE_CLIENT_ID`/`$GRACE_CLIENT_SECRET`, alongside Carol's. `create_client` is reusable beyond these four: add another persona later with one more call.

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
