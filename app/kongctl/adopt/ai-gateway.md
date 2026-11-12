---
title: kongctl adopt ai-gateway
description: "Apply the KONGCTL-namespace label to an existing {{site.konnect_short_name}} {{site.ai_gateway}} that is not currently managed by kongctl."
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/adopt/

related_resources:
  - text: kongctl adopt commands
    url: /kongctl/adopt/
  - text: kongctl declarative resource reference
    url: /kongctl/supported-resources/#ai-gateway
  - text: kongctl get ai-gateway
    url: /kongctl/get/ai-gateway/
  - text: kongctl list ai-gateway
    url: /kongctl/list/ai-gateway/
---

Apply the `KONGCTL-namespace` label to an existing {{site.konnect_short_name}} {{site.ai_gateway}} that is not currently managed by kongctl. Child subcommands `adopt` independently owned resources; adopting a gateway does not adopt its children.

## Command usage

{% include_cached /kongctl/help/adopt/ai-gateway/index.md %}

### kongctl adopt ai-gateway agents

Use the `agents` command to adopt existing agents for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/agents.md %}

### kongctl adopt ai-gateway auth-strategies

Use the `auth-strategies` command to adopt existing auth strategies for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/auth-strategies.md %}

### kongctl adopt ai-gateway ca-certificates

Use the `ca-certificates` command to adopt existing CA certificates for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/ca-certificates.md %}

### kongctl adopt ai-gateway consumer-groups

Use the `consumer-groups` command to adopt existing consumer groups for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/consumer-groups.md %}

### kongctl adopt ai-gateway consumers

Use the `consumers` command to adopt existing consumers for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/consumers.md %}

### kongctl adopt ai-gateway custom-policies

Use the `custom-policies` command to adopt existing custom policies for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/custom-policies.md %}

### kongctl adopt ai-gateway mcp-servers

Use the `mcp-servers` command to adopt existing MCP servers for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/mcp-servers.md %}

### kongctl adopt ai-gateway model-providers

Use the `model-providers` command to adopt existing model providers for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/model-providers.md %}

### kongctl adopt ai-gateway models

Use the `models` command to adopt existing models for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/models.md %}

### kongctl adopt ai-gateway policies

Use the `policies` command to adopt existing policies for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/policies.md %}

### kongctl adopt ai-gateway snis

Use the `snis` command to adopt existing SNIs for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/snis.md %}

### kongctl adopt ai-gateway vaults

Use the `vaults` command to adopt existing vaults for a specific {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management.

{% include_cached /kongctl/help/adopt/ai-gateway/vaults.md %}
