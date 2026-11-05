---
title: "AI Management roles and permissions"
content_type: reference
layout: reference
permalink: /ai-management/roles-and-permissions/
breadcrumbs:
  - /ai-management/
products:
  - ai-gateway
works_on:
  - konnect
tags:
  - ai
  - access-control
description: "Reference for what Org Admins, Team Managers, and Individual Users can do in AI Management. Covers permissions for AI Models, AI MCP Servers, AI Agents, virtual keys, and cost data."
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

[AI Management](/ai-management/) roles control who can create and manage models, MCP servers, agents, and virtual keys, and who can view cost data.
Org Admins set up models, MCP servers, and agents.
Team Managers and Individual Users ask an Org Admin for access.

## Roles

{{site.konnect_short_name}} assigns Team Manager and Individual User for you.
They do not appear in any role dropdown, and you cannot assign them manually.

<!-- vale off -->
{% table %}
columns:
  - title: Role
    key: role
  - title: How a user gets it
    key: who
  - title: What the role does
    key: does
rows:
  - role: Org Admin
    who: "You add them to the {{site.konnect_short_name}} Organization Admin or Identity Admin [team](/konnect-platform/teams-and-roles/)."
    does: "Creates and manages resources, users, and access for the whole organization."
  - role: Team Manager
    who: "{{site.konnect_short_name}} assigns it to a user who manages a team in the [org chart](/ai-cost-management/org-chart/). The role applies to that team only."
    does: "Sees spend and budgets for their teams, and requests resources and access."
  - role: Individual User
    who: "{{site.konnect_short_name}} assigns it to a user whose email address matches a {{site.identity}} [principal](/identity/principals/) of type `User`."
    does: "Requests resources and access."
{% endtable %}
<!-- vale on -->

A {{site.konnect_short_name}} user with no matching principal has no AI Management role.
The match works in either order. An org chart import or automatic user provisioning can create the principal before or after the user exists.

### Invite a user to AI Management

AI Management has its own invite, which assigns these roles automatically.
An [org chart import](/ai-cost-management/org-chart/) adds users to AI Management but does not invite them, so invite each user after you import.
To invite a user:

1. In the {{site.konnect_short_name}} sidebar, click **Access Management**, then click **Users**.
1. Do one of the following:
   * For an existing user, open the user's actions menu and click **Invite user**.
   * For a new user, click **New user**, fill in the form, and select **Invite this user to view their usage on Konnect**.

When the user accepts the invite and signs in, they get their roles.
Users who sign in with single sign-on (SSO) do not need an invite.
They get their roles the first time they sign in.

To check a user's roles, open the user's **Role Assignments** tab under **Manage organization** and select **All roles**.

## Models

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Org Admin
    key: admin
  - title: Team Manager
    key: manager
  - title: Individual User
    key: individual
rows:
  - capability: "Add a model with **New** > **Model**"
    admin: true
    manager: false
    individual: false
  - capability: "Ask an Org Admin to add a model with **Request a model**"
    admin: false
    manager: true
    individual: true
  - capability: "Turn a model on or off"
    admin: true
    manager: false
    individual: false
  - capability: "Edit or delete a model from the **Actions** menu"
    admin: true
    manager: false
    individual: false
  - capability: "View a model's auth strategies, ACLs, and policies in the **Edit** form"
    admin: true
    manager: false
    individual: false
  - capability: "Request access to call a model with **Request access**"
    admin: false
    manager: true
    individual: true
  - capability: "Manage virtual keys from a model"
    admin: true
    manager: true
    individual: true
{% endtable %}
<!-- vale on -->

## Providers

[Providers](/ai-gateway/entities/ai-model-provider/) are under **Models > Providers** in the sidebar.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Org Admin
    key: admin
  - title: Team Manager
    key: manager
  - title: Individual User
    key: individual
rows:
  - capability: "Add a provider with **New provider**"
    admin: true
    manager: false
    individual: false
  - capability: "Edit or delete a provider from the **Actions** menu"
    admin: true
    manager: false
    individual: false
  - capability: "View a provider's authentication type and details"
    admin: true
    manager: true
    individual: true
{% endtable %}
<!-- vale on -->

## MCP servers

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Org Admin
    key: admin
  - title: Team Manager
    key: manager
  - title: Individual User
    key: individual
