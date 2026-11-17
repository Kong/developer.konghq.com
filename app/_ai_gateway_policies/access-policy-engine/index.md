---
title: 'AI Access Policy Engine'
name: 'AI Access Policy Engine'
publisher: kong-inc
description: 'Control which Kong Identity principals can call which AI Models and MCP tools, using access rules that you manage in Konnect.'
min_version:
  ai-gateway: '2.4'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
categories:
  - traffic-control
tags:
  - authorization
  - access-control
  - kong-identity
  - mcp
  - ai
related_resources:
  - text: ACL AI Policy
    url: /ai-gateway/policies/acl/
  - text: AI Policy
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model
    url: /ai-gateway/entities/ai-model/
  - text: AI MCP Server
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Auth Strategy
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: Restrict AI Model access to a group of {{site.identity}} principals
    url: /ai-gateway/restrict-ai-model-access-by-group-with-kong-identity/
---

The AI Access Policy Engine Policy controls which {{site.identity}} [principals](/identity/principals/) can call which [AI Models](/ai-gateway/entities/ai-model/) and MCP tools through {{site.ai_gateway}}.
You write access rules in {{site.konnect_short_name}}, for example "the Contractors group can call only the standard model" or "nobody can call this model", and the Policy checks every request from a principal against those rules.

This Policy lets you manage access to every [AI Model](/ai-gateway/entities/ai-model/) and [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) in one place.
Access rules belong to your organization, so a single rule applies across control planes and entities.

## Use cases

Use the AI Access Policy Engine Policy in the following situations:

{% table %}
columns:
  - title: Problem to solve
    key: situation
  - title: Typical scenario
    key: example
  - title: Rule to create
    key: rule
rows:
  - situation: A group of users can reach a model that they shouldn't.
    example: "Contractors and employees share an organization, and only employees should call the premium model."
    rule: "Create an allow rule for the Employees group on the premium model. No allow rule matches Contractors, so the Policy rejects their requests."
  - situation: A model must be switched off for everyone immediately.
    example: "A model is withdrawn after a compliance review."
    rule: "Create a deny rule for the model without a group or principal. The rule applies to the whole organization. A deny rule takes precedence over an allow rule."
  - situation: Access rules need updating each time a provider releases a new model version.
    example: "A provider releases a new version of a model every few months, and the team should always have access to that model family."
    rule: "Create an allow rule with a wildcard at the end of the model name, such as `gpt-*`."
  - situation: An agent can call every tool on an MCP server when it needs only a few.
    example: "A support agent needs to read tickets but must not close or delete them."
    rule: "Set [`enforce_mcp`](/ai-gateway/policies/access-policy-engine/reference/#schema--config-enforce-mcp) to `true`. Then create an allow rule for the agent's principal on the MCP server, limited to the read-only tools."
  - situation: Groups need the same access on more than one control plane.
    example: "Your organization runs separate control planes for production and staging, and the same groups need the same model access in both."
    rule: "Create the rules once in {{site.konnect_short_name}}, and add the Policy to each control plane."
{% endtable %}

## How it works

The Policy depends on three things that you set up separately:

* **Principals and groups:** Callers must authenticate as {{site.identity}} principals through an [AI Auth Strategy with principal mapping](/ai-gateway/entities/ai-auth-strategy/#principal-mapping).
  Groups organize principals, so that one rule can cover many callers.
* **Access rules:** Each rule allows or denies access to one AI Model or one MCP server, for a group, a principal, or the whole organization.
    You create access rules (ACLs) with the {{site.konnect_short_name}} API.
* **The Policy:** Create the AI Access Policy Engine Policy with `global: true`.
  The Policy supports only global scope. See [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

When a request arrives, the Policy evaluates it as follows:

1. The AI Auth Strategy authenticates the caller and resolves its {{site.identity}} principal.
   {{site.ai_gateway}} loads the access rules for that principal together with it: the rules for each of its groups, the rules for the principal itself, and the rules for the whole organization.
1. The Policy identifies the AI Model that the request is for.
   When [`enforce_mcp`](/ai-gateway/policies/access-policy-engine/reference/#schema--config-enforce-mcp) is `true`, it also identifies the MCP tool.
1. If any deny rule matches, the Policy rejects the request.
   Otherwise, if any allow rule matches, the request proceeds.
   Otherwise, the Policy rejects the request.
1. The Policy returns its configured rejection response to the caller.

The Policy skips requests from callers without a {{site.identity}} principal.
This includes unauthenticated requests and requests from an AI Consumer that isn't linked to a principal.

{:.warning}
> **Create allow rules before you add the Policy**
>
> The Policy rejects a request from a principal when no allow rule matches it, and when the principal has no rules at all. If you add the Policy before you create any allow rules, it rejects every request from a principal.

## Choose between access control options

{{site.ai_gateway}} has several ways to control access, and they identify callers differently.
The following table compares them:

{% table %}
columns:
  - title: Option
    key: option
  - title: "`access.acls` on an entity"
    key: entity
  - title: "[ACL Policy](/ai-gateway/policies/acl/)"
    key: acl
  - title: AI Access Policy Engine Policy
    key: ape
rows:
  - option: "Identifies callers by"
    entity: "AI Consumers, AI Consumer Groups, and authenticated groups. CEL expressions can also use consumer attributes and request context."
    acl: "AI Consumers, AI Consumer Groups, and authenticated groups."
    ape: "{{site.identity}} principals and the groups they belong to."
  - option: "Rules are defined in"
    entity: "The `access.acls` field of the AI Model, AI MCP Server, or AI Agent."
    acl: "The configuration of the Policy."
    ape: "Access rules that you create at the organization level in {{site.konnect_short_name}}."
  - option: "Applies to"
    entity: "The entity that holds the field."
    acl: "AI Models, AI MCP Servers, AI Agents, or all traffic."
    ape: "All AI Model traffic, and AI MCP Server traffic when `enforce_mcp` is `true`."
  - option: "AI Consumers that aren't linked to a principal"
    entity: "Evaluated"
    acl: "Evaluated"
    ape: "Not evaluated"
{% endtable %}

Use the AI Access Policy Engine Policy when your callers are {{site.identity}} principals.
It lets you manage who can call which models and MCP tools in one place, by group, instead of editing each entity.
Use `access.acls` or the ACL Policy when your callers are AI Consumers, or when you need to control access to AI Agents.
The AI Access Policy Engine Policy doesn't evaluate either.

## Limitations

The AI Access Policy Engine Policy has the following limitations:

* The Policy doesn't evaluate AI Agent requests.
* A rule that selects MCP tools matches the tool name on every MCP server that exposes a tool with that name, not only the server that you named.
* A deny rule on selected tools leaves the MCP session open, so the principal can still call other tools. A deny rule on a whole MCP server closes the session.
* Model rules can't constrain the `deployment` or `instance` of a model.
* Changes to access rules apply after the data plane's cached copy of the principal expires.
* When the Policy can't evaluate a request's rules, it returns a `500` response instead of the rejection response that is configured on the Policy.
