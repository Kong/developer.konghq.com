---
title: Set up AI Proxy with Databricks
permalink: /how-to/set-up-ai-proxy-with-databricks/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy/

description: Configure the AI Proxy plugin to create a chat route using Databricks.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.14'

plugins:
  - ai-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - databricks

tldr:
  q: How do I use the AI Proxy plugin with Databricks?
  a: Create a Gateway Service and a Route, then enable the AI Proxy plugin and configure it with the Databricks provider, and the GPT OSS 20B model.

tools:
  - deck

prereqs:
  inline:
    - title: Databricks
      include_content: prereqs/databricks
      icon_url: /assets/icons/databricks.svg
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

## Configure the plugin

Set up the AI Proxy plugin to route chat requests to Databricks’s GPT OSS 20B model by configuring the model options, including the Databricks workspace ID.


{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${key}
        model:
          provider: databricks
          name: databricks-gpt-oss-20b
          options:
            databricks:
              workspace_instance_id: ${workspace}

variables:
  url:
    value: "$DATABRICKS_INSTANCE_URL"
  key:
    value: "$DATABRICKS_TOKEN"
  workspace:
    value: "$DATABRICKS_WORKSPACE_INSTANCE_ID"
{% endentity_examples %}


## Validate

{% include how-tos/steps/ai-proxy-validate.md %}
