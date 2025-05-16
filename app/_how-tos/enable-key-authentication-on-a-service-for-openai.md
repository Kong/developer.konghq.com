---
title: Enable key authentication on an AI Gateway service for OpenAI
content_type: how_to
description: Enable the Key Authentication plugin on a Gateway Service to require Consumers to authenticate with an API key.

tldr:
    q: How do I secure a service with key authentication for OpenAI?
    a: Enable the Key Authentication plugin on the AI Gateway Service. This plugin requires all requests to include a valid API key before accessing the service, protecting it from unauthorized clients (such as frontends, partners, or apps). This way Key Auth will be your API access control layer guarding your AI service and ensuring only clients with a valid apikey can use your /llm/v1/chat route.

related_resources:
  - text: Authentication
    url: /gateway/authentication/
  - text: Key auth
    url: /plugins/key-auth/
  - text: AI Proxy plugin
    url: /plugins/ai-proxy/
  - text: AI Gateway
    url: /ai-gateway/
  - text: Store Mistral AI API key in config store
    url: /how-to/store-a-mistral-api-key-as-a-secret-in-konnect-config-store/
  - text: Store Mistral AI API keys in Google Cloud Secret
    url: /how-to/rotate-secrets-in-google-cloud-secret/
breadcrumbs:
  - /mcp/
permalink: "/mcp/authentication"

products:
    - gateway
    - ai-gateway

entities:
  - service
  - consumer
  - route

plugins:
  - key-auth
  - ai-proxy

tags:
  - authentication
  - key-auth

tools:
    - deck

works_on:
    - on-prem
    - konnect

prereqs:
  inline:
    - title: OpenAI
      content: |
        This tutorial uses the AI Proxy plugin with OpenAI. You'll need to [create an OpenAI account](https://auth.openai.com/create-account) and [get an API key](https://platform.openai.com/api-keys). Once you have your API key, create an environment variable:

        ```sh
        export OPENAI_KEY='<api-key>'
        ```
      icon_url: /assets/icons/openai.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.6'
---


## Configure the AI Plugin on the Service

Start by creating a service named `openai-chat-service` that proxies requests to OpenAI's Chat API using the AI Proxy Plugin:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      service: openai-chat-service
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer
        model:
          provider: openai
          name: gpt-4
          options:
            max_tokens: 512
{% endentity_examples %}

This configuration sets a **default OpenAI config** for all users accessing the service.


## Enable the Key Authentication plugin

Require API keys for any client accessing `openai-chat-service`:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: openai-chat-service
      config:
        key_names:
          - apikey

{% endentity_examples %}

This config instructs Kong to look for a key in the `apikey` header for all users/clients accessing the service.


##  Create a consumer with an OpenAI API Key

Create a consumer named `chat-client` and assign them an API key:

{% entity_examples %}
entities:
  consumers:
    - username: chat-client
      keyauth_credentials:
        - key: secret-chat-key
{% endentity_examples %}


## Customize AI Plugin Per Consumer

To override the default model behavior for `chat-client` (for example, more tokens or different temperature), attach the AI plugin directly to the consumer:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      consumer: chat-client
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer   # Optional: consumer-specific OpenAI key
        model:
          provider: openai
          name: gpt-4
          options:
            max_tokens: 1024
            temperature: 0.7
{% endentity_examples %}

{:.info}
> Use this if you want:
> * Per-consumer OpenAI API keys.
> * Different model parameters.
> * Rate-limiting or feature controls at the user level.


## Test the setup


{% navtabs "use-valid-api-key" %}
{% navtab "Valid request using key auth" %}

This request includes a valid API key and should succeed:

```
curl -X POST "$KONNECT_PROXY_URL/llm/v1/chat" \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -H "apikey: secret-chat-key" \
     --json '{
       "messages": [
         {
           "role": "system",
           "content": "You are a mathematician"
         },
         {
           "role": "user",
           "content": "What is 1+1?"
         }
       ]
     }'
```

**Expected response**: `200 OK`

{% endnavtab %}
{% navtab "Invalid request using key auth" %}

```
curl -X POST "$KONNECT_PROXY_URL/llm/v1/chat" \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -H "apikey: secret-chat-key" \
     --json '{
       "messages": [
         {
           "role": "system",
           "content": "You are a mathematician"
         },
         {
           "role": "user",
           "content": "What is 1+1?"
         }
       ]
     }'
```

**Expected response**: `401 Unauthorized`

{% endnavtab %}
{% endnavtabs %}
