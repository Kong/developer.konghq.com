---
title: "OpenAI-compatible and Anthropic-compatible providers"
layout: reference
content_type: reference
description: The openai-compatible and anthropic-compatible provider types connect {{site.ai_gateway}} to vendors that expose an OpenAI or Anthropic compatible API. Covers provider configuration, request routing, and analytics.
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/openai-anthropic-compatible/

works_on:
 - konnect

products:
  - ai-gateway

tools:
  - konnect-api
  - kongctl

tags:
  - ai

min_version:
  ai-gateway: '2.4'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Providers
    url: /ai-gateway/ai-providers/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: OpenAI provider
    url: /ai-gateway/ai-providers/openai/
  - text: Anthropic provider
    url: /ai-gateway/ai-providers/anthropic/
---

<!--
TODO(AI-166) open questions to resolve before GA:
OQ1: Is a provider_alias equal to a built-in provider type, such as `openai` or `anthropic`, rejected?
OQ2: Should provider_alias stay required, or default to the AI Model Provider `name`?
OQ3: How is a trailing `/v1` in base_url handled? Does the gateway strip it or append the path as is?
OQ4: What is the relationship to dedicated providers such as `baseten`? Which should users pick when both apply?
Also: the AI Gateway 2.4 release isn't in app/_data/products/ai-gateway.yml yet. Confirm min_version
resolves correctly once the release entry lands.
-->

The `openai-compatible` and `anthropic-compatible` provider types connect {{site.ai_gateway}} to a vendor that exposes an OpenAI or Anthropic compatible API but has no dedicated {{site.ai_gateway}} provider.
Without one, pointing the `openai` provider at the vendor with `upstream_url` attributes the vendor's traffic to OpenAI in analytics and logs.
You set the vendor's `base_url`, the authentication, and a `provider_alias` that identifies the vendor in telemetry.
Both types are configured on an [AI Model Provider](/ai-gateway/entities/ai-model-provider/).

The `openai-compatible` type uses the [OpenAI](/ai-gateway/ai-providers/openai/) API format.
The `anthropic-compatible` type uses the [Anthropic](/ai-gateway/ai-providers/anthropic/) API format.

If a dedicated provider exists for your vendor, use it instead.
<!-- TODO(AI-166 OQ4): clarify the relationship to dedicated providers such as `baseten`. -->

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="OpenAI-compatible" compare_provider_name="Anthropic-compatible" variant_label="OpenAI-compatible" compare_variant_label="Anthropic-compatible" %}

## How requests are routed

Requests to a compatible provider go to the provider `base_url` plus the standard OpenAI or Anthropic path for the route type.
For example, with a `base_url` of `https://api.example-vendor.com`, a chat request goes to `https://api.example-vendor.com/v1/chat/completions`.
<!-- TODO(AI-166 OQ3): confirm how a trailing `/v1` in base_url is handled. Until then, omit the path from base_url. -->

The vendor must implement the endpoints that your [AI Model](/ai-gateway/entities/ai-model/) uses.

## Provider configuration

Set the following fields in the `config` of the [AI Model Provider](/ai-gateway/entities/ai-model-provider/). All fields are required.

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`auth`"
    description: |
      Authentication for the vendor. Set `type` to `basic` and provide either one header (`name` and `value`) or one query parameter (`name`, `value`, and `location`). Values can reference a secret in a vault.
  - field: "`base_url`"
    description: |
      The vendor's base URL, for example `https://api.example-vendor.com`. Must be an HTTP or HTTPS URI of 1 to 2048 characters.
  - field: "`provider_alias`"
    description: |
      A short name for the vendor, for example `example-vendor`. The alias is 1 to 64 characters of lowercase letters, numbers, and hyphens, and starts and ends with a letter or number (`^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`). It replaces the generic provider type in telemetry, as described in [Analytics and observability](#analytics-and-observability).
{% endtable %}
<!-- TODO(AI-166 OQ1): confirm whether a provider_alias that matches a built-in provider type is rejected. -->
<!-- TODO(AI-166 OQ2): confirm whether provider_alias stays required or defaults to the AI Model Provider name. -->

## Configure an OpenAI-compatible provider

The following example creates an AI Model Provider that sends requests to an example vendor with the `openai-compatible` type and reports `example-vendor` as the provider in telemetry:

{% entity_example %}
type: model-provider
data:
  display_name: Example Vendor OpenAI Compatible
  name: my-openai-compatible
  type: openai-compatible
  config:
    base_url: https://api.example-vendor.com
    provider_alias: example-vendor
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $VENDOR_API_KEY
    secret: true
    description: "The API key for the vendor. Include any prefix the vendor requires, for example `Bearer <your-api-key>`."
{% endentity_example %}

The following AI Model routes `/compatible-chat` to a vendor model through that provider.
Set the target `name` to the vendor's model ID and `config.type` to `openai-compatible`:

{% entity_example %}
type: model
data:
  display_name: Example Vendor Chat Model
  name: example-vendor-chat
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /compatible-chat
  targets:
    - name: VENDOR_MODEL_ID
      provider: my-openai-compatible
      config:
        type: openai-compatible
{% endentity_example %}

## Configure an Anthropic-compatible provider

To connect a vendor with an Anthropic compatible API, create an AI Model Provider with the `anthropic-compatible` type.
The following example authenticates with an `x-api-key` header:

{% entity_example %}
type: model-provider
data:
  display_name: Example Vendor Compatible
  name: my-anthropic-compatible
  type: anthropic-compatible
  config:
    base_url: https://api.example-vendor.com
    provider_alias: example-vendor
    auth:
      type: basic
      headers:
        - name: x-api-key
          value: ${key}
variables:
  key:
    value: $VENDOR_API_KEY
    secret: true
    description: "The API key for the vendor."
{% endentity_example %}

An `anthropic-compatible` target also accepts a `version` option.
{{site.ai_gateway}} sends it as the `anthropic-version` header.
The default is `2023-06-01`.
The following target sets the version explicitly:

```yaml
targets:
  - name: VENDOR_MODEL_ID
    provider: my-anthropic-compatible
    config:
      type: anthropic-compatible
      version: '2023-06-01'
```

## Target options

Targets of both types support the standard target options, such as `max_tokens`, `temperature`, `top_k`, `top_p`, costs, and `upstream_url`.
See the [AI Model entity](/ai-gateway/entities/ai-model/#targets) for the full list.
Set `input_cost` and `output_cost` so cost reporting reflects the vendor's pricing.

## Analytics and observability

{{site.ai_gateway}} reports the `provider_alias` value as the provider name in analytics, logs, and OpenTelemetry data.
The alias replaces the generic `openai-compatible` or `anthropic-compatible` type, so you can tell vendors apart even though they share a provider type.
