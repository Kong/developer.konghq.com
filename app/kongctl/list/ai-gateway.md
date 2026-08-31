---
title: kongctl list ai-gateway
description: "Use the list verb with the ai-gateway command to list {{site.konnect_short_name}} {{site.ai_gateway}}s."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/list/

related_resources:
  - text: kongctl list commands
    url: /kongctl/list/
  - text: Manage an AI Gateway with kongctl
    url: /kongctl/manage-ai-gateway/
  - text: kongctl declarative resource reference
    url: /kongctl/supported-resources/#ai-gateway
---

Use the `list` verb with the `ai-gateway` command to list {{site.konnect_short_name}} {{site.ai_gateway}}s.

kongctl provides the following tools for listing resources for {{site.ai_gateway}}s:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list ai-gateway agents](#kongctl-list-ai-gateway-agents)
    description: "Use the `agents` command to list or retrieve Agents for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway config-stores](#kongctl-list-ai-gateway-config-stores)
    description: "Use the `config-stores` command to list or retrieve Config Stores for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway consumer-groups](#kongctl-list-ai-gateway-consumer-groups)
    description: "Use the `consumer-groups` command to list or retrieve Consumer Groups for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway consumers](#kongctl-list-ai-gateway-consumers)
    description: "Use the `consumers` command to list or retrieve Consumers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway credentials](#kongctl-list-ai-gateway-credentials)
    description: "Use the `credentials` command to list or retrieve Credentials for a specific {{site.konnect_short_name}} {{site.ai_gateway}} Consumer."
  - command: |
      [kongctl list ai-gateway data-plane-certificates](#kongctl-list-ai-gateway-data-plane-certificates)
    description: "Use the `data-plane-certificates` command to list or retrieve data plane certificates for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway mcp-servers](#kongctl-list-ai-gateway-mcp-servers)
    description: "Use the `mcp-servers` command to list or retrieve MCP Servers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway model-providers](#kongctl-list-ai-gateway-model-providers)
    description: "Use the `model-providers` command to list or retrieve model providers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway models](#kongctl-list-ai-gateway-models)
    description: "Use the `models` command to list or retrieve models for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway nodes](#kongctl-list-ai-gateway-nodes)
    description: "Use the `nodes` command to list or retrieve data plane Nodes for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway policies](#kongctl-list-ai-gateway-policies)
    description: "Use the `policies` command to list or retrieve Policies for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
  - command: |
      [kongctl list ai-gateway vaults](#kongctl-list-ai-gateway-vaults)
    description: "Use the `vaults` command to list or retrieve Vaults for a specific {{site.konnect_short_name}} {{site.ai_gateway}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/list/ai-gateway/index.md %}

### kongctl list ai-gateway agents

Use the `agents` command to list or retrieve Agents for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/agents.md %}

### kongctl list ai-gateway auth-strategies

Use the `auth-strategies` command to list or retrieve Auth Strategies for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/auth-strategies.md %}

### kongctl list ai-gateway config-stores

Use the `config-stores` command to list or retrieve Config Stores for a {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/config-stores.md %}

### kongctl list ai-gateway consumer-groups

Use the `consumer-groups` command to list or retrieve Consumer Groups for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/consumer-groups.md %}

### kongctl list ai-gateway consumers

Use the `consumers` command to list or retrieve Consumers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/consumers.md %}

### kongctl list ai-gateway credentials

Use the `credentials` command to list or retrieve Credentials for a specific {{site.konnect_short_name}} {{site.ai_gateway}} Consumer.

{% include_cached /kongctl/help/list/ai-gateway/credentials.md %}

### kongctl list ai-gateway data-plane-certificates

Use the `data-plane-certificates` command to list or retrieve data plane certificates for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/data-plane-certificates.md %}

### kongctl list ai-gateway mcp-servers

Use the `mcp-servers` command to list or retrieve MCP Servers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/mcp-servers.md %}

### kongctl list ai-gateway model-providers

Use the `model-providers` command to list or retrieve model providers for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/model-providers.md %}

### kongctl list ai-gateway models

Use the `models` command to list or retrieve models for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/models.md %}

### kongctl list ai-gateway nodes

Use the `nodes` command to list or retrieve data plane Nodes for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/nodes.md %}

### kongctl list ai-gateway policies

Use the `policies` command to list or retrieve Policies for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/policies.md %}

### kongctl list ai-gateway vaults

Use the `vaults` command to list or retrieve Vaults for a specific {{site.konnect_short_name}} {{site.ai_gateway}}.

{% include_cached /kongctl/help/list/ai-gateway/vaults.md %}