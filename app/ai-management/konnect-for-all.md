---
title: "Konnect for All"
content_type: reference
layout: reference
permalink: /ai-management/konnect-for-all/
breadcrumbs:
  - /ai-management/
products:
  - ai-gateway
works_on:
  - konnect
tags:
  - ai
  - access-control
description: "Konnect for All (K4A) has three roles in AI Management. This reference lists what each role can do with models, MCP servers, agents, keys, and cost data."
related_resources:
  - text: AI Management
    url: /ai-management/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
---

Konnect for All (K4A) gives every user in [AI Management](/ai-management/) a role, and the role sets what they can do.
Admins set up models, MCP servers, and agents, and other users ask an admin for access.

## Roles

<!-- vale off -->
{% table %}
columns:
  - title: Role
    key: role
  - title: Who has it
    key: who
  - title: What the role does
    key: does
rows:
  - role: Admin
    who: "A user with the {{site.konnect_short_name}} Organization Admin or Identity Admin role."
    does: "Creates and manages resources, users, and access for the whole organization."
  - role: Team manager
    who: "The owner of a Team in the org chart."
    does: "Sees spend and budgets for their teams, and requests resources and access."
  - role: Individual
    who: "Any other user in the organization."
    does: "Views their own usage, and requests resources and access."
{% endtable %}
<!-- vale on -->

## Models

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - capability: "Add a model"
    admin: "Yes, with **New model**"
    manager: "No"
    individual: "No"
  - capability: "Ask an admin to add a model"
    admin: "No"
    manager: "Yes, with **Request a model**"
    individual: "Yes, with **Request a model**"
  - capability: "Turn a model on or off"
    admin: "Yes"
    manager: "No"
    individual: "No"
  - capability: "Edit, delete, or debug a model"
    admin: "Yes, from the **Actions** menu"
    manager: "No"
    individual: "No"
  - capability: "View auth strategies, ACLs, and policies on a model"
    admin: "Yes"
    manager: "No"
    individual: "No"
  - capability: "View their own usage of a model for the last 7 days"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
  - capability: "Request access to call a model"
    admin: "No"
    manager: "Yes, with **Request access**"
    individual: "Yes, with **Request access**"
  - capability: "Manage virtual keys from a model"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
{% endtable %}
<!-- vale on -->

## Providers

[Providers](/ai-gateway/entities/ai-model-provider/) are under **Models** in the navigation.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - capability: "Add a provider"
    admin: "Yes, with **New provider**"
    manager: "No"
    individual: "No"
  - capability: "Edit or delete a provider"
    admin: "Yes, from the **Actions** menu"
    manager: "No"
    individual: "No"
  - capability: "Set a provider to get each caller's key from [Token Vault](/identity/token-vault/)"
    admin: "Yes, with **Key source** > **Token Vault**"
    manager: "No"
    individual: "No"
  - capability: "View a provider's authentication type and details"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
{% endtable %}
<!-- vale on -->

## MCP servers

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - capability: "Add an MCP server"
    admin: "Yes, with **New MCP server**"
    manager: "No"
    individual: "No"
  - capability: "Ask an admin to add an MCP server"
    admin: "No"
    manager: "Yes, with **Request an MCP server**"
    individual: "Yes, with **Request an MCP server**"
  - capability: "Turn an MCP server on or off"
    admin: "Yes"
    manager: "No"
    individual: "No"
  - capability: "Edit, delete, or debug an MCP server"
    admin: "Yes, from the **Actions** menu"
    manager: "No"
    individual: "No"
  - capability: "View an MCP server's tools and usage"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
  - capability: "Change logging for an MCP server"
    admin: "Yes, with **Log payloads** and **Log audits**"
    manager: "No"
    individual: "No"
  - capability: "Set an MCP server to get its upstream credential from [Token Vault](/identity/token-vault/)"
    admin: "Yes, with **Outbound authentication** > **Use a credential provider**"
    manager: "No"
    individual: "No"
  - capability: "View an MCP server's [authentication](/ai-gateway/entities/ai-mcp-server/#protected-resource-metadata), [ACLs](/ai-gateway/entities/ai-mcp-server/#acl-tool-control), and policies"
    admin: "Yes"
    manager: "No"
    individual: "No"
  - capability: "Request access to call an MCP server"
    admin: "No"
    manager: "Yes, with **Request access**"
    individual: "Yes, with **Request access**"
  - capability: "Manage virtual keys from an MCP server"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
{% endtable %}
<!-- vale on -->

