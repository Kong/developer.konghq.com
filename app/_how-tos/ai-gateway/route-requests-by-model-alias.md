---
title: Route requests to different models using model aliases
permalink: /how-to/route-requests-by-model-alias/
content_type: how_to

description: Use model aliases in the AI Proxy Advanced plugin to route requests to different upstream models based on the model field in the request body

breadcrumbs:
  - /ai-gateway/

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - routing

tldr:
  q: How do I route AI requests to different models based on the model field in the request body?
  a: Configure the AI Proxy Advanced plugin with multiple targets, each with a unique `model_alias`. When a request arrives, Kong matches the model field in the body to the alias and routes to the corresponding target.

tools:
  - deck

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the AI Proxy Advanced plugin

The `model_alias` field on each target lets you decouple the model name clients send from the actual provider model. Clients request a logical name like `powerful` or `fast`, and {{site.base_gateway}} routes to the matching upstream model.

Configure the [AI Proxy Advanced plugin](/plugins/ai-proxy-advanced/) with two targets, each mapped to a different OpenAI model through a `model_alias`:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              model_alias: powerful
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o-mini
              model_alias: fast
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

When a client sends `"model": "powerful"` in the request body, {{site.base_gateway}} matches it to the first target and routes the request to `gpt-4o`. A request with `"model": "fast"` routes to `gpt-4o-mini`.

## Validate

Send a request with `"model": "powerful"` to verify that {{site.base_gateway}} routes it to `gpt-4o`:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    model: powerful
    messages:
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}

Send a second request with `"model": "fast"` to confirm routing to `gpt-4o-mini`:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    model: fast
    messages:
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}

Both requests use the same Route. Check the `model` field in the JSON response object to confirm which upstream model handled each request. The provider sets this field, so it reflects the actual model used (`gpt-4o` or `gpt-4o-mini`), regardless of the alias the client sent.
