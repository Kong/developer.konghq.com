---
title: 'AI Azure Content Safety'
name: 'AI Azure Content Safety'

content_type: plugin

publisher: kong-inc
description: 'Use Azure AI Content Safety to check and audit AI Proxy plugin messages before proxying them to an upstream LLM'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.7'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-azure-content-safety.png

categories:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
  - moderation
  - azure cognitive services
---

The AI Azure Content Safety plugin allows administrators to enforce 
introspection with the [Azure AI Content Safety](https://azure.microsoft.com/en-us/products/ai-services/ai-content-safety) service 
for all requests handled by the [AI Proxy](/plugins/ai-proxy/) plugin.
The plugin enables configurable thresholds for the different moderation categories 
and you can specify an array set of pre-configured blocklist IDs from your Azure Content Safety instance.

Audit failures can be observed and reported on using the {{Site.base_gateway}} logging plugins.

{% include plugins/ai-plugins-note.md %}

## Format

This plugin works with all of the AI Proxy plugin's `route_type` settings (excluding the `preserve` mode), and is able to
compose an Azure Content Safety text check by compiling all chat history, or just the `'user'` content.
