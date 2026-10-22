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
  - text: "Principals and directories"
    url: /identity/principals/
  - text: "AI Agents"
    url: /ai-gateway/entities/ai-agent/
  - text: "AI Vaults"
    url: /ai-gateway/entities/ai-vault/
  - text: "AI Consumers"
    url: /ai-gateway/entities/ai-consumer/
---

Access management allows you to define who can use your organization's resources (like models or MCP servers) in {{site.ai_gateway}}.

## How access management works

Access management uses Kong Identity features to answer two questions:

* Who is making the request?
* What are they allowed to do with it?

You can give specific permissions to users individually or in bulk using [groups](/identity/groups/).

<!-- TODO: scoped to the Dogfood and M1.0 jobs in the "Kong Identity & Token Vault: Jobs to Be Done for AI-X M1" sheet (10/19 priority). Teams, org chart import, spend limits, projects, agent management, user deactivation, key rotation, and access rules are M1.1 or later. Add them as they ship. -->

## Users

A user is a person that gets into the system in one of two ways:

* An admin manually creates them.
* {{site.identity}} creates them automatically the first time they log in through OIDC.

Once a user exists, an admin can edit their details, add them to or remove them from groups, create virtual keys for them, or delete them. A user can also set their own virtual key.

You can view all users in one searchable table. Search matches on name only. You can filter the table by team, source, and status, and show or hide columns such as metadata and labels.

A user can have a cost center, which is a free-form string. {{site.ai_gateway}} doesn't keep a list of cost centers or validate the value.

For more on how identities are stored, see [Principals and directories](/identity/principals/).

## Agents

An agent is the identity record for a piece of software that calls models or MCP servers. It might act for itself, or on behalf of users.

An agent here is the caller. It's not the same thing as an [AI Agent](/ai-gateway/entities/ai-agent/), which is a {{site.ai_gateway}} entity that agents get called through.

<!-- TODO: do not say how agents get created until the Access Management team confirms. Agent management is M1.1 or later, but the M1.0 key creation flow lets you pick an agent as the key holder. -->

## Groups

A group is a list of users that share the same rules. Instead of setting rules on each member, you set them once on the group.

Admins create groups by hand. A group can't contain another group.

In the Konnect UI, you can:

* View groups in a list.
* Create a group with a name and description.
* Add labels and metadata to a group.
* Add users to a group, either from the groups screen or from a user.
* Edit a group and view its details.
* Delete a group.

Groups don't have a cost center.

## Identity Providers

An identity provider is an outside service, such as Okta or Auth0, that signs the tokens people and agents present. Kong trusts the ones you list and uses them to check that those tokens are genuine.

Token Vault needs at least one trusted identity provider to verify callers. You can add a provider, remove one you no longer want Token Vault to rely on, and review the table of trusted providers with their display names, issuer URLs, and linked identities.

<!-- TODO: needs SME review. The sources have very little detail on this section. -->

## Token Vault

Token Vault stores credentials so that {{site.ai_gateway}} can call outside services on behalf of a caller. Setting it up involves:

1. Adding at least one trusted [identity provider](#identity-providers).
1. Generating a public encryption key for the vault and setting the private key reference on a gateway.
1. Creating credential providers. A credential provider uses either OAuth or a static API key.

When you set up an MCP server, you can choose a credential provider for outbound authentication as an alternative to pass-through. You can view the credentials stored in the vault from the provider and identity provider detail pages.

<!-- TODO: link to the Token Vault page once it exists. -->

## Virtual Keys

A virtual key is an API key that lets a caller use {{site.ai_gateway}}. Whoever holds the key is who the gateway treats the caller as.

<!-- TODO: confirm the supported holder types for M1.0. The sheet lists user, agent, group, or project, but project and agent management are M1.1 or later. -->

You can create a key in two ways:

* Have {{site.ai_gateway}} generate the key.
* Set your own key value.

In both cases, you set an expiry. When you create a key for someone else, you pick the holder, can filter the holder list by users or agents, and can add a new user or agent inline.

The key list shows each key's holder, status, expiry, and creation date. You can revoke or delete a key. Rotating a key isn't supported yet. To rotate a key, create a new one and revoke the old one.
