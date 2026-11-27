---
title: "Access Policy Engine"
layout: reference
content_type: reference
description: "Control which {{site.identity}} principals can call which AI Models and MCP tools, using access rules that you manage once for your whole organization."
breadcrumbs:
  - /ai-gateway/

works_on:
  - konnect

products:
  - ai-gateway
  - identity

tools:
  - konnect-api

tags:
  - ai
  - authorization
  - access-control
  - kong-identity
  - mcp

min_version:
  ai-gateway: '2.4'

related_resources:
  - text: ACL AI Policy
    url: /ai-gateway/policies/acl/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: Restrict AI Model access to a group of {{site.identity}} principals
    url: /ai-gateway/restrict-ai-model-access-by-group-with-kong-identity/
---

Access to an [AI Model](/ai-gateway/entities/ai-model/) or an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) is normally configured on each entity.
This works until you have several teams and a growing list of models.
If you want to make a rule, such as "contractors don't get the expensive model," that rule then has to be added again on every entity, and switching a model off for everyone means editing each one.

The Access Policy Engine allows you to make those decisions globally.
You write access rules once for your organization in {{site.konnect_short_name}}, and {{site.ai_gateway}} checks every request from a {{site.identity}} [principal](/identity/principals/) against them.

The Access Policy Engine evaluates AI Model traffic and AI MCP Server traffic.
MCP traffic is always evaluated.
It also evaluates WebSocket upgrade requests: a rejected upgrade never becomes a connection.

The Access Policy Engine doesn't evaluate the following:

* AI Agent requests
* Unauthenticated requests
* Requests from an AI Consumer that isn't linked to a {{site.identity}} principal

Those requests pass through without being checked against any rule, so plain consumer traffic on the same control plane keeps working.

## How it works

You control the Access Policy Engine entirely through access rules, and turning on the setting for a control plane starts enforcement.
To use it:

