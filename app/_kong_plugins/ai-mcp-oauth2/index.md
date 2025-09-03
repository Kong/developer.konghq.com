---
title: 'AI MCP OAuth2'
name: 'AI MCP OAuth2'

content_type: plugin
tier: ai_gateway_enterprise
publisher: kong-inc
description: 'Secure MCP server access with OAuth2 authentication'


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

tags:
  - ai
  - mcp

search_aliases:
  - ai-mcp-oauth2
  - OAuth2
  - MCP


icon: plugin-slug.png # e.g. acme.svg or acme.png

categories:
   - ai
---