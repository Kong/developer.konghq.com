---
title: "Migrate to {{site.ai_gateway}} 2.x"
content_type: reference
layout: reference

works_on:
 - konnect

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai

  
min_version:
  ai-gateway: '2.0'

description: This guide walks you through moving your configuration from the API {{site.base_gateway}} plugin model to the new {{site.ai_gateway}} Policies model.
---

{{site.ai_gateway}} version 2.x introduces a dedicated Control Plane for AI workloads in {{site.konnect_short_name}}. Instead of requiring users to manually build AI behavior on top of API {{site.base_gateway}} through proxy plugins, {{site.ai_gateway}} exposes first-class AI entities: Providers, Models, MCP Servers, and Agents. 

This guide walks you through migrating an existing configuration using the `kongctl` {{site.ai_gateway}} conversion extension.

This guide is intended for teams running {{site.ai_gateway}} version 1.x on {{site.base_gateway}} 3.x who want to move to the {{site.ai_gateway}} version 2.x Control Plane. If you are starting fresh, see Appendix B: Set up a fresh install with the {{site.konnect_short_name}} MCP Server.

## Prerequisites 

Before migrating, make sure you have:

- Read the [{{site.ai_gateway}} 2.x concepts](/ai-gateway/ai-gateway-v2-concepts/) guide.
- An existing Kong API Gateway Control Plane in Konnect running {{site.ai_gateway}} version 1.x, with the AI plugins you want to migrate.
- A new {{site.ai_gateway}} version 2.x Control Plane created in {{site.konnect_short_name}}. Note its Control Plane name.
- A Konnect Personal Access Token (PAT) or System Account Access Token with permission to read the source Control Plane and write to the {{site.ai_gateway}} Control Plane.
- The `deck` CLI for exporting your current configuration.
- The `kongctl` CLI for applying the converted configuration to the {{site.ai_gateway}} Control Plane.
- The `kong/kongctl-ext-aigw-converter` extension added for translating the exported config to the version 2.x entity model.

## Migration overview

The supported migration path uses the kongctl convert ai-gateway extension to translate your existing declarative configuration into the v2 entity model, then applies it with kongctl. The flow has five steps:

Export the declarative configuration from your existing API Gateway control plane with decK.
Run the converter to produce an AI Gateway entity configuration file.
Validate that the output includes all of your models, MCP servers, and agents.
Add your AI Gateway control plane ID to the kongctl configuration.
Apply the converted configuration to the new AI Gateway control plane.

The diagram below shows where each tool sits in the flow.

{% mermaid %}
flowchart LR A[API Gateway CP<br>AI Gateway v1] -->|deck gateway dump| B[kong.yaml] B -->|ai-deck-converter| C[ai-gateway.yaml] C -->|review and validate| C C -->|kongctl apply| D[AI Gateway CP<br>AI Gateway v2] 
{% endmermaid %}
