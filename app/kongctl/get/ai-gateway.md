---
title: kongctl get ai-gateway
description: "Use the get verb with the ai-gateway command to query {{site.konnect_short_name}} {{site.ai_gateway}}s."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl get commands
    url: /kongctl/get/
---

Use the `get` verb with the `ai-gateway` command to query {{site.konnect_short_name}} {{site.ai_gateway}}s.

kongctl provides the following tools for retrieving resources and resource details for {{site.ai_gateway}}s:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl get ai-gateway agents](#kongctl-get-ai-gateway-agents)
    description: "Use the `agents` command to list or retrieve Agents for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway config-stores](#kongctl-get-ai-gateway-config-stores)
    description: "Use the `config-stores` command to list or retrieve Config Stores for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway consumer-groups](#kongctl-get-ai-gateway-consumer-groups)
    description: "Use the `consumer-groups` command to list or retrieve Consumer Groups for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway consumers](#kongctl-get-ai-gateway-consumers)
    description: "Use the `consumers` command to list or retrieve Consumers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway credentials](#kongctl-get-ai-gateway-credentials)
    description: "Use the `credentials` command to list or retrieve Credentials for a specific {{site.konnect_short_name}} {{site.ai_gateway}} Consumer."
  - command: |
      [kongctl get ai-gateway data-plane-certificates](#kongctl-get-ai-gateway-data-plane-certificates)
    description: "Use the `data-plane-certificates` command to list or retrieve data plane certificates for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway identity-providers](#kongctl-get-ai-gateway-identity-providers)
    description: "Use the `identity-providers` command to list or retrieve identity providers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway mcp-servers](#kongctl-get-ai-gateway-mcp-servers)
    description: "Use the `mcp-servers` command to list or retrieve MCP Servers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway model-providers](#kongctl-get-ai-gateway-model-providers)
    description: "Use the `model-providers` command to list or retrieve model providers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway models](#kongctl-get-ai-gateway-models)
    description: "Use the `models` command to list or retrieve models for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway nodes](#kongctl-get-ai-gateway-nodes)
    description: "Use the `nodes` command to list or retrieve data plane Nodes for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway policies](#kongctl-get-ai-gateway-policies)
    description: "Use the `policies` command to list or retrieve Policies for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl get ai-gateway vaults](#kongctl-get-ai-gateway-vaults)
    description: "Use the `vaults` command to list or retrieve Vaults for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/get/ai-gateway/index.md %}

### kongctl get ai-gateway agents

Use the `agents` command to list or retrieve Agents for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/agents.md %}

### kongctl get ai-gateway config-stores

Use the `config-stores` command to list or retrieve Config Stores for a {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/config-stores.md %}

### kongctl get ai-gateway consumer-groups

Use the `consumer-groups` command to list or retrieve Consumer Groups for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/consumer-groups.md %}

### kongctl get ai-gateway consumers

Use the `consumers` command to list or retrieve Consumers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/consumers.md %}

### kongctl get ai-gateway credentials

Use the `credentials` command to list or retrieve Credentials for a specific {{site.konnect_short_name}} {{site.ai_gateway}} Consumer.

{% include_cached /kongctl/help/get/ai-gateway/credentials.md %}

### kongctl get ai-gateway data-plane-certificates

Use the `data-plane-certificates` command to list or retrieve data plane certificates for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/data-plane-certificates.md %}

### kongctl get ai-gateway identity-providers

Use the `identity-providers` command to list or retrieve identity providers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/identity-providers.md %}

### kongctl get ai-gateway mcp-servers

Use the `mcp-servers` command to list or retrieve MCP Servers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/mcp-servers.md %}

### kongctl get ai-gateway model-providers

Use the `model-providers` command to list or retrieve model providers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/model-providers.md %}

### kongctl get ai-gateway models

Use the `models` command to list or retrieve models for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/models.md %}

### kongctl get ai-gateway nodes

Use the `nodes` command to list or retrieve data plane Nodes for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/nodes.md %}

### kongctl get ai-gateway policies

Use the `policies` command to list or retrieve Policies for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/policies.md %}

### kongctl get ai-gateway vaults

Use the `vaults` command to list or retrieve Vaults for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/get/ai-gateway/vaults.md %}
