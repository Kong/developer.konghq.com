---
title: Create an {{site.ai_gateway}} virtual key in {{site.konnect_short_name}}
permalink: /how-to/create-a-virtual-key-in-konnect/
description: Learn how to create a virtual key to secure your {{site.ai_gateway}} in {{site.konnect_short_name}}.

content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Rate limiting with {{site.base_gateway}}
    url: /gateway/rate-limiting/
    

products:
    - gateway
    - ai-gateway

works_on:
    - konnect

tags:
    - security
    - ai
    - rate-limiting
    - openai

tldr:
    q: How can I secure and rate limit my {{site.ai_gateway}} with virtual keys?
    a: |
        Create an {{site.ai_gateway}}, then open the {{site.ai_gateway}} in the {{site.konnect_short_name}} UI and click **Virtual keys**. Create a new virtual key and assign rate limits. {{site.ai_gateway}} will generate a key and automatically create the plugins needed to apply the configuration.

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

tools:
  - deck

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.14'
---

## Set up an {{site.ai_gateway}}

To set up an {{site.ai_gateway}}, enable the AI Proxy Advanced plugin on a Route or Gateway Service.

In this example, we'll enable the plugin for the `example-service` we create in the [prerequisites](#required-entities) and use the OpenAI provider with the GPT-4o model:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      service: example-service
      config:
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
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Create a virtual key

Creating a virtual key in the {{site.konnect_short_name}} UI allows you to generate multiple plugins for access control and rate limiting. In this example, we'll set the rate limit for the key to 2 requests per minute for testing purposes.

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.ai_gateway}}**](https://cloud.konghq.com/ai-manager/).
1. Open your {{site.ai_gateway}}.
1. In the sidebar, click **Virtual keys**.
1. Click **New virtual key**.
1. In the **Virtual key name** field, enter `example-key`.
1. In the **Request number** field, enter `2`.
1. In the **Time interval** field, enter `60`.
1. Click **Get key credential**.
1. Copy the generated key and export it to your environment:
   ```sh
   export VIRTUAL_KEY='YOUR VIRTUAL KEY'
   ```
1. In {{site.konnect_short_name}}, click **Confirm**.

If you go to [**API Gateway**](https://cloud.konghq.com/gateway-manager/), click the `quickstart` gateway, and click **Plugins**, you'll see the plugins automatically created by {{site.ai_gateway}}:
* [Key Authentication](/plugins/key-auth/) to add API key authentication.
* [Rate Limiting Advanced](/plugins/rate-limiting-advanced/) to apply rate limits.
* [ACL](/plugins/acl/) to manage access control.
* [Kong Functions (Pre-Plugins)](/plugins/pre-function/) to extract the virtual key from the header.

{{site.ai_gateway}} also generates a [Consumer](/gateway/entities/consumer/) named after the virtual key name.

## Validate

To validate the configuration, send the following requests three times:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $VIRTUAL_KEY'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}

The third request should return a `429` error with the following message:

```json
{"message":"API rate limit exceeded"}
```
{:.no-copy-code}