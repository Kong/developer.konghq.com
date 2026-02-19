---
title: Forward OpenAI SDK model selection to AI Proxy Advanced in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Pre-function
    url: /plugins/pre-function/

permalink: /how-to/forward-openai-sdk-model-to-ai-proxy-advanced

description: Use the Pre-function plugin to extract the OpenAI SDK model value into a header, then reference it dynamically in AI Proxy Advanced configuration.

products:
  - ai-gateway
  - gateway

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
  q: How do I use the OpenAI SDK model parameter to dynamically configure AI Proxy Advanced?
  a: Add a Pre-function plugin that extracts the model from the request body into a custom header, then use the `$(headers.x-source-model)` template variable in the AI Proxy Advanced config to reference it dynamically.

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

[OpenAI-compatible SDKs](https://platform.openai.com/docs/libraries) always set the `model` field in the request body. This is a required parameter and can't be omitted.

[AI Proxy Advanced](/plugins/ai-proxy-advanced/) validates the body `model` against the plugin-configured model. If they don't match, the plugin rejects the request with `400 Bad Request: cannot use own model - must be: <configured-model>`.

Instead of hardcoding a model in the plugin config, you can let the SDK's model value drive the upstream selection. The [Pre-function](/plugins/pre-function/) plugin extracts the model into a custom header, and AI Proxy Advanced reads it through a [template variable](/plugins/ai-proxy-advanced/#dynamic-model-and-options-from-request-parameters). The validation passes because the resolved plugin model matches the body model.

## Configure the Pre-function plugin

First, let's configure the [Pre-function](/plugins/pre-function/) plugin to extract the `model` field from the request body and write it into a custom `x-source-model` header:

{% entity_examples %}
entities:
  plugins:
    - name: pre-function
      config:
        access:
          - |-
            local req_body = kong.request.get_body()
            local model = req_body.model
            kong.service.request.set_header("x-source-model", model)
{% endentity_examples %}

## Configure the AI Proxy Advanced plugin

Now, let's configure [AI Proxy Advanced](/plugins/ai-proxy-advanced/) to read the model name from the `x-source-model` header using the `$(headers.x-source-model)` template variable:

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
              name: "$(headers.x-source-model)"
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

The SDK sends `"model": "gpt-4o"` in the request body. Pre-function copies that value into the `x-source-model` header. AI Proxy Advanced resolves `$(headers.x-source-model)` to `gpt-4o` and uses it as the upstream model name. The validation passes because the body model and the resolved plugin model match.

## Create a script

Now, let's create a test script that sends requests with different model names. Each request reaches a different OpenAI model through the same route:

```bash
cat <<EOF > test_dynamic_model.py
from openai import OpenAI

kong_url = "http://localhost:8000"
kong_route = "anything"

client = OpenAI(
    api_key="test",
    base_url=f"{kong_url}/{kong_route}"
)

for model in ["gpt-4o", "gpt-4o-mini"]:
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Requested: {model}, Got: {response.model}")
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }
```bash
cat <<EOF > test_dynamic_model.py
from openai import OpenAI
import os

kong_url = os.environ['KONNECT_PROXY_URL']
kong_route = "anything"

client = OpenAI(
    api_key="test",
    base_url=f"{kong_url}/{kong_route}"
)

for model in ["gpt-4o", "gpt-4o-mini"]:
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": "What model are you? Reply with only your model name."}]
    )
    print(f"Requested: {model}, Got: {response.model}")
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

## Validate the configuration

Now, we can run the script we created in the previous step:

```bash
python test_dynamic_model.py
```

You should see each request routed to the corresponding OpenAI model. The `response.model` value should match the model name the SDK sent.
