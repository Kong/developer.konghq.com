---
title: "Virtual keys"
content_type: reference
layout: reference
permalink: /ai-access-management/virtual-keys/
works_on:
  - konnect

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
  - /ai-access-management/
tags:
  - ai
  - access-control
  - authentication

min_version:
  ai-gateway: '2.3'

description: "Issue API keys to users, agents, and groups so they can call {{site.ai_gateway}} models, MCP servers, and agents without sharing provider credentials."

related_resources:
  - text: "Access management concepts"
    url: /ai-access-management/concepts/
  - text: "AI Auth Strategies"
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: "Principals"
    url: /identity/principals/
  - text: "Token Vault"
    url: /identity/token-vault/
  - text: "{{site.konnect_short_name}} teams and roles"
    url: /konnect-platform/teams-and-roles/#access-management

faqs:
  - q: Can I rotate a virtual key?
    a: |
      No. To rotate a key, create a new key for the same holder, update your callers, and then delete the old key.
  - q: Can I see a virtual key's value after I create it?
    a: |
      No. {{site.konnect_short_name}} stores only a hash of the key, so the key value is shown once, when you create it. If you lose a key, create a new one and delete the old one.
  - q: Why does a deleted or expired key still work?
    a: |
      The data plane caches successful key lookups. A gateway that has cached a key may keep accepting it until the cache entry expires. See [Caching](#caching).
  - q: Can a team hold a virtual key?
    a: |
      No. Users, agents, and groups can hold virtual keys. Teams can't.
---

A virtual key is an API key that lets a caller use {{site.ai_gateway}}.
For example, an organization with one Anthropic API key can generate a virtual key for each Claude Code user instead of sharing the real key. The user holds the virtual key, while the provider API keys stay in [Token Vault](/identity/token-vault/) instead of in your apps.

Use virtual keys to:

* **Reinforce API key security:** Virtual keys can be generated and deleted, and the provider API key never reaches the caller.
* **Attribute and control costs:** Requests made with a virtual key are attributed to its holder: a [user](/ai-access-management/concepts/#users), an [agent](/ai-access-management/concepts/#agents), or a [group](/ai-access-management/concepts/#groups). The spend limits set on a user apply to that user's traffic.

The gateway treats whoever holds the key as the caller.

In the {{site.identity}} API, virtual keys are called API keys.

## How virtual keys work

1. An admin creates a virtual key for a holder in {{site.konnect_short_name}}. {{site.konnect_short_name}} stores a hash of the key, not the key itself.
1. The caller sends the key in a request to an [AI Model](/ai-gateway/entities/ai-model/), [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), or [AI Agent](/ai-gateway/entities/ai-agent/).
1. The entity's Key Auth [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) sends the key to {{site.identity}}, which checks that the key exists, hasn't expired, and belongs to an active holder.
1. {{site.ai_gateway}} identifies the request as coming from the key's holder, then calls the upstream with its own provider credentials.

By default, the AI Auth Strategy strips the key from the request (`hide_credentials: true`), so the virtual key isn't forwarded to the LLM provider or upstream service.

## Set up virtual keys

Virtual keys require {{site.identity}} and [principals](/identity/principals/). To use a virtual key with an [AI Model](/ai-gateway/entities/ai-model/), [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), or [AI Agent](/ai-gateway/entities/ai-agent/), do the following:

1. Assign the entity a Key Auth [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that authenticates against {{site.identity}} (`config.principals.enabled: true`). See [Principal mapping](/ai-gateway/entities/ai-auth-strategy/#principal-mapping).
1. Create the user, agent, or group that will hold the key.
1. [Create the virtual key](#create-a-virtual-key).
1. Send the virtual key in requests to the entity, in the header or query parameter that the AI Auth Strategy defines. By default, this is an `apikey` header or an `apikey` query parameter.
   Prefer the header: a query parameter is part of the request URL, so the key can end up in plain text in access logs.
   With the default key names, a key sent in an `Authorization: Bearer` header is rejected.

## Key holders

Every virtual key has exactly one holder. The holder is the identity that requests made with the key are attributed to.

{% table %}
columns:
  - title: Holder
    key: holder
  - title: Who the caller is
    key: caller
  - title: Default maximum keys
    key: limit
rows:
  - holder: "[User](/ai-access-management/concepts/#users)"
    caller: "The user."
    limit: "5"
  - holder: "[Agent](/ai-access-management/concepts/#agents)"
    caller: "The agent."
    limit: "5"
  - holder: "[Group](/ai-access-management/concepts/#groups)"
    caller: "The group, not any one of its members."
    limit: "100"
{% endtable %}

The limit counts all keys that the holder has, including expired keys. Delete keys you no longer need to free up space.

[Teams](/ai-access-management/concepts/#teams) can't hold virtual keys.

### Group keys

A group key authenticates as the group as a whole. Use a group key when several people or systems share one credential and you want their usage attributed to the group, for example a CI pipeline that several teams maintain.

Adding or removing group members doesn't affect the group's keys. A key holder can only be changed by deleting the key and creating a new one for a different holder.

### What happens to keys when the holder changes

{% table %}
columns:
  - title: Change
    key: change
  - title: Effect on the holder's virtual keys
    key: effect
rows:
  - change: "The holder is deactivated"
    effect: "The keys are kept, but they stop working. Reactivate the holder to restore access with the same keys."
  - change: "The holder is deleted"
    effect: "The keys are deleted."
  - change: "A member is added to or removed from a group"
    effect: "No effect. The group's keys belong to the group, not to its members."
{% endtable %}

## Create a virtual key

You can create a virtual key from any of the following places in {{site.konnect_short_name}}:

* In the sidebar, click **Access Management**, then **Virtual Keys**, then **New key**.
* From a user, agent, or group's details, in the **Virtual keys** section, click **New key**. The holder is preselected.
* From an AI Model, AI MCP Server, or AI Agent, in the **Connect** section, click **Manage virtual keys**. This opens the **Virtual keys** list.

When you create a key, you set the following:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: "**Key name**"
    description: "Optional. How you recognize the key in lists. Names don't need to be unique and can be up to 255 characters."
  - setting: "**Who holds it**"
    description: "The user, agent, or group that the key belongs to. Choose **A user or agent** or **A group or project**, then select the holder. If the user or agent doesn't exist yet, select **New user or agent** in the holder selector to create it."
  - setting: "**Key value**"
    description: |
      * **Kong generates the key:** {{site.konnect_short_name}} creates a random key.
      * **Use my own key:** Bring a key you already have. See [Custom key values](#custom-key-values).
  - setting: "**Expiry**"
    description: "How long the key works before you must replace it: 30 days, 90 days (default), 1 year, or never."
{% endtable %}

When {{site.konnect_short_name}} generates the key, it shows the key once, after you create it. Copy it before you close the dialog. {{site.konnect_short_name}} stores only a hash, so it can't show the key again.

### Custom key values

A custom key value must meet the following requirements:

* It is between 1 and 255 characters long.
* It is unique within the {{site.identity}} directory. Creating a key with a value that another key in the same directory already uses fails with a conflict error.
* It doesn't use the format of a key that {{site.konnect_short_name}} generates, for example `1_<id>_<secret>_<checksum>`.

Like generated keys, a custom key value can't be viewed after you create it.

### Use the {{site.identity}} API

Virtual keys are API keys in the [{{site.identity}} API](/api/konnect/kong-identity-principals/v2/).
Org Admins can use the following endpoints to manage them:

{% table %}
columns:
  - title: Holder
    key: holder
  - title: Endpoint
    key: endpoint
rows:
  - holder: "User or agent"
    endpoint: "`/v2/directories/{directoryId}/principals/{principalId}/api-keys`"
  - holder: "Group"
    endpoint: "`/v2/directories/{directoryId}/groups/{groupId}/api-keys`"
{% endtable %}

Set `type` to choose how the key is created:

* `v1`: {{site.konnect_short_name}} generates the key.
* `imported`: You provide the key in `secret`.

The following examples generate a key that expires on a set date, for each type of holder.
Users and agents are both principals, so their keys use the same endpoint with a different principal ID:

{% navtabs "virtual-key-holder" %}
{% navtab "Agent" %}

Create a key for an agent, using the ID of the agent's principal as `$AGENT_ID`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$AGENT_ID/api-keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: v1
  name: booking-agent-key
  expires_at: '2027-01-01T00:00:00Z'
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "User" %}

Create a key for a user, using the ID of the user's principal as `$USER_ID`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$USER_ID/api-keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: v1
  name: local-development
  expires_at: '2027-01-01T00:00:00Z'
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Group" %}

Create a key for a group, using the group's ID as `$GROUP_ID`:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups/$GROUP_ID/api-keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: v1
  name: ci-pipeline
  expires_at: '2027-01-01T00:00:00Z'
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

The response includes the key in `secret`. This is the only response that includes it.

The holders you can create a key for depend on your [role](/ai-management/roles-and-permissions/):

* **Org Admins** can create keys for any user, agent, or group, in {{site.konnect_short_name}} or with the API.
* **Individual Users** can only create keys for themselves, in {{site.konnect_short_name}}: in the sidebar, click **Access Management**, then **Virtual Keys**, then **New Key**.


## Manage virtual keys

The **Virtual keys** list in **Access Management** shows the virtual keys held by users, agents, and groups. Each user, agent, and group also lists its own keys in its details.

In the **Virtual keys** list, you can:

* Search keys by name.
* Filter keys by holder type.
* Sort keys by name, holder, expiry date, or creation date.
* Delete keys one at a time.

### Edit a key

You can't edit a virtual key in the {{site.konnect_short_name}} UI.

With the {{site.identity}} API, you can change a key's name and expiry date. To remove an expiry date, set `expires_at` to `null`. You can't change the key value or the holder.

### Delete a key

Deleting a virtual key revokes it, and anything using the key stops working. You can't undo a deletion.

A gateway that has cached the key may keep accepting it until its cache expires. See [Caching](#caching).

### Rotate a key

Rotating a key isn't supported. To rotate a key:

1. Create a new key for the same holder.
1. Update your callers to use the new key.
1. Delete the old key.

## Expiry

A key's expiry date is set when you create it. After that date, requests made with the key are rejected.

Expired keys aren't deleted automatically. They stay in the key list and count toward the holder's [key limit](#key-holders) until you delete them.

With the {{site.identity}} API, you can set `expires_at` to any date and time, and change it after you create the key.

## Caching

To avoid calling {{site.identity}} on every request, the data plane caches the result of each key lookup:

* **Valid keys** are cached for the [TTL set on the {{site.identity}} directory](/identity/directories/#lookup-caching) (10 minutes by default), or until the key expires, whichever comes first.
* **Invalid keys** are cached for the directory's negative TTL, so repeated requests with a bad key don't reach {{site.identity}}.

Because of this cache, a change to a key can take effect on a gateway after a delay:

* A deleted key, or a key whose holder was deactivated, may keep working until the gateway's cache entry expires.
* A changed expiry date may not take effect right away, because {{site.identity}} keeps serving the previous expiry date until its own cache entry expires.
* A key that you just created works right away, unless a gateway recently rejected the same value and cached that result.

## Authentication errors

When a request fails authentication with a virtual key, {{site.ai_gateway}} returns `401` with the same body in every case:

```json
{"message": "Unauthorized"}
```
{:.no-copy-code}

The response doesn't say which check failed, so check each of the following causes:

* The request doesn't include a key, or sends it in a header or query parameter that the AI Auth Strategy doesn't check, like `Authorization: Bearer`.
* The key doesn't exist, was deleted, or has expired.
* The key's holder is deactivated.
* The request sends the `apikey` header more than once.

A request that sends the key in both the `apikey` header and the `apikey` query parameter is accepted.

If the gateway can't reach {{site.identity}}, it returns `500` with the message `An unexpected error occurred`.
