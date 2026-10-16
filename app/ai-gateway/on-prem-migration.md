---
title: "Migrate to {{site.ai_gateway}} 2.x on-prem"

description: "Migrate an on-prem {{site.base_gateway}} 3.x deployment running AI plugins to the {{site.ai_gateway}} 2.x entity and policy model, using the deck file kong2ai command."

content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - on-prem

tools:
  - deck

# TODO: add min_version once the AI Gateway 2.x release(s) and minimum Kong
# Gateway version deck file kong2ai supports are confirmed.

tags:
  - ai
  - migration

breadcrumbs:
  - /ai-gateway/

related_resources:
  - text: "Migrate to {{site.ai_gateway}} 2.x in {{site.konnect_short_name}}"
    url: /ai-gateway/v2-migration-guide/
  - text: "Configure {{site.ai_gateway_name}} on-prem"
    url: /ai-gateway/configure-on-prem/
  - text: "{{site.ai_gateway}} 2.x concepts"
    url: /ai-gateway/ai-gateway-v2-concepts/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: deck file kong2ai
    url: /deck/file/kong2ai/
  - text: deck file ai2kong
    url: /deck/file/ai2kong/
---

This guide explains how to migrate from a self-managed, on-prem deployment of {{site.ai_gateway}} on {{site.base_gateway}} 3.15 or later to an on-prem deployment of {{site.ai_gateway}} 2.x using decK.
This allows you to run the {{site.ai_gateway}} 2.x model of AI entities and Policies (instead of plugins) in an on-prem deployment.
This guide is intended for teams running {{site.ai_gateway}} on {{site.base_gateway}} 3.x on-prem who want to move to the on-prem {{site.ai_gateway_name}} 2.x [entity and policy model](/ai-gateway/ai-gateway-v2-concepts/), not just upgrade the runtime version.

If you want to migrate to {{site.konnect_short_name}}, see [Migrate to {{site.ai_gateway}} 2.x in {{site.konnect_short_name}}](/ai-gateway/v2-migration-guide/), which covers this migration using `kongctl`.

## Prerequisites

Before migrating, make sure you have:

- An existing, self-managed {{site.base_gateway}} 3.x deployment (`<!-- TODO: confirm minimum version deck file kong2ai supports -->`) running the AI plugins you want to migrate, such as [AI Proxy Advanced](/plugins/ai-proxy-advanced/), [AI MCP Proxy](/plugins/ai-mcp-proxy/), and [AI A2A Proxy](/plugins/ai-a2a-proxy/).
- The [`deck` CLI](/deck/#install-deck) version 1.69
- Admin API access (address and token) for the source {{site.base_gateway}} deployment.
- Read the [AI Gateway 2.x concepts](/ai-gateway/ai-gateway-v2-concepts/) guide
- A target on-prem {{site.ai_gateway_name}} 2.x deployment to migrate into. See [Build the {{site.ai_gateway}} 2.x deployment](#build-the-ai-gateway-2x-deployment) if you haven't created one yet.

## Migration overview

Migration uses `deck file kong2ai` to convert your existing declarative configuration into the {{site.ai_gateway}} 2.x entity model, then `deck ai sync` to apply it.

1. Export the declarative configuration from your existing {{site.base_gateway}} 3.x deployment with decK.
2. Convert it to the {{site.ai_gateway}} 2.x entity model with `deck file kong2ai`.
3. Review the converted file and resolve any conversion warnings.
4. Build (or reuse) an on-prem {{site.ai_gateway_name}} 2.x deployment.
5. Apply the converted configuration with `deck ai sync`.
6. Verify the migrated configuration before moving traffic over.

### Step 1: Export your current configuration

Use `deck` to dump the declarative configuration from the {{site.base_gateway}} 3.x deployment that currently runs your AI plugins. Replace the placeholders with your Admin API address and token.

```sh
deck gateway dump -o kong.yaml
```

The resulting `kong.yaml` contains your Services, Routes, plugins (including `ai-proxy-advanced`, `ai-mcp-proxy`, and `ai-a2a-proxy`), Consumers, and Vaults.

### Step 2: Convert to the {{site.ai_gateway}} 2.x entity model

Run `deck file kong2ai` against the exported file:

```sh
deck file kong2ai --state kong.yaml --output-file ai.yaml
```

The conversion is best-effort: AI plugins are recognized anywhere in `kong.yaml`, and any entity or plugin `kong2ai` can't represent in the {{site.ai_gateway}} 2.x entity model is reported as a warning rather than silently dropped.

By default, the output is YAML. Pass `--format json` to produce JSON instead.

### Step 3: Review warnings and the converted file

Address every warning `kong2ai` prints before moving on. Each one names a plugin or entity it couldn't convert automatically.

### Step 4: Build the {{site.ai_gateway_name}} 2.x deployment

{{site.ai_gateway_name}} 2.x runs as its own control plane and data planes, separate from classic {{site.base_gateway}}, using the `kong/kong-ai-gateway` image.

`<!-- TODO: restore or rewrite the on-prem AI Gateway 2.x install procedure (kong/kong-ai-gateway image, license loading, control plane and data plane configuration) here. -->`

### Step 5: Apply the configuration

Apply the converted entity file to your {{site.ai_gateway_name}} 2.x deployment:

```sh
deck gateway apply ai.yaml
```

## Verify your migration

After you apply the converted configuration, verify it before moving production traffic:

- Confirm each AI Model responds. Send a chat or embeddings request to the migrated route and compare the response and the `X-Kong-LLM-Model` header against its plugin equivalent.
- Confirm AI MCP tool discovery and invocation. Connect an MCP client and list tools, then invoke one.
- Confirm AI Agent traffic, if applicable. Send an A2A request and check that the agent card URL is rewritten to the gateway address.
- Confirm AI Policies and Auth Strategies took effect. Exercise rate limiting, authentication, and any other AI policies to confirm they behave as they did before.
- Compare entity counts. The number of AI Models, MCP Servers, and Agents should match the number of corresponding plugins in your {{site.base_gateway}} 3.x export.

Run the old and new deployments in parallel during cutover so you can roll back by routing traffic to the original deployment if needed.