1. Set up callers as {{site.identity}} principals.
   Clients authenticate through an [AI Auth Strategy with principal mapping](/ai-gateway/entities/ai-auth-strategy/#principal-mapping).
   Put principals in groups so that one rule can cover many callers.
1. Create access rules in {{site.konnect_short_name}} using the `/v1/policies/acls` endpoint.
   Each rule allows or denies access to AI Models or MCP servers, for a group, a single principal, or everyone in the organization.
1. Turn on the Access Policy Engine on each control plane where you want the rules enforced, by setting `access_policy_engine.enabled` to `true` in the control plane's settings (`/v1/ai-gateways/{gatewayId}/settings`).

Access rules belong to your {{site.konnect_short_name}} organization, so you write them once.
Enforcement is per control plane: it applies only on the control planes where you turn it on.
If you run production and staging as separate control planes and want the same rules in both, turn it on for each.

{:.warning}
> **Create your allow rules first**
>
> A principal needs a matching allow rule, or the request is rejected.
> If you turn on the Access Policy Engine before any rules exist, every request from a principal is rejected.

## Use cases

Acme has two {{site.identity}} groups, `employees` and `contractors`, and runs a Jira MCP server.
An administrator creates four rules:

{% table %}
columns:
  - title: Who the rule applies to
    key: who
  - title: What it covers
    key: what
  - title: Effect
    key: effect
rows:
  - who: "The `employees` group"
    what: "Models matching `gpt-*`"
    effect: allow
  - who: "The `employees` group"
    what: "The `jira` MCP server, tools `get_ticket` and `list_tickets`"
    effect: allow
  - who: "The `contractors` group"
    what: "The `gpt-4o-mini` model"
    effect: allow
  - who: Everyone in the organization
    what: "The `gpt-4-turbo` model"
    effect: deny
{% endtable %}

Then an administrator turns on the Access Policy Engine on Acme's production control plane.
From that point:

* A contractor calls `gpt-4o-mini`.
  The request is proxied, because the `contractors` rule allows it.
* The same contractor calls `gpt-4o`.
  The request is rejected, because no allow rule matches them for that model.
* An employee calls `gpt-4-turbo`.
  The request is rejected, because the organization-wide deny takes precedence over the `gpt-*` allow.
* An employee calls `get_ticket` on `jira`.
  The request is proxied.
  The same employee calls `delete_ticket` and is rejected, because the rule lists only two tools.
* An unauthenticated request, or a request from an [AI Consumer](/ai-gateway/entities/ai-consumer/) without a linked principal, isn't evaluated at all.

Every rejected request gets the same `403` response with the body `{"message":"Forbidden"}`.
The response is fixed.

## Choose between access control options

{{site.ai_gateway}} has three ways to control access, and which one you should use depends on what your callers are.

{% table %}
columns:
  - title: Option
    key: option
  - title: "`access.acls` on an entity"
    key: entity
  - title: "[ACL Policy](/ai-gateway/policies/acl/)"
    key: acl
  - title: Access Policy Engine
    key: ape
rows:
  - option: "Identifies callers by"
    entity: "AI Consumers, AI Consumer Groups, and authenticated groups. CEL expressions can also use consumer attributes and request context."
    acl: "AI Consumers, AI Consumer Groups, and authenticated groups."
    ape: "{{site.identity}} principals and the groups they belong to."
  - option: "Rules are defined in"
    entity: "The `access.acls` field of the AI Model, AI MCP Server, or AI Agent."
    acl: "The configuration of the Policy."
    ape: "Access rules that you create once for your organization in {{site.konnect_short_name}}."
  - option: "Applies to"
    entity: "The entity that holds the field."
    acl: "AI Models, AI MCP Servers, AI Agents, or all traffic."
    ape: "All AI Model and AI MCP Server traffic on that control plane."
  - option: "Callers that aren't linked to a principal"
    entity: "Evaluated"
    acl: "Evaluated"
    ape: "Not evaluated"
{% endtable %}

Use the Access Policy Engine when your callers are {{site.identity}} principals and you want one place to manage access by group.
Use `access.acls` or the ACL Policy when your callers are AI Consumers, or when you need to control access to [AI Agents](/ai-gateway/entities/ai-agent/), which the Access Policy Engine doesn't evaluate.

The three options work independently of each other.
`access.acls` and the ACL Policy remain fully supported, and each one is evaluated independently of the Access Policy Engine.
When more than one applies to a request, each one evaluates it, and a rejection from any of them rejects the request.

## Write access rules

Access rules are called ACLs in the {{site.konnect_short_name}} API.
A rule has an effect (`allow` or `deny`), the resources it applies to, and an optional anchor, which limits it to a group or a principal.
A deny always takes precedence over an allow.

A new rule takes effect after a delay:
* Each gateway node re-reads the rules that apply to everyone in the organization about every 30 seconds.
* Rules that are specific to a principal, and changes to the groups a principal belongs to, apply once the data plane's cached copy of that principal expires.
  This can take up to 10 minutes, the default `ttl_secs` of the {{site.identity}} directory.

### Allow a group to access a family of models

Access rules for a model match the model name that the provider serves.
The name that clients send in the request must be the same as the name that the AI Model's target sends to the provider.
If they differ, for example when clients send `my-gpt-5-mini` and the target is `gpt-5-mini`, the Access Policy Engine can't tell which model the request serves, and it returns a `500` response.
A trailing wildcard keeps the rule working when the provider releases a new version.
The following request creates a rule that allows the `employees` group to call every model that matches `gpt-*`:

<!--vale off-->
{% konnect_api_request %}
url: /v1/policies/acls
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "employees-can-call-gpt-models"
  anchor:
    type: group
    id: $GROUP_ID
    directory_id: $DIRECTORY_ID
  effect: allow
  resources:
    - type: Model
      name: gpt-*
{% endkonnect_api_request %}
<!--vale on-->

### Disable a model for everyone

A rule without an anchor applies to the whole organization.
Use this when a model is withdrawn and you don't want to edit each group's rules.
The following request creates a rule that denies `gpt-4-turbo` to everyone:

<!--vale off-->
{% konnect_api_request %}
url: /v1/policies/acls
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "no-gpt-4-turbo-for-anyone"
  effect: deny
  resources:
    - type: Model
      name: gpt-4-turbo
{% endkonnect_api_request %}
<!--vale on-->

### Limit which MCP tools a caller can use

A rule for an MCP server can list tools to restrict a caller to part of that server.
Leave `tools` out to cover the whole server, including its session.
The rule names the server by the id that the data plane gives it, which is the AI MCP Server's name followed by `-route`.
For an AI MCP Server named `jira`, the id is `jira-route`.
The following request creates a rule that allows one principal to call only `get_ticket` and `list_tickets` on that server:

<!--vale off-->
{% konnect_api_request %}
url: /v1/policies/acls
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "support-agent-can-read-jira-tickets"
  anchor:
    type: principal
    id: $PRINCIPAL_ID
    directory_id: $DIRECTORY_ID
  effect: allow
  resources:
    - type: McpServer
      name: jira-route
      tools:
        - get_ticket
        - list_tickets
{% endkonnect_api_request %}
<!--vale on-->

The principal can call those two tools, and any other tool call is rejected with a `403`.
The server's `tools/list` response shows that principal only the two tools they can call.

## Limitations

* A rule that lists MCP tools matches those tool names on every MCP server that exposes them, including servers other than the one you named.
* A deny rule on selected tools leaves the MCP session open, so the caller can still use the server's other tools.
  A deny rule on a whole MCP server closes the session.
* A principal that doesn't have any access rules is rejected, even when an organization-wide rule would allow the request.
* If a gateway node can't read the organization-wide rules, it keeps enforcing the rules attached to each principal and retries.
  An organization-wide deny created during that window isn't enforced until the node can read the rules again, so a new deny rule doesn't take effect immediately.
* When the Access Policy Engine can't evaluate a request, it returns a `500` response rather than the `403` used for a rejection.
