---
title: Use LiteLLM with AI Proxy with {{site.ai_gateway}}
content_type: how_to
permalink: /how-to/use-litellm-with-ai-proxy/
related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Connect your LiteLLM integrations with {{site.ai_gateway}} with no code changes.

products:
  - ai-gateway
  - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy
  - key-auth

entities:
  - service
  - route
  - plugin

tags:
    - ai
    - openai

tldr:
    q: How can I use LiteLLM integrations with {{site.ai_gateway}}?
    a: You can configure LiteLLM to to use your {{site.ai_gateway}} Route by replacing the `base_url` parameter in the [LiteLLM API call](https://docs.litellm.ai/docs/completion/#basic-usage) with your {{site.base_gateway}} proxy URL.

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

published: false
---

## Configure the AI Proxy plugin

Enable the [AI Proxy](/plugins/ai-proxy/) plugin with your OpenAI API key and model details to route LiteLLM OpenAI-compatible requests through {{site.ai_gateway}}. In this example, we'll use the `gpt-4.1` model from OpenAI:

{% entity_examples %}
entities:
    plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_key}
        model:
          provider: openai
          name: gpt-4.1
variables:
  openai_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Add authentication

To secure access to your Route, create a Consumer and set up an authentication plugin:

{:.info}
> LiteLLM expects authentication as an `Authorization` header with a value starting with `Bearer`.
You can use plugins like [OAuth 2.0 Authentication](/plugins/oauth2/) or [OpenID Connect](/plugins/openid-connect/) to generate Bearer tokens. In this example, for testing purposes, we'll recreate this pattern using the [Key Authentication](/plugins/key-auth/) plugin.

{% entity_examples %}
entities:
    plugins:
    - name: key-auth
      route: example-route
      config:
        key_names:
        - Authorization
    consumers:
    - username: ai-user
      keyauth_credentials:
      - key: Bearer my-api-key
{% endentity_examples %}

## Install LiteLLM

Install the LiteLLM Python SDK:

{% navtabs "litellm" %}
{% navtab "WSL2, Linux, macOS native" %}
```sh
pip3 install -U litellm
```

{% endnavtab %}

{% navtab "macOS, with Python installed via Homebrew" %}
Create a virtual environment, then install the Python SDK:
```sh
python3 -m venv .venv
source .venv/bin/activate
pip install -U litellm
```

{% endnavtab %}
{% endnavtabs %}

## Create a LiteLLM script

Use the following command to create a file named `app.py` containing a LiteLLM Python script:

```sh
cat <<EOF > app.py
import litellm

kong_url = "http://127.0.0.1:8000"
kong_route = "anything"

response = litellm.completion(
    model="gpt-4.1",
    messages=[{"role": "user", "content": "What are you?"}],
    api_key="my-api-key",
    base_url=f"{kong_url}/{kong_route}"
)

print(f"$ ChainAnswer:> {response['choices'][0]['message']['content']}")
EOF
```
{: data-deployment-topology="on-prem" }

```sh
cat <<EOF > app.py
import litellm
import os

kong_url = os.environ['KONNECT_PROXY_URL']
kong_route = "anything"

response = litellm.completion(
    model="gpt-4.1",
    messages=[{"role": "user", "content": "What are you?"}],
    api_key="my-api-key",
    base_url=f"{kong_url}/{kong_route}"
)

print(f"$ ChainAnswer:> {response['choices'][0]['message']['content']}")
EOF
```
{: data-deployment-topology="konnect" }

With the `base_url` parameter, we can override the OpenAI base URL that LiteLLM uses by default with the URL to our {{site.base_gateway}} Route. This allows proxying requests and applying {{site.base_gateway}} plugins while still using LiteLLM’s API interface.

In the `api_key` parameter, we'll add the API key we created, without the `Bearer` prefix, which LiteLLM adds automatically in the request header.

## Validate

Run your script to validate that LiteLLM can access the Route:

```sh
python3 ./app.py
```

The response should look like this:

```sh
ChainAnswer:> I'm an artificial intelligence (AI) assistant created by OpenAI. I'm designed to help answer questions, provide information, write content, and assist with a wide variety of tasks through natural conversation. You can think of me as a type of intelligent computer program that uses language models to understand and respond to your messages. If you have any questions or need help with something, just let me know!
```
{:.no-copy-code}