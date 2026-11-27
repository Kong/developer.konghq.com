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

description: "How to add users and agents, create teams and groups, and manage access to {{site.ai_gateway}} resources."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "Principals"
    url: /identity/principals/
  - text: "AI Vaults"
    url: /ai-gateway/entities/ai-vault/
  - text: "AI Consumers"
    url: /ai-gateway/entities/ai-consumer/
  - text: "AI Auth Strategies"
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: "Token Vault"
    url: /identity/token-vault/
  - text: "Virtual keys"
    url: /ai-access-management/virtual-keys/
  - text: "Org chart in {{site.ai_cost_management}}"
    url: /ai-cost-management/org-chart/
  - text: "{{site.konnect_short_name}} teams and roles"
    url: /konnect-platform/teams-and-roles/#access-management

faqs:
 
---

Access management allows you to define who can use your organization's resources, like [models](/ai-gateway/entities/ai-model/) or [MCP servers](/ai-gateway/entities/ai-mcp-server/), in {{site.ai_gateway}}.

Access management features define:

* Who can make requests to your {{site.ai_gateway}} resources.
* What they are allowed to do.
* Which limits apply to them.
* How your organization is structured.

Callers are [users](#users) or [agents](#agents). A [group](#groups) can hold a [virtual key](#virtual-keys). You can apply rules to each caller individually, or in bulk using groups.

## Users

A user is a person who is added to the system in one of the following ways:

{% table %}
columns:
  - title: Method
    key: method
  - title: Description
    key: description
  - title: Requirements
    key: requirements
rows:
  - method: "Manual creation"
    description: "An admin creates the user."
    requirements: "A user name and a user email."
  - method: "Org structure import"
    description: "An admin uploads a CSV file containing the org structure."
    requirements: "A CSV file with the required columns."
  - method: "Automatic user provisioning"
    description: "The user signs in for the first time and is created automatically."
    requirements: "An [identity provider](#identity-providers) with **Automatic user provisioning** enabled."
{% endtable %}

To stop a user from signing in while keeping their history, deactivate the user instead of deleting them.

Users imported from an org structure file are managed by that file:

* Their name and email are read-only.
* You can't delete them. If a later import no longer lists them, they are deactivated, not deleted.

{:.info}
> To change imported users, import an updated org chart.

You can view all users in one searchable table. Search matches on the user's name. You can filter the table by team and status, and show or hide columns such as metadata and labels.

Open a user to see their details. The **Provisioned by** field shows how the user was added, for example **Imported** for users from an [org structure import](#import-an-org-structure).

### Teams

Teams are created automatically when you import an org chart that groups users into teams. They can't be created manually, and you can't manually assign a user to an existing team.

Teams can be nested under a parent team.

### Import an org structure

To add users and teams in bulk, upload your org structure as a CSV file from the org chart: in the {{site.konnect_short_name}} sidebar, click **Cost Management**, then click **Org Chart**.

Because teams change only through import, upload the file again whenever your org structure changes. Users that the new file no longer lists are deactivated, not deleted.

See [Org chart in {{site.ai_cost_management}}](/ai-cost-management/org-chart/) for the file format, the upload steps, and how to set spend limits on teams and people.

## Agents

An agent is a software system that calls your {{site.ai_gateway}} resources, either on its own behalf or on behalf of a user. For example, an agent deployed to AWS AgentCore that calls a model and an MCP server is an agent.

An agent has its own identity, separate from the users who manage it:

* **Own access rules:** The rules that apply to an agent are independent from the rules that apply to the users who manage it.
* **Own credentials:** An agent authenticates with its own credentials like [virtual keys](#virtual-keys) to call models, or with an OAuth client from your identity provider to call MCP servers.
* **Own attribution:** {{site.ai_gateway}} attributes requests to the agent that makes them, not to the users who manage it.

When an agent acts on behalf of a user (for example, when it authenticates to an MCP server for that user), {{site.ai_gateway}} identifies the agent and the user separately. An access decision can depend on the user, the agent, or both.

Admins create agents manually. An agent has a name, a description, labels, and metadata. After you create an agent, you can:

* Edit its details.
* Add it to one or more [groups](#groups).
* Issue it a [virtual key](#virtual-keys) by choosing the agent as the key holder.
* See its virtual keys, groups, and OAuth credentials in the agent's details.
* Deactivate it to stop it from authenticating, and reactivate it later without creating new credentials.
* Delete it.

In the {{site.identity}} API, an agent is a [principal](/identity/principals/) with `type` set to `agent`.

### Users vs agents

Users and agents are both callers, but they represent different things and are managed differently:

{% table %}
columns:
  - title: Aspect
    key: aspect
  - title: User
    key: user
  - title: Agent
    key: agent
rows:
  - aspect: "**Represents**"
    user: "A person."
    agent: "A software system that acts on its own behalf or on behalf of a user."
  - aspect: "**Creation**"
    user: "Created manually by an admin, [imported from an org structure](#import-an-org-structure), or [provisioned automatically](#identity-providers) on first sign-in."
    agent: "Created manually by an admin."
  - aspect: "**Authentication**"
    user: "Signs in through an [identity provider](#identity-providers), or uses a [virtual key](#virtual-keys)."
    agent: "Uses a [virtual key](#virtual-keys), or an OAuth client from an identity provider."
  - aspect: "**Groups**"
    user: "Can belong to one or more [groups](#groups)."
    agent: "Can belong to one or more [groups](#groups)."
  - aspect: "**Teams**"
    user: "Can belong to a [team](#teams) through an org structure import."
    agent: "Can't belong to a team."
  - aspect: "**Access rules**"
    user: "Apply to the user."
    agent: "Apply to the agent, independently from the users who manage it."
  - aspect: "**Deactivation**"
    user: "Deactivate to stop the user from signing in while keeping their history."
    agent: "Deactivate to stop the agent from authenticating. Reactivate to restore access with its existing credentials."
{% endtable %}

## Groups

A group is a list of users and agents that share the same rules. Instead of setting rules on each member, you set them once on the group. For example, you can select a group when setting up a spend limit.

Admins create groups manually. A group has a name, a description, labels, and metadata. A group can't contain another group.

Add users and agents to a group from the group's detail page. You can also add or remove a user or an agent from one or more groups from its details.

### Groups vs teams

Both groups and teams collect users, but they are created and managed differently:

{% table %}
columns:
  - title: Aspect
    key: aspect
  - title: Group
    key: group
  - title: Team
    key: team
rows:
  - aspect: "**Purpose**"
    group: "Share the same rules across a list of users and agents, for example in a spend limit."
    team: "Reflect your org structure."
  - aspect: "**Creation**"
    group: "Created manually by an admin."
    team: "Created automatically when you [import an org structure](#import-an-org-structure). Can't be created manually."
  - aspect: "**Membership**"
    group: "Users and agents. Add or remove members from the group's detail page or from the member's details."
    team: "Users only. Set by the org structure import."
  - aspect: "**Nesting**"
    group: "A group can't contain another group."
    team: "A team can be nested under a parent team."
  - aspect: "**Changes**"
    group: "Edit manually at any time."
    team: "Change only through import."
{% endtable %}

## Identity providers

An identity provider is an external service, like Okta or Auth0, that signs the tokens users present when they sign in. {{site.konnect_short_name}} trusts the providers you list and uses them to verify that those tokens are genuine.

When you add an identity provider, you give it a name and an issuer URL. You can also:

* [Enable automatic user provisioning](/identity/token-vault/#trusted-idp) so that users are created the first time they sign in. Automatic user provisioning doesn't give users access to the credentials stored in [Token Vault](/identity/token-vault/). An admin must grant that access explicitly.
* Choose whether Token Vault trusts the provider.


To stop Token Vault from relying on a provider, remove its trust. To delete a provider you no longer need, delete it from the list.

[Token Vault](#token-vault) needs at least one trusted identity provider to verify callers.

To learn more, see [Token Vault's trusted IdP](/identity/token-vault/#trusted-idp).

## Token Vault

Token Vault stores credentials for third-party services so that {{site.ai_gateway}} can call them on behalf of a caller. When a caller acts on behalf of a user, Token Vault checks that user against a trusted identity provider before releasing credentials.

To set it up:

1. Add at least one trusted [identity provider](#identity-providers).
1. Configure how Token Vault authenticates with this provider.
1. Create credential providers. A credential provider uses either OAuth or a static API key.

When you set up an [MCP server](/ai-gateway/entities/ai-mcp-server/), you can choose a credential provider for outbound authentication as an alternative to pass-through. To see the credentials that Token Vault holds for a user, open the user's details and go to **Remote credentials**.

To learn more, see [Token Vault](/identity/token-vault/).

## Virtual keys

A virtual key is an API key that lets a caller use {{site.ai_gateway}}.
A [user](#users), an [agent](#agents), or a [group](#groups) holds each key, and requests made with the key are attributed to that holder. The provider API keys stay in [Token Vault](#token-vault) instead of in your apps.

See [Virtual keys](/ai-access-management/virtual-keys/).

