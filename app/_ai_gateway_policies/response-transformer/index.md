---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Modify the response from an AI Model, AI Agent, or AI MCP Server before {{site.ai_gateway}} returns it to the client.'
categories:
  - transformations
tags:
  - transformations
  - ai
search_aliases:
  - response-transformer
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
---

Clients can receive headers or JSON properties that you don't want to expose, or lack fields they expect.
The Response Transformer [AI Policy](/ai-gateway/entities/ai-policy/) changes the response from an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) before {{site.ai_gateway}} returns it to the client.
You can remove headers or JSON properties, rename or replace values, and add fields.

## How does the Response Transformer Policy work?

The Response Transformer Policy supports five operations on response headers and on the properties of a JSON response body.
{{site.ai_gateway}} runs the operations in the following order:

1. [`remove`](/ai-gateway/policies/response-transformer/reference/#schema--config-remove): Deletes headers or JSON properties.
1. [`rename`](/ai-gateway/policies/response-transformer/reference/#schema--config-rename): Changes the name of a header or JSON property.
1. [`replace`](/ai-gateway/policies/response-transformer/reference/#schema--config-replace): Sets a new value only for a header or JSON property that already exists.
1. [`add`](/ai-gateway/policies/response-transformer/reference/#schema--config-add): Creates a header or JSON property. {{site.ai_gateway}} skips the entry when the header or property already exists.
1. [`append`](/ai-gateway/policies/response-transformer/reference/#schema--config-append): Adds a header with the same name as an existing header, or adds a value to a JSON property. When the JSON property isn't an array, {{site.ai_gateway}} converts it to an array that contains the existing value and the new value. When the property doesn't exist, {{site.ai_gateway}} creates an array with the new value.

Because `remove` runs first, you can remove a property and then `add` it with a new value in the same configuration.
Because `rename` runs before `add`, the original name is available after a rename, so an `add` for that name creates a new property.

### Specify headers and JSON properties

Each Response Transformer operation takes a `headers` list and a `json` list.
Write each entry as `name:value`.
For `rename`, write `old_name:new_name`.
For `remove`, write only the name.

JSON entries match top-level properties of the response body only.
For example, the entry `n.deep:1` adds a property named `n.deep`.

The policy changes JSON response bodies whose top level is an object.
It leaves response bodies of other types unchanged, such as `text/plain`, `text/event-stream`, and JSON arrays.
{{site.ai_gateway}} still applies header changes to these responses.

When it changes a JSON body, {{site.ai_gateway}} serializes the body again, so the property order and whitespace can differ from the upstream response.

### Set the type of a JSON value

By default, {{site.ai_gateway}} writes values from `add`, `replace`, and `append` as strings.
To write a number or a boolean, set [`json_types`](/ai-gateway/policies/response-transformer/reference/#schema--config-add-json-types) to a list of `number`, `boolean`, or `string`.
Each type applies to the `json` entry at the same position in the list.

## Examples

The following example adds the `X-Gateway: kong` header to every response:

{% entity_example %}
type: policy
data:
  name: response-transformer-add-header
  display_name: Response Transformer add header
  type: response-transformer
  global: true
  config:
    add:
      headers:
        - "X-Gateway:kong"
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

The following example removes the `custom_property` property from JSON responses:

{% entity_example %}
type: policy
data:
  name: response-transformer-remove-json-property
  display_name: Response Transformer remove JSON property
  type: response-transformer
  global: true
  config:
    remove:
      json:
        - custom_property
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

The following example adds `retries: 3` as a number and `cached: true` as a boolean:

{% entity_example %}
type: policy
data:
  name: response-transformer-typed-json
  display_name: Response Transformer typed JSON
  type: response-transformer
  global: true
  config:
    add:
      json:
        - "retries:3"
        - "cached:true"
      json_types:
        - number
        - boolean
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Scopes

Apply the Response Transformer Policy globally to change every response on the data plane, or attach it to an AI Model, an AI Agent, an AI MCP Server, an AI Consumer, or an AI Consumer Group to change responses for that entity only.
Use a global policy to apply one change everywhere, such as removing an internal header.
Use an entity scope when only one entity or group of clients needs a different response shape.
A global policy changes responses from every entity, so use a [`condition`](/ai-gateway/entities/ai-policy/#conditional-ai-policy-execution) or an entity scope when only some clients or entities need the change.

AI Consumer and AI Consumer Group scopes apply only to authenticated requests, because authentication runs before the policy.

{:.warning}
> **AI Model scope:** At AI Model scope, the policy changes response headers but does not change JSON response bodies.
>
> This applies to a policy attached to an AI Model and to a global policy on responses from an AI Model.
> The control plane accepts the configuration and the request succeeds, so {{site.ai_gateway}} silently does not apply the body changes.
> JSON body changes work for AI Agents and AI MCP Servers.

If a global Response Transformer Policy and one attached to an entity both apply to a request, only the entity-scoped policy runs.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

{% include md/ai-gateway/v2/policies/response-transformers-comparison.md %}
