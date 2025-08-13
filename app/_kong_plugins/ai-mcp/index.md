---
title: 'AI MCP'
name: 'AI MCP'

content_type: plugin
tier: ai_gateway_enterprise
publisher: kong-inc
description: Convert any API into a working MCP server

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-prompt-compressor.png

categories:
  - ai

tags:
  - ai

related_resources:
  - text: About AI Gateway
    url: /ai-gateway/
  - text: All AI Gateway plugins
    url: /plugins/?category=ai
  - text: Kong MCP traffic gateway
    url: /mcp/
    icon: /assets/icons/mcp.svg

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
---