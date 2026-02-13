---
title: Strip the model field from OpenAI SDK requests
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Pre-function
    url: /plugins/pre-function/

permalink: /how-to/strip-model-from-openai-sdk-requests

description: Use the [Pre-function](/plugins/pre-function/) plugin to remove the model field from the request body so AI Proxy Advanced controls model selection during load balancing.

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
  - pre-function

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - ai-sdks

tldr:
  q: How do I prevent the OpenAI SDK model field from conflicting with AI Proxy Advanced model selection?
  a: Add a Pre-function plugin that strips the model field from the request body before AI Proxy Advanced processes it. This lets the gateway control model selection through its balancer configuration.

tools:
  - deck

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

## Overview

[OpenAI-compatible SDKs](https://platform.openai.com/docs/libraries) always set the `model` field in the request body. This is a required parameter and can't be omitted.

[AI Proxy Advanced](/plugins/ai-proxy-advanced/) validates the body `model` against the plugin-configured model. If they don't match, the plugin rejects the request with `400 Bad Request: cannot use own model - must be: <configured-model>`. When load balancing across multiple models, the balancer may route to a target that doesn't match the SDK's `model` value, which triggers this error.

The fix is to use the [Pre-function](/plugins/pre-function/) plugin to strip the `model` field from the request body before AI Proxy Advanced processes it.

## Configure the Pre-function plugin

First, let's configure the [Pre-function](/plugins/pre-function/) plugin to removes the `model` field from the JSON request body to the LLM provider:

{% entity_examples %}
entities:
  plugins:
    - name: pre-function
      config:
        access:
          - |-
            local req_body = kong.request.get_body()
            req_body["model"] = nil
            kong.service.request.set_body(req_body)
{% endentity_examples %}

## Configure the AI Proxy Advanced plugin

Now, let's let's configure [AI Proxy Advanced](/plugins/ai-proxy-advanced/) with multiple targets to different OpenAI models. The balancer selects which target handles each request, independent of whatever model the SDK originally specified:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        balancer:
          algorithm: round-robin
          retries: 3
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o-mini
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Create a test script

Now, let's create a test script. Even though the SDK sends `model="gpt-4o"` in the body, the Pre-function plugin strips it. AI Proxy Advanced's balancer decides which model actually handles the request:

```bash
cat <<EOF > test_strip_model.py
from openai import OpenAI

kong_url = "http://localhost:8000"
kong_route = "anything"

client = OpenAI(
    api_key="test",
    base_url=f"{kong_url}/{kong_route}"
)

for i in range(4):
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Request {i+1}: {response.model}")
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }

```bash
cat <<EOF > test_strip_model.py
from openai import OpenAI
import os

kong_url = os.environ['KONNECT_PROXY_URL']
kong_route = "anything"

client = OpenAI(
    api_key="test",
    base_url=f"{kong_url}/{kong_route}"
)

for i in range(4):
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Request {i+1}: {response.model}")
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

## Validate the configuration

Now we can run the script created in the previous step:

```bash
python test_strip_model.py
```

With round-robin balancing and two targets, you should see the `response.model` value alternate between `gpt-4o` and `gpt-4o-mini` across the four requests, confirming that the gateway controls model selection regardless of what the SDK sends.