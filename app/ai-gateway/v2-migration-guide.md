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

