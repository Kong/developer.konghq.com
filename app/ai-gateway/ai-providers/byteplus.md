---
title: "BytePlus ModelArk provider"
layout: reference
content_type: reference
description: Reference for supported capabilities and configuration for the BytePlus ModelArk provider
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/byteplus/

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
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: BytePlus ModelArk documentation
    url: https://docs.byteplus.com/en/docs/ModelArk
---

<!--
TODO(AI-119 OQ1): the runtime capability matrix isn't confirmed. Verify image and video generation before GA.
TODO(AI-119 OQ2): confirm whether the target `region` is an enum or a free string, and document the accepted values.
TODO(AI-119): no BytePlus logo SVG exists in the repo. Add app/assets/icons/byteplus.svg and the icon cards in ai-providers.yaml and ai-provider.md.
-->

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="BytePlus ModelArk" %}

## Configure a {{ provider.name }} provider {% new_in 2.4 %}

To use {{ provider.name }} with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/).
You can then route [AI Models](/ai-gateway/entities/ai-model/) to {{ provider.name }}.

Create an AI Model Provider entity to store your {{ provider.name }} API key.
{{ provider.name }} authenticates with an `Authorization: Bearer` header:

{% entity_example %}
type: model-provider
data:
  display_name: BytePlus ModelArk Production
  name: my-byteplus-account
  type: byteplus
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: ${key}
variables:
  key:
    value: $BYTEPLUS_API_KEY
    secret: true
    description: "The API key used to connect to BytePlus ModelArk. Include the `Bearer` prefix, for example `Bearer <your-api-key>`."
{% endentity_example %}

## Configure a {{ provider.name }} model {% new_in 2.4 %}

{{ provider.name }} supports chat completions, the Responses API, Messages, and embeddings through the OpenAI format, with streaming. It also supports image and video generation.

Set the target `name` to a {{ provider.name }} model ID, for example `seed-1-6-250615`, or to an inference endpoint ID, for example `ep-20250101000000-abcde`. {{site.ai_gateway}} passes the name to {{ provider.name }} unchanged.

{% entity_example %}
type: model
data:
  display_name: Seed 1.6 on BytePlus ModelArk
  name: seed-1-6
  type: model
  capabilities:
    - generate
  config:
    route:
      paths:
        - /byteplus
  targets:
    - name: seed-1-6-250615
      provider: my-byteplus-account
      config:
        type: byteplus
        region: ap-southeast
{% endentity_example %}

## Region

By default, {{site.ai_gateway}} sends requests to `https://ark.REGION.bytepluses.com/api/v3`. Set the optional target `region` field to choose the region. The default is `ap-southeast`.

To use a custom base URL, set `upstream_url` on the target. When `upstream_url` is set, {{site.ai_gateway}} ignores `region`.
