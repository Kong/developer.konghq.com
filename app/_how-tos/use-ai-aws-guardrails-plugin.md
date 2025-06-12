---
title: Use AI AWS Guardrails plugin
content_type: how_to

related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: Azure AI Content Safety
    url: /plugins/ai-azure-content-safety/
  - text: AI Gateway
    url: /ai-gateway/

description: Learn how to use the AI AWS Guardrails Safety plugin.

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy
  - ai-azure-content-safety

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - ai-gateway
  - azure

tldr:
  q: How can I use AI AWS Guardrails plugin with AI Gateway?
  a: To use the AI AWS Guardrails plugin

tools:
    - deck

prereqs:
  inline:
    - title: AWS
      content: |
        To complete this tutorial, you will need the following credentials

        * AWS_REGION
        * AWS_ACCESS_KEY_ID
        * AWS_SECRET_ACCESS_KEY

        You can get all of these from the AWS IAM Console under **Users > Security credentials**, and the region from the AWS Console where your resources are deployed.

      icon_url: /assets/icons/aws.svg
    - title: Bedrock guardrail
      include_content: prereqs/bedrock



      icon_url: /assets/icons/bedrock.svg

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

automated_tests: false
---