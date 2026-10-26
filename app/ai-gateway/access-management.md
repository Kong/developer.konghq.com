---
title: "Access management concepts"
content_type: reference
layout: reference
permalink: /ai-gateway/access-management/concepts/
works_on:
  - konnect

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai
  - access-control
  - authentication

min_version:
  ai-gateway: '2.3'

description: "Learn what users, agents, groups, identity providers, Token Vault, and virtual keys are in {{site.ai_gateway}} access management, and how they relate to each other."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "Principals"
    url: /identity/principals/
  - text: "AI Agents"
    url: /ai-gateway/entities/ai-agent/
  - text: "AI Vaults"
    url: /ai-gateway/entities/ai-vault/
  - text: "AI Consumers"
    url: /ai-gateway/entities/ai-consumer/
  - text: "Token Vault"
    url: /identity/token-vault/

faqs:
  - q: How can I create a group?
    a: |
      Admins create groups manually.

  - q: Can a group contain another group?
    a: |
      No. A group can't contain another group.
---

Access management allows you to define who can use your organization's resources, like [models](/ai-gateway/entities/ai-model/) or [MCP servers](/ai-gateway/entities/ai-mcp-server/), in {{site.ai_gateway}}.

## How access management works

Access management features answer two questions:

* Who is making the request?
* What are they allowed to do?

You can give permissions to users individually, or in bulk using groups.

## Users

A user is a person who is added to the system in one of three ways:

