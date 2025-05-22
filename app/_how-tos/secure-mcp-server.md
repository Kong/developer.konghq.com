---
title: Securing MCP server traffic
content_type: how_to
description: Secure the MCP service with Key Authentication, load balancing, and rate limiting using Kong plugins.
breadcrumbs:
  - /mcp/
permalink: /mcp/secure/

tldr:
  q: How do I secure MCP traffic with authentication, load balancing, and rate limiting?
  a: |
    This tutorial demonstrates how to secure MCP traffic using the **Key Authentication** plugin, distribute traffic with the **AI Proxy Advanced** plugin, and control LLM usage through the **AI Rate Limiting Advanced** plugin.

    {:.info}
    > To offload user credential management to a trusted Identity Provider, consider using the [OpenID Connect](/plugins/openid-connect/) plugin.
    >
    > If you need to restrict access to a service or route using allow/deny lists, you can also use the [ACL](/plugins/acl/) plugin by assigning consumers to arbitrary ACL groups.

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


products:
  - gateway
  - ai-gateway

entities:
  - service
  - consumer
  - route

plugins:
  - key-auth
  - ai-proxy-advanced
  - ai-rate-limiting-advanced

tags:
  - authentication
  - key-auth
  - load-balancing
  - rate-limiting

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
  gateway: '3.10'
---

{:.info}
>

## Configure the AI Plugin on the MCP Service

Start by creating a service named `mcp-service` that proxies requests to OpenAI's Chat API using the AI Proxy Plugin:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      service: mcp-service
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
variables:
  openai_key:
    value: OPENAI_API_KEY
{% endentity_examples %}

This configuration sets a **default OpenAI config** for all users accessing the MCP service.

## Enable the Key Authentication plugin

Require API keys for any client accessing `mcp-service`:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: mcp-service
      config:
        key_names:
          - apikey
{% endentity_examples %}

Kong now expects a valid `apikey` header for every incoming request to the service.

## Create a consumer with an OpenAI API Key

Create a consumer named `chat-client` and assign them an API key:

{% entity_examples %}
entities:
  consumers:
    - username: chat-client
      keyauth_credentials:
        - key: secret-chat-key
{% endentity_examples %}

## Customize AI Plugin per Consumer

To override the default model behavior for `chat-client`, attach a plugin directly to the consumer:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      consumer: chat-client
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer
        model:
          provider: openai
          name: gpt-4o
          options:
            max_tokens: 1024
            temperature: 0.7
{% endentity_examples %}

## Test the Key Authentication setup

Now we can test the set up for requiring API keys:

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

## Configure AI load balancing

After handling authentication and authorization, Kong can perform **credential mediation** by injecting the necessary upstream credentials into the request on behalf of the client. This approach abstracts credential management from end-users and applications, reducing the surface area for credential exposure and ensuring tighter control over access to backend services such as LLM APIs.

The `ai-proxy-advanced` plugin facilitates credential mediation by allowing you to configure outbound request headers—such as `Authorization`—using secrets securely referenced from a vault. In the example below, Kong fetches an OpenAI API token from a configured vault path (`vault://ai/openai-token`) and injects it into requests targeting the `gpt-4o` model.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      service: mcp-service
      config:
        balancer:
          algorithm: "round-robin"
          tokens_count_strategy: "total-tokens"
          latency_strategy: "tpot"
          retries: 3
        targets:
        - route_type: "llm/v1/chat"
          auth:
            header_name: "Authorization"
            header_value: "{vault://ai/openai-token}"
          logging:
            log_statistics: true
            log_payloads: true
          model:
            provider: "openai"
            name: "gpt-4o"
            options:
              max_tokens: 1024
              temperature: 1.0
              input_cost: 2.5
              output_cost: 10
variables:
  openai_key:
    value: OPENAI_API_KEY
{% endentity_examples %}

This plugin balances traffic across OpenAI targets and applies retry logic while logging payloads and stats for monitoring.

## Configure AI rate limiting

You can also use the `ai-rate-limiting-advanced` plugin to protect your MCP service and manage API usage costs:

{% entity_examples %}
entities:
  plugins:
    - name: ai-rate-limiting-advanced
      service: mcp-service
      config:
        strategy: local
        window_type: fixed
        llm_providers:
          - name: openai
            window_size:
              - 60
              - 3600
            limit:
              - 10000
              - 1000000
{% endentity_examples %}

This configuration allows up to **10,000 tokens per minute** and **1,000,000 tokens per hour** per consumer.


