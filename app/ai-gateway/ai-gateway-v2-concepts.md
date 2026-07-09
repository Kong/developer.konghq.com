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
---

{{site.ai_gateway}} version 2.x introduces a dedicated Control Plane for AI workloads in {{site.konnect_short_name}}. Instead of requiring users to manually build AI behavior on top of API {{site.base_gateway}} through proxy plugins, {{site.ai_gateway}} exposes first-class AI entities: Providers, Models, MCP Servers, and Agents. 

This guide explains what changed, maps each AI entity to it's corresponding proxy plugin configuration, and walks you through migrating an existing configuration using the `kongctl` {{site.ai_gateway}} conversion extension.

This guide is intended for teams running {{site.ai_gateway}} version 1.x on {{site.base_gateway}} 3.x who want to move to the {{site.ai_gateway}} version 2.x Control Plane. If you are starting fresh, see Appendix B: Set up a fresh install with the {{site.konnect_short_name}} MCP Server.

## What's changing

In {{site.ai_gateway}} version 1.x, AI functionality is delivered by three proxy plugins that extend {{site.base_gateway}}'s core proxying. You build Services and Routes, then attach a plugin to add AI behavior:

- AI Proxy Advanced provides model proxying, transformation, and load balancing across providers and models.
- AI MCP Proxy bridges Kong-managed Services to the Model Context Protocol, converting REST APIs into MCP tools or fronting upstream MCP servers.
- AI A2A Proxy adds observability and gateway control for Agent-to-Agent protocol traffic.

This model works, but it couples every AI concept to {{site.base_gateway}} primitives. A single logical model can require a Service, a Route, an AI Proxy Advanced plugin, and several supporting plugins, with the AI intent spread across all of them.

{{site.ai_gateway}} version 2.x abstracts those plugins into a purpose-built entity model on its own Control Plane. You no longer need to assemble Services, Routes, and plugins by hand. Instead, you declare the AI resource you want, and the Control Plane provisions the underlying primitives for you.

The following section describes how the two models relate at a high level: a version 1.x deployment is a collection of {{site.base_gateway}}'s Services and Routes with AI plugins attached, while a version 2.x deployment is a collection of {{site.ai_gateway}} entities managed under a single {{site.ai_gateway}} Control Plane.

### Entity mapping

| Version 1.x (API {{site.base_gateway}} model)                                                                 | Version 2.x (Native {{site.ai_gateway}} model)                                                                                                                                                                           | Description                                                                                                                                            |
| ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [AI Proxy Advanced](/plugins/ai-proxy-advanced/) on a Service or Route                                        | [AI Model](/ai-gateway/entities/ai-model/)                                                                                                                                                                               | One model entry per virtual model, with one or more `targets`.                                                                                         |
| Set `config.targets[].model.provider` on an [AI Proxy Advanced](/plugins/ai-proxy-advanced/) with inline auth | [AI Provider](/ai-gateway/entities/ai-provider)                                                                                                                                                                          | Provider credentials are now declared once and reused across AI Model entities.                                                                        |
| Set `config.targets[].route_type` on an [AI Proxy Advanced](/plugins/ai-proxy-advanced/)                      | Set `capabilities` and `formats.type` on an [AI Model](/ai-gateway/entities/ai-model/)                                                                                                                                   | The `route_type` is decomposed into a `capabilities` array and a format `type`.                                                                        |
| Set `config.balancer` on an [AI Proxy Advanced](/plugins/ai-proxy-advanced/)                                  | Set `config.balancer` on an [AI Model](/ai-gateway/entities/ai-model/)                                                                                                                                                   | The same load balancing algorithms are available.                                                                                                      |
| Set `config.vectordb` and `config.embeddings` on an [AI Proxy Advanced](/plugins/ai-proxy-advanced/)          | Set `config.balancer.AIGatewayModelBalancerSemanticConfig.vectordb` and `config.balancer.AIGatewayModelBalancerSemanticConfig.embeddings` on an [AI Model](/ai-gateway/entities/ai-model/)                               | Carried over with the same Redis and pgvector strategies.                                                                                              |
| [AI MCP Proxy](/plugins/ai-mcp-proxy/) on a Service or Route                                                  | [AI MCP Server](/ai-gateway/entities/ai-mcp-server/)                                                                                                                                                                     | Each version 1.x plugin `mode` maps directly to an AI MCP Server `type` value in version 2.x. Additionally, a new `upstream-server` type is available. |
| Set `config.default_acl` and `config.tools.acl` on an [AI MCP Proxy](/plugins/ai-mcp-proxy/)                  | Set `access` or `tools.access` on an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/). Configure an [AI Consumer](/ai-gateway/entities/ai-consumer/) or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) | ACLs become first-class fields.                                                                                                                        |
| [AI A2A Proxy](/plugins/ai-a2a-proxy/) on a Service or Route                                                  | [AI Agent](/ai-gateway/entities/ai-agent/)                                                                                                                                                                               | First class A2A support with URL rewriting and A2A analytics built in.                                                                                 |
| [Plugins](/plugins/?category=ai)                                                                              | [Policies](/ai-gateway/policies/)                                                                                                                                                                                        | AI Policies replace plugins, and can be attached to other entities. The 'type' field on a Policy corresponds to the version 1.x plugin.                |
| Consumers and Consumer Groups                                                                                 | [AI Consumer](/ai-gateway/entities/ai-consumer/) and [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)                                                                                                        | Managed from the Control Plane.                                                                                                                                                       |
| Vault                                                                                                         | [AI Vault](/ai-gateway/entities/ai-vault/) and [AI Data Plane Certificates](/ai-gateway/entities/ai-data-plane-certificate/)                                                                                             | Referenceable fields keep the same {vault://...} syntax.                                                                                               |

Note the following terminology changes:

- AI Policies replace API {{site.base_gateway}} plugins. All AI Policies have some common parameters, in addition each aI policy has a `type` which corresponds to a version 1.x plugin such as `ai-sanitizer` or `openid-connect` and their `config` is the same as the version 1.x plugin.
- AI Providers are now seperate reusable entities. This decouples config and credentials of upstream providers from specific models, which allows you to declare an AI Provider once and reference it by name from multiple AI Models.
- A version 1.x route is split into two version 2.x concepts: a `capabilities` list and a `formats` entry. 
