---
title: "Access management concepts"
content_type: reference
layout: reference
permalink: /ai-access-management/concepts/
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

description: "Learn what users, groups, identity providers, Token Vault, and virtual keys are in {{site.ai_gateway}} access management, and how they relate to each other."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "Principals"
    url: /identity/principals/
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

You can view all users in one searchable table. Search matches on user name. You can filter the table by team and status, and show or hide columns such as metadata and labels.

Open a user to see their details, including the groups and teams they belong to and their virtual keys. The details also show where the user came from (created manually, [imported](#import-an-org-structure), or from the Developer Portal). For imported users, the details show when they were last imported.

### Teams

You can assign users to a team. Teams can't be created manually. They are created when you import an org chart that groups users into teams. Teams can be nested under a parent team.

### Import an org structure

To add users and teams in bulk, upload your org structure as a CSV file that contains the required columns:

* `external_id`
* `email`
* `given_name`: The user's first name.
* `family_name`
* `manager_external_id`: Identifies who the user reports to, which the importer uses to build teams.

The first upload creates all the people and teams it lists.

Because teams change only through import, upload the file again whenever your org structure changes. Users that the new file no longer lists are deactivated, not deleted.

## Groups

A group is a list of users that share the same rules. Instead of setting rules on each member, you set them once on the group. For example, you can select a group when setting up a spend limit.

Admins create groups manually. A group has a name, a description, labels, and metadata. A group can't contain another group.

Add users to a group from the group's detail page. You can also add or remove a user from one or more groups from the user's details.

## Identity providers

An identity provider is an external service, like Okta or Auth0, that signs the tokens users present when they sign in. Kong trusts the providers you list and uses them to verify that those tokens are genuine.

Users sign in through an identity provider.

When you add an identity provider, you give it a display name and an issuer URL. You can also:

* Enable JIT provisioning, so that users are created the first time they sign in. JIT provisioning is separate from Token Vault access.
* Choose whether Token Vault trusts the provider.

The identity providers list shows each provider's display name, issuer URL, and linked identities.

To stop Token Vault from relying on a provider, remove its trust. To delete a provider you no longer need, delete it from the list.

[Token Vault](#token-vault) needs at least one trusted identity provider to verify callers.

To learn more, see [Token Vault's providers](/identity/token-vault/#providers).

## Token Vault

Token Vault stores credentials for third-party services so that {{site.ai_gateway}} can call them on behalf of a caller. When a caller acts on behalf of a user, Token Vault checks that user against a trusted identity provider before releasing credentials.

To set it up:

1. Add at least one trusted [identity provider](#identity-providers).
1. Configure how Token Vault authenticates with this provider.
1. Create credential providers. A credential provider uses either OAuth or a static API key.

When you set up an [MCP server](/ai-gateway/entities/ai-mcp-server/), you can choose a credential provider for outbound authentication as an alternative to pass-through. You can view the credentials stored in the vault from the provider and identity provider detail pages.

To learn more, see [Token Vault](/identity/token-vault/).

## Virtual keys

A virtual key is an API key that lets a caller use {{site.ai_gateway}}. For example, for an organization that has one Anthropic API key, and wants to give access to Claude Code through {{site.ai_gateway}}: instead of sharing the real Anthropic API key to all the users, you generate a virtual key for each user. The user holds the virtual key, while the provider API keys stay in [Token Vault](#token-vault) instead of in your apps.

Use virtual keys to:

* **Reinforce API key security:** Virtual keys can be generated and deleted.
* **Attribute and control costs:** Requests made with a personal virtual key are attributed to the user who owns it. The user spend limits apply to that traffic.
* **Gain visibility:** The key list shows when each key was last used, so you can delete stale ones.

The gateway treats whoever holds the key as the caller.

To create a key, you provide a name and choose a user as the holder. You can also add a new user inline.

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
  - area: Groups
    admin: View all groups. Create, edit, and delete groups. Add or remove members. Export groups as a CSV.
    manager: View the groups they belong to or manage.
    individual: View the groups they belong to.
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
    manager: View keys they hold, and keys held by the groups they belong to or manage.
    individual: View the keys they hold.
{% endtable %}
