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

Intro

## How access management works

<!--
Access management answers two questions: who is making a request, and what are they allowed to do with it.
The "who" is a user or an agent. Groups let you give many of them the same rules at once. Identity providers are how Kong checks that someone is who they say they are.
Credentials work in two directions. A virtual key is what a user or agent shows to get into {{site.ai_gateway}} (inbound). Token Vault holds the credentials the gateway shows to other services on a user's behalf (outbound).
A virtual key has no rules of its own. It borrows the access rules, spend limits, and department of whoever holds it.
Optional: a small table with holder, inbound credential, and outbound credential. Add a diagram only if asked. -->

## Users

<!--
A user is a person. {{site.ai_gateway}} tracks the traffic that person sends to models and MCP servers, so it can apply access rules and spend limits to them.
Users get into the system in one of three ways: an admin uploads a CSV of the org chart, an admin creates them by hand, or they are created automatically the first time they log in through OIDC.
Once a user exists, they can hold virtual keys, belong to groups, and have a department and spend limits.
Users can also look after their own account: see how much they have spent, create and revoke their own keys, and sign up for or revoke their own Token Vault credentials.
Link to /identity/principals/ for more on how identities are stored. -->

## Agents

<!--
An agent is the identity record for a piece of software that calls models or MCP servers. It might act for itself, or on behalf of users.
Like a user, an agent has its own department and its own access rules. It also has its own credentials: an API key, an OIDC issuer and client, or both. It has administrators, and it can be linked to a Registry record.
Warn readers that this is not the same thing as an AI Agent. An AI Agent is a gateway entity, the thing agents get called through. An agent here is the caller. Link to /ai-gateway/entities/ai-agent/.
Do not say how agents get created until the Access Management team confirms whether admins create them or they come through Registry approval. -->

## Groups

<!--
A group is a list of users or agents that share the same rules. Instead of setting access and spend limits on each member, you set them once on the group and every member gets them.
Admins create groups by hand. A group cannot contain another group.
A group can hold a virtual key.
If no rule says a request is allowed, it is denied. When several rules apply to the same request: any explicit deny wins, otherwise any explicit allow wins, otherwise the request is denied.
Mention Projects here only if the team confirms they belong on this page. -->

## Identity Providers

<!--
An identity provider is an outside service, such as Okta or Auth0 (or one you run yourself), that signs the tokens people and agents present. Kong trusts the ones you list here and uses them to check those tokens are genuine.
When you set up outbound authentication in Token Vault, you pick from this same list.
New users who log in for the first time are created through these issuers.
Needs SME review: the sources have very little detail on this section. -->

## Token Vault

<!--
Summary then link to token vault page -->

## Virtual Keys

<!--
A virtual key is an API key that lets a user, agent, group, or project call {{site.ai_gateway}}. Whoever holds the key is who the gateway treats the caller as.
The key has no settings of its own. It uses the holder's access rules, spend limits, and department. If you need different limits, give the key to a different holder.
Today a key has no scope, spend cap, or throughput limit of its own. The only action on an existing key is revoke. To rotate a key, create a new one and revoke the old one. The key value is shown once, when it is created.
Logs and metrics show both the key that was used and its holder. -->
