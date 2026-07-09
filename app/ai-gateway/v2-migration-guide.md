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
- An existing Kong API Gateway Control Plane in {{site.konnect_short_name}} running {{site.ai_gateway}} version 1.x, with the AI plugins you want to migrate.
- A new {{site.ai_gateway}} version 2.x Control Plane created in {{site.konnect_short_name}}. Note its Control Plane name.
- A {{site.konnect_short_name}} Personal Access Token (PAT) or System Account Access Token with permission to read the source Control Plane and write to the {{site.ai_gateway}} Control Plane.
- The `deck` CLI for exporting your current configuration.
- The `kongctl` CLI for applying the converted configuration to the {{site.ai_gateway}} Control Plane.
- The `kong/kongctl-ext-aigw-converter` extension added for translating the exported config to the version 2.x entity model.

## Migration overview

The supported migration path uses the kongctl convert ai-gateway extension to translate your existing declarative configuration into the v2 entity model, then applies it with kongctl. The flow has five steps:

1. Export the declarative configuration from your existing API {{site.base_gateway}} Control Plane with decK.
1. Run the converter to produce an {{site.ai_gateway}} entity configuration file.
1. Validate that the output includes all of your models, MCP servers, and agents.
1. Add your {{site.ai_gateway}} Control Plane ID to the `kongctl` configuration.
1. Apply the converted configuration to the new {{site.ai_gateway}} Control Plane.

The diagram below shows where each tool sits in the flow:

{% mermaid %}
flowchart LR
    A["API Gateway CP<br/>AI Gateway v1"] -->|deck gateway dump| B["kong.yaml"]
    B -->|ai-deck-converter| C["ai-gateway.yaml"]
    C -->|review and validate| C
    C -->|kongctl apply| D["AI Gateway CP<br/>AI Gateway v2"]
{% endmermaid %}

### Step 1: Export your current configuration

Use `deck` to dump the declarative configuration from the API {{site.base_gateway}} Control Plane that currently runs your AI plugins. Replace the placeholders with your {{site.konnect_short_name}} PAT and the name of the source Control Plane.

```sh
deck gateway dump \
  --konnect-token $YOUR_KONNECT_PAT \
  --konnect-control-plane-name $YOUR_KONNECT_API_GATEWAY_CONTROL_PLANE_NAME \
  > kong.yaml

```

The resulting `kong.yaml` contains your Services, Routes, plugins (including ai-proxy-advanced, ai-mcp-proxy, and ai-a2a-proxy), Consumers, and Vaults.

### Step 2: Run the converter

Run `kongctl convert ai-gateway` against the exported `kong.yaml` file. The tool reads the version 1.x plugin configuration and emits an {{site.ai_gateway}} version 2.x entity configuration.

```sh
kongctl convert ai-gateway deck.yaml \
  --from deck \
  --to kongctl \
  --gateway-name support-ai \
  --output-file ai-gateway.yaml
```

The `-o` flag sets the output file. The converter inspects each AI plugin and translates it into the matching version 2.x entity:

- Each `ai-proxy-advanced `plugin becomes an AI Model (and one Provider per distinct upstream provider and credential set).
- Each `ai-mcp-proxy` plugin becomes an AI MCP Server whose type matches the plugin mode.
- Each `ai-a2a-proxy` plugin becomes an AI Agent.
- Supporting plugins on the same Service or Route become Policies attached to the relevant entity.

### Step 3: Validate the converted configuration

Open `ai-gateway.yaml` and confirm that the converter captured everything you expect. At minimum, check that:

- Every version 1.x model has a corresponding AI Model entry, with the right `capabilities`, `formats`, and `targets`.
- Provider credentials were extracted correctly, and each `targets[].provider` reference resolves to a declared AI Provider.
- Every AI MCP Server has the correct `type` for its original plugin mode, and that `conversion-only` and `listener` pairs are linked by matching tags.
- Each AI Agent points at the correct upstream url and carries the logging settings you had configured.
- Supporting plugins were converted to AI Policies and attached to the right entities.

Pay particular attention to anything the converter cannot infer from the version 1.x config, such as a AI Provider `display_name` or a AI Model `display_name`. These are required in version 2.x and may be generated from the source data, so rename them to something meaningful before you apply.

### Step 4: Add your Control Plane ID to kongctl

`kongctl` needs to know which {{site.ai_gateway}} Control Plane to target. Add your Control Plane name to the `kongctl` configuration file so that apply writes to the correct Control Plane.

