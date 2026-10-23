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

# TODO: confirm min_version with the Access Management team
min_version:
  ai-gateway: '2.2'

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
---

Access management allows you to define who can use your organization's resources, like [models](/ai-gateway/entities/ai-model/) or [MCP servers](/ai-gateway/entities/ai-mcp-server/), in {{site.ai_gateway}}.

## How access management works

Access management uses Kong Identity features, such as [principals](/identity/principals/) and [auth servers](/identity/auth-servers/), to answer two questions:

* Who is making the request?
* What are they allowed to do?

You can give permissions to users individually, or in bulk using groups.

## Users

A user is a person who an admin adds to the system in one of two ways:

* An admin creates them manually, one at a time.
* An admin uploads a CSV file containing the org structure.

To create a user, you must provide the following:

* A name
* An email

Once a user exists, an admin can:

* Edit the user's details.
* Add the user to a group, or remove them from one.
* Create or delete [virtual keys](#virtual-keys) for the user. A user can also set their own virtual key.
* Link the user to a cost center.
* Delete or deactivate the user.

To stop a user from signing in while keeping their history, deactivate the user instead of deleting them.

{:.warning}
> You can't deactivate a user imported from a CSV file. To update the users, import an updated org chart.

An admin can view all users in one searchable table. Search matches on name only. You can filter the table by team, source, and status, and show or hide columns such as metadata and labels.

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
    users: Manually, or through an org structure import.
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

A group is a list of users that share the same rules. Instead of setting rules on each member, you set them once on the group.

Admins create groups manually. A group can't contain another group.

In the {{site.konnect_short_name}} UI, you can:

* View groups in a list.
* Create a group with a name and description.
* Add labels and metadata to a group.
* Add users to a group, either from the groups screen or from a user.
* Edit a group and view its details.
* Delete a group.

Groups don't have a cost center.

## Identity providers

An identity provider is an external service, such as Okta or Auth0, that signs the tokens people and agents present. Kong trusts the providers you list and uses them to verify that those tokens are genuine.

[Token Vault](#token-vault) needs at least one trusted identity provider to verify callers. You can add a provider, remove one you no longer want Token Vault to rely on, and review the table of trusted providers with their display names, issuer URLs, and linked identities.

To learn more, see [Token Vault's providers](/identity/token-vault/#providers).

## Token Vault

Token Vault stores credentials so that {{site.ai_gateway}} can call external services on behalf of a caller. To set it up:

1. Add at least one trusted [identity provider](#identity-providers).
1. Generate a public encryption key for the vault and set the private key reference on a gateway.
1. Create credential providers. A credential provider uses either OAuth or a static API key.

When you set up an [MCP server](/ai-gateway/entities/ai-mcp-server/), you can choose a credential provider for outbound authentication as an alternative to pass-through. You can view the credentials stored in the vault from the provider and identity provider detail pages.

To learn more, see [Token Vault](/identity/token-vault/).

## Virtual keys

A virtual key is an API key that lets a caller use {{site.ai_gateway}}. For example, instead of adding an Anthropic API key to an agent, you generate a virtual key for the agent. The agent uses the virtual key, while the provider API keys stay in [Token Vault](#token-vault) instead of in your apps.

Use virtual keys to:

* **Reinforce API key security:** Virtual keys can be generated and revoked cleanly.
* **Enforce and monitor costs:** You can link each virtual key to a cost center and set a spend limit.
* **Gain visibility:** The key list shows when each key was last used, so you can delete stale ones.

The gateway treats whoever holds the key as the caller.

You can create a key in two ways:

* Have {{site.ai_gateway}} generate the key.
* Set your own key value.

In both cases, you set an expiry. When you create a key for someone else, you pick the holder. You can filter the holder list by users or agents, and add a new user or agent inline.

The key list shows each key's holder, status, expiry, and creation date. You can revoke or delete a key. Rotating a key isn't supported. To rotate a key, create a new one and revoke the old one.
