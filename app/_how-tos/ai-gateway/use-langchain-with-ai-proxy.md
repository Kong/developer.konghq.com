---
title: Use LangChain with AI Proxy in {{site.ai_gateway}}
permalink: /how-to/use-langchain-with-ai-proxy/
content_type: how_to
related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/

description: Connect your LangChain integrations with {{site.base_gateway}} with no code changes.

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
    q: How can use my LangChain integrations with {{site.ai_gateway}}?
    a: You can configure LangChain scripts to use your {{site.ai_gateway}} Route by replacing the `base_url` parameter in the [LangChain model instantiation](https://python.langchain.com/docs/integrations/chat/openai/#instantiation) with your proxy URL.

tools:
    - deck

prereqs:
  inline:
  - title: OpenAI
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
  - title: Python
    include_content: prereqs/python
    icon_url: /assets/icons/python.svg
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

## Configure the AI Proxy plugin

Enable the [AI Proxy](/plugins/ai-proxy/) plugin with your OpenAI API key and the model details. In this example, we'll use the GPT-4o model.

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
          name: gpt-4o
variables:
  openai_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Add authentication

To secure the access to your Route, create a Consumer and set up an authentication plugin.

{:.info}
> Note that LangChain expects authentication as an `Authorization` header with a value starting with `Bearer`.
You can use plugins like [OAuth 2.0 Authentication](/plugins/oauth2/) or [OpenID Connect](/plugins/openid-connect/) to generate Bearer tokens.
In this example, for testing purposes, we'll recreate this pattern using the [Key Authentication](/plugins/key-auth/) plugin.

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


## Install LangChain

Load the LangChain SDK into your Python dependencies:

{% validation custom-command %}
command: pip3 install -U langchain-openai
expected:
  return_code: 0
render_output: false
{% endvalidation %}

## Create a LangChain script

Use the following command to create a file named `app.py` containing a LangChain Python script:

```bash
cat <<EOF > app.py
from langchain_openai import ChatOpenAI

kong_url = "http://127.0.0.1:8000"
kong_route = "anything"

llm = ChatOpenAI(
    base_url=f"{kong_url}/{kong_route}",
    model="gpt-4o",
    api_key="my-api-key"
)

response = llm.invoke("What are you?")
print(f"$ ChainAnswer:> {response.content}")
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }

```bash
cat <<EOF > app.py
from langchain_openai import ChatOpenAI
import os

kong_url = os.environ['KONNECT_PROXY_URL']
kong_route = "anything"

llm = ChatOpenAI(
    base_url=f"{kong_url}/{kong_route}",
    model="gpt-4o",
    api_key="my-api-key"
)

response = llm.invoke("What are you?")
print(f"$ ChainAnswer:> {response.content}")
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

With the `base_url` parameter, we can override the OpenAI base URL that LangChain uses by default with the URL to our {{site.base_gateway}} Route. This way, we can proxy requests and apply {{site.base_gateway}} plugins, while also using LangChain integrations and tools.

In the `api_key` parameter, we'll add the API key we created, without the `Bearer` prefix, which is added automatically by LangChain.

## Validate

Run your script to validate that LangChain can access the Route:

{% validation custom-command %}
command: python3 ./app.py
expected:
  return_code: 0
render_output: false
{% endvalidation %}

The response should look like this:
```sh
ChainAnswer:> I am an AI language model created by OpenAI, designed to assist with understanding and generating human-like text based on the input I receive. I can help answer questions, provide explanations, and assist with a variety of tasks involving language. What would you like to know or discuss today?
```
{:.no-copy-code}


