---
title: Autogenerate serverless MCP APIs from any RESTful API
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI MCP
    url: /plugins/ai-mcp/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Learn how to use the AI MCP plugin to generate serverless MCP APIs from any RESTful API, including setting up a mock Node.js server for testing.
products:
  - gateway
  - ai-gateway
permalink: /mcp/autogenerate-serverless-mcp/
works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.12'

plugins:
  - ai-mcp

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - mcp
  - serverless

tldr:
  q: How do I automatically generate an MCP API from an existing REST API?
  a: |
    Use the AI MCP plugin to map your REST API endpoints into MCP capabilities, allowing you to integrate them directly with AI Gateway.
tools:
  - deck

prereqs:
  inline:
    - title: Cursor
      content: |
        Install Cursor:
        1. Go to Cursor [downloads](https://cursor.com/downloads) page.
        2. Download the installation file and install it on your machine.
        3. Run Cursor.
      icon_url: /assets/icons/cursor.svg
    - title: Mock Node.js server
      content: |
        This tutorial uses a mock API server with user data. Follow these steps to expose it:
        1. Install dependencies and run the server
           ```bash
           curl -s -o api.js "https://gist.githubusercontent.com/subnetmarco/5ddb23876f9ce7165df17f9216f75cce/raw/a44a947d69e6f597465050cc595b6abf4db2fbea/api.js"
           npm install express
           node api.js
           ```
        2. Test the API
           ```bash
           curl http://localhost:3000
           ```
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
