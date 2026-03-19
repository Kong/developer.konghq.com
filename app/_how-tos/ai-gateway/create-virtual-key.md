---
title: Create an {{site.ai_gateway}} virtual key in {{site.konnect_short_name}}
permalink: /how-to/create-a-virtual-key-in-konnect/
description: Learn how to create a virtual key to secure your {{site.ai_gateway}} in {{site.konnect_short_name}}.

content_type: how_to

related_resources:
  - text: TODO
    url: /
    

products:
    - gateway
    - ai-gateway

works_on:
    - konnect

tags:
    - security
    - ai

tldr:
    q: TODO
    a: |
        TODO

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
  # - konnect-api
  - deck

cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.14'
---

## Create a virtual key

1. In the {{site.konnect_short_name}} sidebar, click [**AI Gateway**](https://cloud.konghq.com/ai-manager/).
1. Open your AI Gateway.
1. In the sidebar, click **Virtual keys**.
1. Click **New virtual key**.
1. In the **Virtual key name** field, enter `example-key`.
1. In the **Request number** field, enter `100`.
1. In the **Time interval** field, enter `60`.
1. Click **Get key credential**.
1. Copy the generated key and export it to your environment:
   ```sh
   export VIRTUAL_KEY='YOUR VIRTUAL KEY'
   ```
1. In {{site.konnect_short_name}}, click **Confirm**.

## Validate

{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'apikey: $VIRTUAL_KEY'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"

{% endvalidation %}