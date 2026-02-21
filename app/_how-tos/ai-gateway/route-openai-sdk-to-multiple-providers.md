---
title: Route OpenAI SDK requests to multiple providers
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: "AI Proxy Advanced: Multi-provider chat routing example"
    url: /plugins/ai-proxy-advanced/examples/sdk-two-routes/

permalink: /how-to/route-openai-sdk-to-multiple-providers

description: Configure separate Kong routes to direct OpenAI SDK requests to different LLM providers based on the base URL.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - anthropic
  - mistral
  - ai-sdks

tldr:
  q: How do I use a single OpenAI SDK client to route requests to different LLM providers through Kong?
  a: Create a route per provider with a regex path that captures the model name, then configure a separate AI Proxy Advanced plugin on each route with the corresponding provider and credentials. The SDK switches providers by changing the base URL.

tools:
  - deck

prereqs:
  inline:
    - title: Anthropic
      include_content: prereqs/anthropic
      icon_url: /assets/icons/anthropic.svg
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Overview

The [OpenAI Python SDK](https://platform.openai.com/docs/libraries) can talk to any provider that {{site.ai_gateway}} supports. [AI Proxy Advanced](/plugins/ai-proxy-advanced/) translates the OpenAI request format into the provider's native format and handles authentication.

To route requests to different providers, create a separate route for each provider. Each route has its own AI Proxy Advanced plugin instance with the correct provider config and credentials. The SDK switches between providers by changing the `base_url`, and the model name is captured from the URL path using a [template variable](/plugins/ai-proxy-advanced/#dynamic-model-and-options-from-request-parameters).

## Create the Service and Routes

Configure a [Service](/gateway/entities/service/) and a [Route](/gateway/entities/route/) for each provider. The regex path captures the model name from the SDK's request URL:

{% entity_examples %}
entities:
  services:
    - name: ai-providers-service
      url: http://localhost:8000
      routes:
        - name: anthropic-chat
          paths:
            - "~/anthropic/(?<model>[^#?/]+)/chat/completions$"
          methods:
            - POST
        - name: mistral-chat
          paths:
            - "~/mistral/(?<model>[^#?/]+)/chat/completions$"
          methods:
            - POST
{% endentity_examples %}

When the SDK sends a request to `/anthropic/claude-sonnet-4-20250514/chat/completions`, the route captures `claude-sonnet-4-20250514` into the `model` named group.

## Configure AI Proxy Advanced for the Anthropic route

Configure [AI Proxy Advanced](/plugins/ai-proxy-advanced/) on the `anthropic-chat` route. The `$(uri_captures.model)` template variable reads the model name from the URL path:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      route: anthropic-chat
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: x-api-key
              header_value: ${anthropic_api_key}
            model:
              provider: anthropic
              name: "$(uri_captures.model)"
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  anthropic_api_key:
    value: $ANTHROPIC_API_KEY
{% endentity_examples %}

## Configure AI Proxy Advanced for the Mistral route

Configure [AI Proxy Advanced](/plugins/ai-proxy-advanced/) on the `mistral-chat` route with Mistral credentials:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      route: mistral-chat
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${mistral_api_key}
            model:
              provider: mistral
              name: "$(uri_captures.model)"
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  mistral_api_key:
    value: $MISTRAL_API_KEY
{% endentity_examples %}

## Validate

Create a test script that sends requests to both providers through Kong. The SDK client is identical for both providers. Only the `base_url` and `model` change:
```bash
cat <<EOF > test_multi_provider.py
from openai import OpenAI

kong_url = "http://localhost:8000"

providers = [
    {"base_url": f"{kong_url}/anthropic/claude-sonnet-4-20250514", "model": "claude-sonnet-4-20250514"},
    {"base_url": f"{kong_url}/mistral/mistral-small-latest", "model": "mistral-small-latest"},
]

for p in providers:
    client = OpenAI(
        api_key="test",
        base_url=p["base_url"]
    )
    response = client.chat.completions.create(
        model=p["model"],
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Provider: {p['base_url'].split('/')[-1]}, Model: {response.model}")
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }
```bash
cat <<EOF > test_multi_provider.py
from openai import OpenAI
import os

kong_url = os.environ['KONNECT_PROXY_URL']

providers = [
    {"base_url": f"{kong_url}/anthropic/claude-sonnet-4-20250514", "model": "claude-sonnet-4-20250514"},
    {"base_url": f"{kong_url}/mistral/mistral-small-latest", "model": "mistral-small-latest"},
]

for p in providers:
    client = OpenAI(
        api_key="test",
        base_url=p["base_url"]
    )
    response = client.chat.completions.create(
        model=p["model"],
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Provider: {p['base_url'].split('/')[-1]}, Model: {response.model}")
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

Run the script:
```bash
python test_multi_provider.py
```

You should see each request routed to the corresponding provider, confirming that a single SDK client can reach different LLM providers by changing the base URL.
