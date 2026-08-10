---
title: Set up a {{site.identity}} auth server for AI Agent authentication
permalink: /ai-gateway/set-up-kong-identity-for-a2a/
content_type: how_to
description: Create a {{site.identity}} auth server, scope, claim, and client to issue bearer tokens for authenticating AI Agent A2A traffic.

products:
  - identity
  - ai-gateway

works_on:
  - konnect

series:
  id: a2a-identity-2-0
  position: 1

tags:
  - ai
  - a2a
  - authentication
  - openid-connect

tldr:
  q: How do I set up {{site.identity}} to authenticate AI Agent A2A traffic?
  a: |
    Create a {{site.identity}} auth server, scope, claim, and client. The client issues bearer tokens that an `openid-connect` AI Identity Provider can validate to authenticate requests to an AI Agent.

tools:
  - konnect-api

related_resources:
  - text: "{{site.identity}}"
    url: /identity/
  - text: AI Identity Provider entity
    url: /ai-gateway/entities/ai-identity-provider/
  - text: Secure AI Agent traffic with OpenID Connect and {{site.identity}}
    url: /ai-gateway/secure-ai-agent-with-oidc/

faqs:
  - q: Can I retrieve my client's secret again?
    a: |
      No, the secret is only shared once when the client is created. Store it securely.
  - q: Can I reuse this auth server for other AI Agents, AI Models, or AI MCP Servers?
    a: |
      Yes. Create additional scopes and clients under the same auth server, or reference the same `issuer` from multiple `openid-connect` AI Identity Providers. All AI Models in the same {{site.ai_gateway}} that use OIDC must reference the same AI Identity Provider, so plan scopes accordingly if you're authenticating multiple entity types with the same auth server.

automated_tests: false

---

## Create an auth server in {{site.identity}}

Before you can authenticate AI Agent traffic, you must first create an auth server in {{site.identity}}. We recommend creating different auth servers for different environments or subsidiaries. The auth server name is unique per each organization and each {{site.konnect_short_name}} region.

Create an auth server using the [`/v1/auth-servers` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServer):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Kong Air A2A"
  audience: "http://localhost:8000/a2a"
  description: "Auth server for authenticating A2A requests to the Kong Air Flight Booking Agent"
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

Configure a scope in your auth server using the [`/v1/auth-servers/$AUTH_SERVER_ID/scopes` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerScope):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "a2a-access"
  description: "Scope for accessing the Kong Air Flight Booking Agent over A2A"
  default: false
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

## Configure the auth server with a custom claim

Configure a custom claim using the [`/v1/auth-servers/$AUTH_SERVER_ID/claims` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClaim):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "agent"
  value: kongair-flight-booking
  include_in_token: true
  include_in_all_scopes: false
  include_in_scopes:
    - $SCOPE_ID
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

You can also configure dynamic custom claims with [dynamic claim templating](/identity/#dynamic-claim-templates) to generate claims during runtime.

## Create a client in the auth server

The client is the machine-to-machine credential your AI Consumers use to obtain a bearer token. In this tutorial, {{site.konnect_short_name}} autogenerates the client ID and secret, but you can alternatively specify one yourself.

Configure the client using the [`/v1/auth-servers/$AUTH_SERVER_ID/clients` endpoint](/api/konnect/kong-identity/v1/#/operations/createAuthServerClient):

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: Kong Air A2A Client
  grant_types:
    - client_credentials
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  access_token_duration: 3600
  id_token_duration: 3600
  response_types:
    - id_token
    - token
extract_body:
  - name: 'client_secret'
    variable: CLIENT_SECRET
  - name: 'id'
    variable: CLIENT_ID
{% endkonnect_api_request %}
<!--vale on-->

Export your client secret and client ID:
```sh
export CLIENT_SECRET='YOUR-CLIENT-SECRET'
export CLIENT_ID='YOUR-CLIENT-ID'
```

You now have `$ISSUER_URL`, `$CLIENT_ID`, and `$CLIENT_SECRET` for an auth server scoped to the Kong Air Flight Booking Agent. Use these to create an AI Identity Provider and secure the agent's A2A traffic.