## Agents

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - capability: "Add an agent"
    admin: "Yes, with **New agent**"
    manager: "No"
    individual: "No"
  - capability: "Ask an admin to add an agent"
    admin: "No"
    manager: "Yes, with **Request an agent**"
    individual: "Yes, with **Request an agent**"
  - capability: "Turn an agent on or off"
    admin: "Yes"
    manager: "No"
    individual: "No"
  - capability: "Edit, delete, debug, or link an identity record to an agent"
    admin: "Yes, from the **Actions** menu"
    manager: "No"
    individual: "No"
  - capability: "Change logging for an agent"
    admin: "Yes, with **Log payloads** and **Log audits**"
    manager: "No"
    individual: "No"
  - capability: "Request access to call an agent"
    admin: "No"
    manager: "Yes, with **Request access**"
    individual: "Yes, with **Request access**"
  - capability: "Manage virtual keys from an agent"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
{% endtable %}
<!-- vale on -->

## Access Management

[Access Management](/ai-access-management/concepts/) has pages for users, agents, groups, and virtual keys.
Projects are a tab on the **Groups** page.
Users and agents are [{{site.identity}} principals](/identity/principals/).

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - capability: "Open the Users, Identity Providers, and Token Vault pages"
    admin: "Yes"
    manager: "No"
    individual: "No"
  - capability: "View agent identities"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
  - capability: "Ask an admin to add an agent identity"
    admin: "No"
    manager: "Yes, with **Request an agent**"
    individual: "Yes, with **Request an agent**"
  - capability: "View groups and projects"
    admin: "All groups and projects"
    manager: "Only their groups and projects"
    individual: "Only their groups and projects"
  - capability: "View virtual keys"
    admin: "All keys"
    manager: "Their own keys, and keys in the groups and projects that they manage"
    individual: "Only their own keys"
  - capability: "Create a virtual key"
    admin: "Yes, with **New Key**"
    manager: "Yes, with **New Key**"
    individual: "Yes, with **New Key**"
  - capability: "Delete a virtual key"
    admin: "Yes"
    manager: "Yes, for keys they can view"
    individual: "Yes, for their own keys"
{% endtable %}
<!-- vale on -->

## Cost Management

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - capability: "View their own usage on **My Usage**"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
  - capability: "View the cost dashboard and explorer"
    admin: "Yes, for the whole organization"
    manager: "Yes, for their teams"
    individual: "No"
  - capability: "View and create budgets"
    admin: "Yes, for the whole organization"
    manager: "Yes, for their teams"
    individual: "No"
  - capability: "Use the price catalog, attribution, and exports"
    admin: "Yes"
    manager: "No"
    individual: "No"
{% endtable %}
<!-- vale on -->

## Observability

Individuals can open a dashboard's sharing settings to see who has access, but they cannot change them.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - capability: "View Overview, Dashboards, Explorer, and Logs"
    admin: "Yes"
    manager: "Yes"
    individual: "Yes"
  - capability: "Share a dashboard with other users and teams"
    admin: "Yes"
    manager: "Yes"
    individual: "No, view only"
{% endtable %}
<!-- vale on -->

## Requests

When team managers or individuals need a resource or access that they do not have, they send a request.
An admin decides whether to approve it.

<!-- vale off -->
{% table %}
columns:
  - title: Request
    key: request
  - title: Where to find it
    key: where
  - title: What you provide
    key: provide
rows:
  - request: "**Request a model**"
    where: "Models page"
    provide: "A provider and a model from the provider's catalog. A reason is optional."
  - request: "**Request an MCP server**"
    where: "MCP servers page"
    provide: "A server from the library, or the URL of a server that is not in the library. A reason is optional."
  - request: "**Request an agent**"
    where: "Agents page"
    provide: "A display name, a type (A2A or HTTP), and the agent's URL. A reason is optional."
  - request: "**Request access**"
    where: "The detail page of a model, MCP server, or agent"
    provide: "A reason, which is required. The request names the resource, its gateway, and your email address."
{% endtable %}
<!-- vale on -->