* An admin creates them manually.
* An admin uploads a CSV file containing the org structure.
* They sign in for the first time and are created through just-in-time (JIT) provisioning. This requires an [identity provider](#identity-providers) with JIT provisioning enabled.

To create a user, you must provide the following:

* A user name
* A user email

To stop a user from signing in while keeping their history, deactivate the user instead of deleting them.

Users imported from an org structure file are managed by that file:

* You can't delete them.
* Their name and email are read-only.
* If a later import no longer lists them, they are deactivated, not deleted.

{:.info}
> To change imported users, import an updated org chart.

You can view all users in one searchable table. Search matches on name, email, cost center, team, and source. You can filter the table by team, source, and status, and show or hide columns such as metadata and labels.

### Teams

You can assign users to a team. Teams can't be created manually. They are created when you import an org chart that groups users into teams. Teams can be nested under a parent team.

## Agents

An agent is the identity record for a piece of software that calls [models](/ai-gateway/entities/ai-model/) or [MCP servers](/ai-gateway/entities/ai-mcp-server/). It might act for itself, or on behalf of users.

The agent acts as the caller. Like users, it can:

* Hold [virtual keys](#virtual-keys) and remote credentials.
* Be linked to a cost center.

Agents in **Access Management** aren't the same thing as an [AI Agent](/ai-gateway/entities/ai-agent/):

* **AI Agents** are the resource you call through {{site.ai_gateway}}.
* **Agents** in **Access Management** are the identity that calls {{site.ai_gateway}} resources.

{:.warning}
> Agents can't belong to teams or sign in through an identity provider.

## Users versus agents

Users and agents share the following capabilities:

* Virtual keys
* Cost center
* Spend limits
* Group membership

The following table lists their differences:

{% table %}
columns:
  - title: Aspects
    key: aspect
  - title: Users
    key: users
  - title: Agents
    key: agents
rows:
  - aspect: What it represents
    users: A person.
    agents: Software that calls [models](/ai-gateway/entities/ai-model/), [MCP servers](/ai-gateway/entities/ai-mcp-server/), or other agents, including service accounts such as CI jobs.
  - aspect: How it's created
    users: Manually, through an org structure import, or through JIT provisioning on first sign-in.
    agents: From the **Agents** section. Agents aren't included in org structure imports.
  - aspect: Required fields
    users: Name and email.
    agents: Name.
  - aspect: How it authenticates
    users: Signs in through an [identity provider](#identity-providers), and calls the gateway with a [virtual key](#virtual-keys).
    agents: Uses only the credentials it holds, such as virtual keys and remote credentials.
  - aspect: Org structure
    users: Can belong to teams, appear on the org chart, and own a team.
    agents: Not part of teams or the org chart.
  - aspect: Link to a gateway resource
    users: Can't be linked to a gateway resource.
    agents: Can be linked to the [AI Agent](/ai-gateway/entities/ai-agent/) it represents.
  - aspect: Lifecycle
    users: Deactivate to stop sign-in and keep history. Imported users can't be deleted, and their name and email are read-only.
    agents: Deactivate or delete.
  - aspect: Kong Identity API type
    users: "`user`"
    agents: "`agent`"
{% endtable %}

## Groups

A group is a list of users and agents that share the same rules. Instead of setting rules on each member, you set them once on the group. For example, you can select a group when setting up a spend limit in the cost center.

Admins create groups manually. A group has a name, a description, labels, and metadata. A group can't contain another group, and doesn't have a cost center.

### Projects

A project is a group with its own spend limit. A project can be linked to a cost center, and it holds users and agents only. Projects can't contain other groups.

You can create a virtual key for a project. Each project key is used by one member of the project, uses the project's access rules and spend limit, and is billed to the project's cost center.

## Identity providers

An identity provider is an external service like Okta or Auth0, that signs the tokens people and agents present. Kong trusts the providers you list and uses them to verify that those tokens are genuine.

When you add an identity provider, you give it a display name and an issuer URL. You can also:

* Enable JIT provisioning, so that users are created the first time they sign in. JIT provisioning is separate from Token Vault access.
* Choose whether Token Vault trusts the provider.

[Token Vault](#token-vault) needs at least one trusted identity provider to verify callers.

To learn more, see [Token Vault's providers](/identity/token-vault/#providers).

## Token Vault

Token Vault stores credentials so that {{site.ai_gateway}} can call external services on behalf of a caller. To set it up:

1. Add at least one trusted [identity provider](#identity-providers).
1. Configure how Token Vault authenticates with this provider.
1. Create credential providers. A credential provider uses either OAuth or a static API key.

When you set up an [MCP server](/ai-gateway/entities/ai-mcp-server/), you can choose a credential provider for outbound authentication as an alternative to pass-through. You can view the credentials stored in the vault from the provider and identity provider detail pages.

To learn more, see [Token Vault](/identity/token-vault/).

## Virtual keys

A virtual key is an API key that lets a caller use {{site.ai_gateway}}. For example, instead of adding an Anthropic API key to an agent, you generate a virtual key for the agent. The agent uses the virtual key, while the provider API keys stay in [Token Vault](#token-vault) instead of in your apps.

Use virtual keys to:

* **Reinforce API key security:** Virtual keys can be generated and deleted.
* **Enforce and monitor costs:** You can link each virtual key to a cost center and set a spend limit.
* **Gain visibility:** The key list shows when each key was last used, so you can delete stale ones.

The gateway treats whoever holds the key as the caller.

To create a key, you provide a name and choose a holder: a user, an agent, or a [project](#projects). You can also add a new user or agent inline.

You can create a key in two ways:

* Have {{site.ai_gateway}} generate the key. The key is shown once, after you create it.
* Set your own key value.

In both cases, you choose an expiry of 30 days, 90 days, 1 year, or never.

The key list shows each key's name, holder, type, status, expiry, last used date, and creation date. You can filter the list by type and status, and delete one or several keys at once. Rotating a key isn't supported. To rotate a key, create a new one and delete the old one.

## Roles and permissions

What you can see and do in access management depends on your role. The following table lists what each role can do.

{% table %}
columns:
  - title: Area
    key: area
  - title: Admin
    key: admin
  - title: Team manager
    key: manager
  - title: Individual
    key: individual
rows:
  - area: Users and org chart
    admin: Create, import, edit, deactivate, and delete users. View the org chart.
    manager: No access.
    individual: No access.
  - area: Agents
    admin: Create agents directly.
    manager: Request an agent. The request is sent to the platform team.
    individual: Request an agent. The request is sent to the platform team.
  - area: Groups and projects
    admin: View all groups and projects. Create, edit, and delete groups and projects. Add or remove members. Export groups as a CSV.
    manager: View the groups and projects they belong to or manage.
    individual: View the groups and projects they belong to.
  - area: Identity providers
    admin: Add, edit, and delete identity providers.
    manager: No access.
    individual: No access.
  - area: Token Vault
    admin: Set up and manage Token Vault and its credential providers.
    manager: No access.
    individual: No access.
  - area: Virtual keys
    admin: View all keys. Create keys for any holder.
    manager: View keys they hold, and keys held by the groups and projects they belong to or manage.
    individual: View the keys they hold.
{% endtable %}
