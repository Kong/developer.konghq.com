---
title: Restrict a destructive MCP tool to agents your security team approved
permalink: /ai-gateway/restrict-mcp-tools-to-approved-agents/
content_type: how_to
description: Gate an MCP tool on two identities at once, the user the request is made for and the agent making it, so an approved user working through an unapproved agent is rejected.

products:
  - ai-gateway
  - identity

works_on:
  - konnect

min_version:
  ai-gateway: '2.4'

entities:
  - ai-auth-strategy
  - ai-mcp-server
  - principal

tags:
  - ai
  - mcp
  - authorization
  - kong-identity
  - openid-connect
tools:
  - konnect-api

automated_tests: false

tldr:
  q: How do I stop an approved user's unapproved agent from calling a destructive MCP tool?
  a: |
    Configure `config.principals.actors` on an OpenID Connect [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) so that {{site.ai_gateway}} resolves the agent making the request as a {{site.identity}} [principal](/identity/principals/), alongside the user the request is made for.
    Then write a per-tool [CEL-based ACL](/ai-gateway/entities/ai-mcp-server/#cel-based-acls) on the [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) that requires both: the user in a group, and the agent.
    A request that satisfies only one of the two is rejected with a `403`.

prereqs:
  inline:
    - title: Petstore API
      include_content: prereqs/third-party/swagger-petstore
    - title: Keycloak with a user and agent clients
      include_content: prereqs/auth/oidc/keycloak-delegated-agents
      icon_url: /assets/icons/keycloak.svg
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg

cleanup:
  inline:
    - title: Stop Petstore API
      include_content: cleanup/third-party/swagger-petstore
    - title: Destroy the Keycloak container
      include_content: cleanup/third-party/keycloak
      icon_url: /assets/icons/keycloak.svg
    - title: Clean up {{site.identity}} resources
      include_content: md/identity/delete_directory
      icon_url: /assets/icons/identity.svg
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: '/assets/icons/ai-gateway.svg'

related_resources:
  - text: Actors in the OpenID Connect AI Auth Strategy
    url: /ai-gateway/openid-connect/#actors
  - text: AI Policy conditions
    url: /ai-gateway/conditions/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: Control MCP tool access with AI Consumer and AI Consumer Group ACLs
    url: /ai-gateway/use-access-controls-for-mcp-tools/
---


An agent that acts on a user's behalf inherits everything that user can do.
If a user can delete records, so can any agent presenting a token issued for them, including one nobody reviewed.

In this guide you'll make a destructive MCP tool require two things at once:

* The request is made for a user in the `engineering` group.
* The request is made by an agent your security team marked as approved.

Every other tool stays available to anyone in `engineering`.

You'll create three principals: a user, an approved agent, and an unapproved one.
The AI Auth Strategy resolves the user from the token's `sub` claim and the agent from its `azp` claim, and a per-tool CEL-based ACL checks both.

<!--vale off-->
{% comment %}
TODO (actors, AI Gateway 2.4): two things in this guide need confirming on the
RC before it publishes.

1. The ACL expression. The per-tool allow_when below uses exists() and reads
   actors[0]. AI Policy conditions reject exists(), size(), all(), default(),
   and list indexing (see "Differences from Kong Gateway plugin conditions" in
   app/ai-gateway/conditions.md). The merged ACL schema tests in
   Kong/kong-ee#24739 accept both forms for allow_when/deny_when, but that's
   the Gateway ACL plugin, not Konnect's validation of access.acls. If Konnect
   rejects the expression with a 400, the whole premise of this guide needs
   rethinking, because a two-party rule can't be written without reaching into
   the list. Raise it with the AI Gateway team before rewriting.

2. Token acquisition. This guide assumes an OIDC provider that issues a token
   whose sub identifies the user and whose azp identifies the agent's client,
   and leaves getting that token to the reader. That was deliberate: a Kong
   Identity auth server client_credentials token sets sub to the client
   itself, not to a user, so it can't demonstrate delegation on its own.
   Confirm what can actually mint a delegated token against the RC, then
   replace the placeholder token variables in the Validate section with real
   steps. Options worth testing, in order of preference: Kong Identity auth
   code flow, Keycloak with
   --features=token-exchange-delegation.

   The act_chain source is deliberately not used here for the same reason:
   Keycloak's standard token exchange emits no act claim, and nested act
   support is still an open question in the ERD. If the RC turns out to issue
   nested act claims cleanly, an act_chain variant is a better demo than azp,
   because it shows the full chain rather than one client.
{% endcomment %}
<!--vale on-->

## Create the principals

1. Create a principal for the user:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "dana"
  description: "An engineer who works through an AI agent"
extract_body:
  - name: 'id'
    variable: USER_PRINCIPAL_ID
capture:
  - variable: USER_PRINCIPAL_ID
    jq: ".id"
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

1. Create a principal for the agent the security team approved.
   The `secops_approved` metadata value is what the ACL checks, so the approval lives on the agent's identity rather than in the rule:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "support-agent"
  description: "An agent reviewed and approved by the security team"
  metadata:
    secops_approved: "true"
extract_body:
  - name: 'id'
    variable: APPROVED_AGENT_ID
capture:
  - variable: APPROVED_AGENT_ID
    jq: ".id"
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

1. Create a second agent principal without that metadata.
   This one stands in for an agent that's registered and legitimate, but hasn't been reviewed:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "prototype-agent"
  description: "An agent that has not been reviewed"
extract_body:
  - name: 'id'
    variable: UNAPPROVED_AGENT_ID
capture:
  - variable: UNAPPROVED_AGENT_ID
    jq: ".id"
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

## Link each principal to a token claim

{{site.ai_gateway}} resolves a principal by matching a claim in the verified token against an identity on the principal.
Add an OIDC identity to each one, using the issuer of the provider that signs your tokens.

1. Link the user to the `sub` claim:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$USER_PRINCIPAL_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: oidc
  issuer: $ISSUER
  claim:
    name: sub
    value: $USER_SUBJECT
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

1. Link the approved agent to the `azp` claim, using the OAuth client ID that the agent authenticates with.
   The claim name has to match the source you configure on the AI Auth Strategy, which is `azp` in this guide:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$APPROVED_AGENT_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: oidc
  issuer: $ISSUER
  claim:
    name: azp
    value: $APPROVED_AGENT_CLIENT_ID
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

1. Link the unapproved agent to the same claim, using its own client ID:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$UNAPPROVED_AGENT_ID/identities
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: oidc
  issuer: $ISSUER
  claim:
    name: azp
    value: $UNAPPROVED_AGENT_CLIENT_ID
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

## Create the group and add the user

1. Create the `engineering` group, which is what the default ACL on the AI MCP Server checks:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: engineering
  description: "Engineers who can reach the Petstore tools"
extract_body:
  - name: 'id'
    variable: GROUP_ID
capture:
  - variable: GROUP_ID
    jq: ".id"
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

1. Add the user, and only the user.
   The agents are actors, not members: an actor never inherits the subject's group membership, and nothing resolves the two identities into one:
   <!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups/$GROUP_ID/membership
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  member:
    id: $USER_PRINCIPAL_ID
    type: principal
indent: 3
{% endkonnect_api_request %}
   <!--vale on-->

## Get the directory name

The AI Auth Strategy references the directory by name:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 200
method: GET
extract_body:
  - name: 'data.0.name'
    variable: DIRECTORY_NAME
capture:
  - variable: DIRECTORY_NAME
    jq: ".data[0].name"
{% endkonnect_api_request %}
<!--vale on-->

## Create the AI Auth Strategy

The AI Auth Strategy is what makes the agent visible to the ACL.
It resolves the user from the token, and then resolves the agent as a second identity in the same directory.

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: delegated-oidc
  display_name: Delegated OIDC
  type: openid-connect
  config:
    issuer: $ISSUER
    using_pseudo_issuer: true
    jwks_endpoint: $JWKS_ENDPOINT
    token_endpoint: $TOKEN_ENDPOINT
    client_id:
      - $CLIENT_ID
    client_secret:
      - $CLIENT_SECRET
    auth_methods:
      - bearer
    cache_tokens_salt: delegated-oidc-salt
    principals:
      enabled: true
      directory: $DIRECTORY_NAME
      error_on_miss: true
      actors:
        enabled: true
        sources:
          - type: claim
            claim:
              - azp
{% endkonnect_api_request %}
<!--vale on-->

In this example:
* `config.principals.enabled`: Resolves the subject from `sub`, as principal mapping does.
* `config.principals.actors`: Adds the second lookup. It has one source, which reads the `azp` claim and resolves it against the same directory.
* `config.using_pseudo_issuer`, `config.jwks_endpoint`, and `config.token_endpoint`: Needed here because Keycloak runs in Docker in this tutorial. The data plane validates the `iss` claim against `config.issuer` but fetches keys over the Docker network, so the two addresses differ. Against a reachable identity provider, set `config.issuer` alone and let discovery find the endpoints.

{:.info}
> When `error_on_miss` is `true`, {{site.ai_gateway}} rejects a request whose `azp` value doesn't match a principal with a `401`, instead of allowing it through without an actor.
> Keep it on while you set this up: an unregistered agent then fails visibly, instead of a rule that stops matching for no apparent reason.

## Create the AI MCP Server

Convert the Petstore API into MCP tools, and gate `delete-pet` on both identities:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/mcp-servers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: petstore-delegated-mcp
  display_name: "Petstore API"
  type: conversion-listener
  enabled: true
  access:
    acl_attribute_type:
      - consumer
    auth_strategies:
      - delegated-oidc
    acls:
      allow_when:
        - 'principal.groups != null && principal.groups.exists(g, g.id == "$GROUP_ID")'
  config:
    url: http://host.docker.internal:8080/api/v3
    route:
      paths:
        - /petstore-delegated
    server:
      timeout: 60000
  tools:
    - name: get-pets-by-status
      description: Find pets by status
      method: GET
      path: /petstore-delegated/pet/findByStatus
      parameters:
        - name: status
          in: query
          required: true
          schema:
            type: string
            enum:
              - available
              - pending
              - sold
          description: Status value to filter pets by
    - name: delete-pet
      description: Delete a pet
      method: DELETE
      path: /petstore-delegated/pet/{petId}
      access:
        acls:
          allow_when:
            - 'principal.groups != null && principal.groups.exists(g, g.id == "$GROUP_ID") && actors != null && actors.exists(a, has(a.metadata.secops_approved) && a.metadata.secops_approved == "true")'
      parameters:
        - name: petId
          in: path
          required: true
          schema:
            type: integer
          description: ID of the pet to delete
{% endkonnect_api_request %}
<!--vale on-->

In this example:
* `access.acls.allow_when`: The default ACL for the AI MCP Server. It allows anyone in `engineering`, so the read tools behave the way they would without actors.
* `tools[].access.acls.allow_when` on `delete-pet`: Replaces the default ACL for that tool rather than adding to it, so it states the group requirement again alongside the agent requirement.

The rule matches an agent by its approval metadata rather than by its position in the list.
An actor's position depends on which sources resolved an identity, so a rule written against `actors[0]` can start evaluating a different entity than you intended.
See [Write a condition that uses actors](/ai-gateway/conditions/#write-a-condition-that-uses-actors).

## Validate

Validate the rule with the [MCP Inspector CLI](https://modelcontextprotocol.io/docs/tools/inspector#cli), passing a bearer token in the `Authorization` header.
Each token's `sub` identifies the user and its `azp` identifies the agent's client.

An ACL denial is enforced on the route, before the request is dispatched as an MCP RPC, so {{site.ai_gateway}} returns a plain `HTTP 403 Forbidden` response rather than a JSON-RPC error object.
The MCP Inspector CLI reports that as a transport error and exits with a non-zero status.

### Get a token for each agent

Each token is issued through Keycloak's direct access grant, for the same user, to a different client.
The user's password proves who the request is made for, and the client credentials identify the agent making it.

1. Get a token for the user through the approved agent:
   <!--vale off-->
{% validation request-check %}
konnect_url: $KEYCLOAK_URL
url: /realms/master/protocol/openid-connect/token
method: POST
headers:
  - 'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: password
  client_id: $APPROVED_AGENT_CLIENT_ID
  client_secret: $APPROVED_AGENT_CLIENT_SECRET
  username: dana
  password: $USER_PASSWORD
extract_body:
  - name: "access_token"
    variable: TOKEN_USER_VIA_APPROVED_AGENT
capture:
  - variable: TOKEN_USER_VIA_APPROVED_AGENT
    jq: ".access_token"
status_code: 200
indent: 3
{% endvalidation %}
   <!--vale on-->

1. Get a token for the same user through the unapproved agent:
   <!--vale off-->
{% validation request-check %}
konnect_url: $KEYCLOAK_URL
url: /realms/master/protocol/openid-connect/token
method: POST
headers:
  - 'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: password
  client_id: $UNAPPROVED_AGENT_CLIENT_ID
  client_secret: $UNAPPROVED_AGENT_CLIENT_SECRET
  username: dana
  password: $USER_PASSWORD
extract_body:
  - name: "access_token"
    variable: TOKEN_USER_VIA_UNAPPROVED_AGENT
capture:
  - variable: TOKEN_USER_VIA_UNAPPROVED_AGENT
    jq: ".access_token"
status_code: 200
indent: 3
{% endvalidation %}
   <!--vale on-->

1. Get a token for the same user through the agent that was never registered as a principal:
   <!--vale off-->
{% validation request-check %}
konnect_url: $KEYCLOAK_URL
url: /realms/master/protocol/openid-connect/token
method: POST
headers:
  - 'Content-Type: application/x-www-form-urlencoded'
form_url_encoded_data:
  grant_type: password
  client_id: $UNREGISTERED_AGENT_CLIENT_ID
  client_secret: $UNREGISTERED_AGENT_CLIENT_SECRET
  username: dana
  password: $USER_PASSWORD
extract_body:
  - name: "access_token"
    variable: TOKEN_USER_VIA_UNREGISTERED_AGENT
capture:
  - variable: TOKEN_USER_VIA_UNREGISTERED_AGENT
    jq: ".access_token"
status_code: 200
indent: 3
{% endvalidation %}
   <!--vale on-->

All three tokens carry the same `sub`. Only `azp` differs.

### The approved agent can delete

A token whose `sub` is the user and whose `azp` is the approved agent's client satisfies both halves of the rule:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    $KONNECT_PROXY_URL/petstore-delegated \
    --transport http --method tools/call \
    --tool-name delete-pet \
    --tool-arg path_petId=10 \
    --header "Authorization: Bearer $TOKEN_USER_VIA_APPROVED_AGENT"
expected:
  return_code: 0
  message: "Pet deleted"
render_output: false
{% endvalidation %}
<!--vale on-->

The tool result confirms the deletion with `Pet deleted`.

### The same user through an unapproved agent is rejected

Nothing about the user changed.
The token still has the same `sub`, and the user is still in `engineering`.
Only the agent is different, and it doesn't have the approval metadata:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    $KONNECT_PROXY_URL/petstore-delegated \
    --transport http --method tools/call \
    --tool-name delete-pet \
    --tool-arg path_petId=10 \
    --header "Authorization: Bearer $TOKEN_USER_VIA_UNAPPROVED_AGENT"
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

The call is rejected with `HTTP 403 Forbidden`.
A group check on the user alone can't catch this case.

### An agent nobody registered is rejected earlier

The third token's `azp` is a client that has no principal in {{site.identity}}, so the actor lookup finds nothing.
Because the AI Auth Strategy sets `error_on_miss: true`, that fails at authentication rather than at the ACL:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    $KONNECT_PROXY_URL/petstore-delegated \
    --transport http --method tools/call \
    --tool-name delete-pet \
    --tool-arg path_petId=10 \
    --header "Authorization: Bearer $TOKEN_USER_VIA_UNREGISTERED_AGENT"
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

The call is rejected with `HTTP 401 Unauthorized`, not `403`.
This is the difference the `error_on_miss` setting makes: an agent you haven't registered is turned away by name, instead of silently producing no actor and failing a rule you'd then have to debug.