rows:
  - capability: "Add an MCP server with **New** > **MCP server**"
    admin: true
    manager: false
    individual: false
  - capability: "Ask an Org Admin to add an MCP server with **Request an MCP server**"
    admin: false
    manager: true
    individual: true
  - capability: "Turn an MCP server on or off"
    admin: true
    manager: false
    individual: false
  - capability: "Edit or delete an MCP server from the **Actions** menu"
    admin: "Yes. Passthrough servers have only **Delete**."
    manager: false
    individual: false
  - capability: "View an MCP server's tools"
    admin: true
    manager: true
    individual: true
  - capability: "Change logging for an MCP server with **Log payloads** and **Log audits**"
    admin: true
    manager: false
    individual: false
  - capability: "Set an MCP server to get its upstream credential from [Token Vault](/identity/token-vault/) with **Outbound authentication** > **Use a credential provider**"
    admin: true
    manager: false
    individual: false
  - capability: "View an MCP server's outbound authentication"
    admin: true
    manager: false
    individual: false
  - capability: "Request access to call an MCP server with **Request access**"
    admin: false
    manager: true
    individual: true
  - capability: "Manage virtual keys from an MCP server"
    admin: true
    manager: true
    individual: true
{% endtable %}
<!-- vale on -->

## Agents

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Org Admin
    key: admin
  - title: Team Manager
    key: manager
  - title: Individual User
    key: individual
rows:
  - capability: "Add an agent with **New agent**"
    admin: true
    manager: false
    individual: false
  - capability: "Ask an Org Admin to add an agent with **Request an agent**"
    admin: false
    manager: true
    individual: true
  - capability: "Turn an agent on or off"
    admin: true
    manager: false
    individual: false
  - capability: "Edit, delete, debug, or link an identity record to an agent from the **Actions** menu"
    admin: true
    manager: false
    individual: false
  - capability: "Change logging for an agent with **Log payloads**"
    admin: true
    manager: false
    individual: false
  - capability: "Request access to call an agent with **Request access**"
    admin: false
    manager: true
    individual: true
  - capability: "Manage virtual keys from an agent"
    admin: true
    manager: true
    individual: true
{% endtable %}
<!-- vale on -->

## Access Management

[Access Management](/ai-access-management/concepts/) has pages for users, groups, and virtual keys.
Users and agents are [{{site.identity}} principals](/identity/principals/).

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Org Admin
    key: admin
  - title: Team Manager
    key: manager
  - title: Individual User
    key: individual
rows:
  - capability: "Open the Users, Identity Providers, and Token Vault pages"
    admin: true
    manager: false
    individual: false
  - capability: "View groups"
    admin: "All groups"
    manager: "Only their groups"
    individual: "Only their groups"
  - capability: "View virtual keys"
    admin: "All keys"
    manager: "Their own keys, and keys in the groups that they manage"
    individual: "Only their own keys"
  - capability: "Create a virtual key with **New key**"
    admin: true
    manager: true
    individual: true
  - capability: "Delete a virtual key"
    admin: true
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
  - title: Org Admin
    key: admin
  - title: Team Manager
    key: manager
  - title: Individual User
    key: individual
rows:
  - capability: "View their own spend in **My Usage**"
    admin: true
    manager: true
    individual: true
  - capability: "View the cost dashboard and explorer"
    admin: "Yes, for the whole organization"
    manager: "Yes, for their teams"
    individual: false
  - capability: "View and create budgets"
    admin: "Yes, for the whole organization"
    manager: "View only"
    individual: false
  - capability: "Use the price catalog, attribution, and exports"
    admin: true
    manager: false
    individual: false
{% endtable %}
<!-- vale on -->

## Observability

Individual Users can view a dashboard's sharing settings, but only Org Admins and Team Managers can change them.

<!-- vale off -->
{% table %}
columns:
  - title: Capability
    key: capability
  - title: Org Admin
    key: admin
  - title: Team Manager
    key: manager
  - title: Individual User
    key: individual
rows:
  - capability: "View Overview, Dashboards, Explorer, and Logs"
    admin: true
    manager: true
    individual: true
  - capability: "Share a dashboard with other users and teams"
    admin: true
    manager: true
    individual: false
{% endtable %}
<!-- vale on -->

## Requests

Team Managers and Individual Users send a request when they need a resource or access they don't have.
An Org Admin decides whether to approve each request.

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