```sh
# Set the AI Gateway Control Plane that kongctl will apply to.
ai_gateways:
- ref: ai-gateway
  _external:
    selector:
        matchFields:
          name: "ai-gateway"
```

Keep one source of truth so that repeated applies always target the same Control Plane.

### Step 5: Apply the configuration

Sync the converted configuration to the {{site.ai_gateway}} Control Plane.

```sh
kongctl apply -f ai-gateway.yaml
```

`kongctl` creates the AI Providers, Models, MCP Servers, Agents, and Policies defined in the file. Because the configuration is declarative, you can re-run to apply after edits and `kongctl` will reconcile the Control Plane to match the file.

After the apply succeeds, the {{site.ai_gateway}} exposes its configuration and telemetry endpoints. Send a representative request to each migrated AI Model, MCP server, and Agent to confirm behavior matches version 1.x before you transfer traffic over.

## Entity specific advice

- [Migrating models]()
- [Migrating MCP servers]()
- [Migrating agents]()

## Verify your migration

After you apply the converted configuration, verify the new Control Plane before moving production traffic:

- Confirm each AI Model responds. Send a chat or embeddings request to the migrated AI Model route and compare the response and the `X-Kong-LLM-Model` header against its version 1.x equivalent.
- Confirm AI MCP tool discovery and invocation. Connect an MCP client and list tools, then invoke one. If you migrated ACLs, test with both an allowed and a denied Consumer.
- Confirm AI Agent traffic. Send an A2A request and check that the agent card url is rewritten to the gateway address and that A2A metrics appear in {{site.konnect_short_name}} analytics.
- Confirm AI Policies took effect. Exercise rate limiting, authentication, and any AI policies such as `ai-sanitizer` to confirm they behave as they did in version 1.x.
- Compare entity counts. The number of AI Models, MCP Servers, and Agents in the Control Plane should match the number of corresponding plugins in your version 1.x export.

Run the old and new configurations in parallel during cutover so you can roll back by routing traffic to the version 1.x Control Plane if needed.

## Troubleshooting

### Drive kongctl extensions from the converter output

The `ai-gateway.yaml` produced by the converter is a declarative artifact, which makes it a useful input to `kongctl` extensions. `kongctl` ships installable skills for coding agents, including a declarative skill for plan, apply, sync, delete, and adopt flows, and an extension builder for creating local CLI extensions.

Install the skills from the root of the repository where your agent works:

```sh
kongctl install skills
```

By default, this writes skill files to `.kongctl/skills/` and symlinks them for supported agent tooling, for example `.claude/skills/kongctl-declarative` and `.agents/skills/kongctl-extension-builder`. Use `--dry-run` to preview the files and symlinks first, or `--path` to choose a different directory.

With the converter output and these skills in place, you can build extensions that:

- Diff a freshly converted `ai-gateway.yaml` against the live AI Gateway Control Plane and surface drift before an apply.
- Wrap the full deck gateway dump, `ai-deck-converter`, and `kongctl apply` sequence into a single repeatable command for many Control Planes.
- Validate that every `targets[].provider` reference resolves and that required fields such as `display_name` are populated, as a pre-apply gate.

This lets you treat {{site.ai_gateway}} migration as a versioned, reviewable, and automatable pipeline rather than a one-time manual conversion.


### Set up a fresh install with the {{site.konnect_short_name}} MCP Server

If you would rather start clean instead of converting an existing configuration, you can provision Models, MCP Servers, and Agents directly through the Kong {{site.konnect_short_name}} MCP Server. This is well suited to teams that want to drive setup from an AI assistant or IDE copilot.

Connect your MCP client to the regional {{site.konnect_short_name}} MCP Server endpoint, for example `https://us.mcp.konghq.com/` for the US region, and authenticate with a {{site.konnect_short_name}} PAT or System Account Access Token. All actions respect the permissions of the token you use.

The {{site.konnect_short_name}} MCP Server exposes a discover-then-execute pattern with three core tools:

- `search` finds the relevant API operation from a natural-language description, for example "create an AI Gateway model."
- `get_schema` returns the full schema for that operation so the assistant knows which fields are required.
- `execute` calls the operation with the right inputs.

Using this pattern, you can ask your assistant to create an AI Gateway, declare AI Providers, then add AI Models, AI MCP Servers, and AI Agents, with the assistant reasoning over the live schema at each step rather than relying on hardcoded field lists. The same tools power KAi, Kong's in-product AI assistant, so the workflow is consistent whether you work from an IDE, the terminal, or {{site.konnect_short_name}} itself.
