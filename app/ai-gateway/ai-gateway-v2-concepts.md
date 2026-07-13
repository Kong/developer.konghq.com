---
title: "{{site.ai_gateway}} 2.x concepts"
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

description: This page describes the differences between the API {{site.base_gateway}} plugin model and the new {{site.ai_gateway}} Policies model.

related_resources:
  - text: "Migrate to {{site.ai_gateway}} 2.x"
    url: /ai-gateway/v2-migration-guide/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/entities/ai-policy/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
---

{{site.ai_gateway}} version 2.x introduces a dedicated control plane for AI workloads in {{site.konnect_short_name}}. Instead of requiring users to manually build AI behavior on top of API {{site.base_gateway}} through proxy plugins, {{site.ai_gateway}} exposes first-class AI entities: Providers, Models, MCP Servers, and Agents. 

This guide explains what changed, maps each AI entity to it's corresponding proxy plugin configuration, and walks you through migrating an existing configuration using the `kongctl` {{site.ai_gateway}} conversion extension.

This guide is intended for teams running {{site.ai_gateway}} version 1.x on {{site.base_gateway}} 3.x who want to move to the {{site.ai_gateway}} version 2.x control plane. If you are starting fresh, see Appendix B: Set up a fresh install with the {{site.konnect_short_name}} MCP Server.

## What's changing

In {{site.ai_gateway}} version 1.x, AI functionality is delivered by three proxy plugins that extend {{site.base_gateway}}'s core proxying. You build Services and Routes, then attach a plugin to add AI behavior:

- AI Proxy Advanced provides model proxying, transformation, and load balancing across providers and models.
- AI MCP Proxy bridges Kong-managed Services to the Model Context Protocol, converting REST APIs into MCP tools or fronting upstream MCP servers.
- AI A2A Proxy adds observability and gateway control for Agent-to-Agent protocol traffic.

This model works, but it couples every AI concept to {{site.base_gateway}} primitives. A single logical model can require a Service, a Route, an AI Proxy Advanced plugin, and several supporting plugins, with the AI intent spread across all of them.

{{site.ai_gateway}} version 2.x abstracts those plugins into a purpose-built entity model on its own control plane. You no longer need to configure Services, Routes, and plugins manually. Instead, you declare the AI resource you want, and the control plane provisions the underlying primitives for you.

### Entity mapping

The following table describes how the two models relate at a high level: a version 1.x deployment is a collection of {{site.base_gateway}}'s Services and Routes with AI plugins attached, while a version 2.x deployment is a collection of {{site.ai_gateway}} entities managed under a single {{site.ai_gateway}} control plane.

{% table %}
columns:
  - title: Version 1.x (API {{site.base_gateway}} model)
    key: v1
  - title: Version 2.x (Native {{site.ai_gateway}} model)
    key: v2
  - title: Description
    key: description
rows:
  - v1: "[AI Proxy Advanced](/plugins/ai-proxy-advanced/) on a Service or Route"
    v2: "[AI Model](/ai-gateway/entities/ai-model/)"
    description: "One model entry per virtual model, with one or more `targets`."
  - v1: "Set `config.targets[].model.provider` on [AI Proxy Advanced](/plugins/ai-proxy-advanced/) with inline auth"
    v2: "[AI Model Provider](/ai-gateway/entities/ai--model-provider)"
    description: "Provider credentials are now declared once and reused across AI Model entities."
  - v1: "Set `config.targets[].route_type` on [AI Proxy Advanced](/plugins/ai-proxy-advanced/)"
    v2: "Set `capabilities` and `formats.type` on an [AI Model](/ai-gateway/entities/ai-model/)"
    description: "The `route_type` is decomposed into a `capabilities` array and a format `type`."
  - v1: "Set `config.balancer` on [AI Proxy Advanced](/plugins/ai-proxy-advanced/)"
    v2: "Set `config.balancer` on an [AI Model](/ai-gateway/entities/ai-model/)"
    description: "The same load balancing algorithms are available."
  - v1: "Set `config.vectordb` and `config.embeddings` on [AI Proxy Advanced](/plugins/ai-proxy-advanced/)"
    v2: "Set `config.balancer.AIGatewayModelBalancerSemanticConfig.vectordb` and `config.balancer.AIGatewayModelBalancerSemanticConfig.embeddings` on an [AI Model](/ai-gateway/entities/ai-model/)"
    description: "Carried over with the same Redis and pgvector strategies."
  - v1: "[AI MCP Proxy](/plugins/ai-mcp-proxy/) on a Service or Route"
    v2: "[AI MCP Server](/ai-gateway/entities/ai-mcp-server/)"
    description: "Each version 1.x plugin `mode` maps directly to an AI MCP Server `type` value in version 2.x. Additionally, a new `upstream-server` type is available."
  - v1: "Set `config.default_acl` and `config.tools.acl` on [AI MCP Proxy](/plugins/ai-mcp-proxy/)"
    v2: "Set `access` or `tools.access` on an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/). Configure an [AI Consumer](/ai-gateway/entities/ai-consumer/) or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    description: "ACLs become first-class fields."
  - v1: "[AI A2A Proxy](/plugins/ai-a2a-proxy/) on a Service or Route"
    v2: "[AI Agent](/ai-gateway/entities/ai-agent/)"
    description: "First class A2A support with URL rewriting and A2A analytics built in."
  - v1: "[Plugins](/plugins/?category=ai)"
    v2: "[Policies](/ai-gateway/policies/)"
    description: "AI Policies replace plugins, and can be attached to other entities. The 'type' field on a Policy corresponds to the version 1.x plugin."
  - v1: "Consumers and Consumer Groups"
    v2: "[AI Consumer](/ai-gateway/entities/ai-consumer/) and [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)"
    description: "Managed from the control plane."
  - v1: "Vault"
    v2: "[AI Vault](/ai-gateway/entities/ai-vault/) and [AI Data Plane Certificates](/ai-gateway/entities/ai-data-plane-certificate/)"
    description: "Referenceable fields keep the same {vault://...} syntax."
{% endtable %}

Note the following terminology changes:

- AI Policies replace API {{site.base_gateway}} plugins. All AI Policies have some common parameters, in addition each AI Policy has a `type` which corresponds to a version 1.x plugin such as `ai-sanitizer` or `openid-connect` and their `config` is the same as the version 1.x plugin.
- AI Model Providers are now separate reusable entities. This decouples config and credentials of upstream providers from specific models, which allows you to declare an AI Model Provider once and reference it by name from multiple AI Models.
- A version 1.x route is split into two version 2.x concepts: a `capabilities` list and a `formats` entry. 
