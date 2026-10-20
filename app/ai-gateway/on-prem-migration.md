---
title: "Migrate to {{site.ai_gateway}} 2.x on-prem"

description: "Migrate an on-prem {{site.base_gateway}} 3.x deployment running AI plugins to the {{site.ai_gateway}} 2.x entity and policy model, using the kongctl convert ai-gateway extension and deck ai sync."

content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - on-prem

tools:
  - deck
  - kongctl

# TODO: confirm the minimum kongctl-ext-aigw-converter extension version and
# on-prem AI Gateway version (install guide uses ai-gateway: '2.2') this flow
# requires, once that's settled.

tags:
  - ai
  - migration

breadcrumbs:
  - /ai-gateway/

related_resources:
  - text: "Migrate to {{site.ai_gateway}} 2.x in {{site.konnect_short_name}}"
    url: /ai-gateway/v2-migration-guide/
  - text: "Install {{site.ai_gateway}} 2.x on-prem using Docker Compose"
    url: /ai-gateway/install/docker/
  - text: "Configure {{site.ai_gateway_name}} on-prem"
    url: /ai-gateway/configure-on-prem/
  - text: "{{site.ai_gateway}} 2.x concepts"
    url: /ai-gateway/ai-gateway-v2-concepts/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: deck ai sync
    url: /deck/ai/sync/
---

This guide explains how to migrate from a self-managed, on-prem deployment of {{site.ai_gateway}} on {{site.base_gateway}} 3.x to an on-prem deployment of {{site.ai_gateway}} 2.x.
This moves you from the {{site.base_gateway}} plugin model to the {{site.ai_gateway}} 2.x model of AI entities and Policies, running on-prem.
This guide is intended for teams running {{site.ai_gateway}} on {{site.base_gateway}} 3.x on-prem who want to move to the on-prem {{site.ai_gateway_name}} 2.x [entity and policy model](/ai-gateway/ai-gateway-v2-concepts/), not just upgrade the runtime version.

If you want to migrate to {{site.konnect_short_name}} instead, see [Migrate to {{site.ai_gateway}} 2.x in {{site.konnect_short_name}}](/ai-gateway/v2-migration-guide/), which covers this migration using `kongctl` end-to-end.

## Prerequisites

Before migrating, make sure you have:

- An existing, self-managed {{site.base_gateway}} 3.x deployment (`<!-- TODO: confirm minimum version this flow supports -->`) running the AI plugins you want to migrate, such as [AI Proxy Advanced](/plugins/ai-proxy-advanced/), [AI MCP Proxy](/plugins/ai-mcp-proxy/), and [AI A2A Proxy](/plugins/ai-a2a-proxy/).
- Admin API access (address and token) for the source {{site.base_gateway}} deployment.
- The [`deck` CLI](/deck/#install-deck), for exporting your current configuration and applying the converted one.
- The [`kongctl` CLI](/kongctl/), for the conversion extension.
- Read the [{{site.ai_gateway}} 2.x concepts](/ai-gateway/ai-gateway-v2-concepts/) guide.
- A target on-prem {{site.ai_gateway_name}} 2.x deployment to migrate into. See [Install {{site.ai_gateway}} 2.x on-prem using Docker Compose](/ai-gateway/install/docker/) if you haven't set one up yet.
- The auth strategies (and Vaults or per-model ACLs, if you use them) you want the migrated AI Models, AI MCP Servers, and AI Agents to use. The converter can't recover these from the decK export, so you declare them manually.

## Migration overview

Migration uses the `kongctl convert ai-gateway` extension to translate your existing declarative configuration into the {{site.ai_gateway}} 2.x entity model, adapts that output into decK format, then applies it with `deck ai sync`.

1. Install the `kongctl convert ai-gateway` extension.
1. Export the declarative configuration from your existing {{site.base_gateway}} 3.x deployment with decK.
1. Prepare a `./config` directory with the auth strategies (and Vaults or per-model ACLs, if needed) the converter can't recover from the decK export.
1. Run the converter to merge `./config` and produce a directory of {{site.ai_gateway}} entity configuration files.
1. Adapt the converter output into decK format.
1. Validate that the output includes all of your AI Models, AI MCP Servers, and AI Agents.
1. Apply the converted configuration to your on-prem {{site.ai_gateway}} deployment with `deck ai sync`.

### Step 1: Install the `kongctl-ext-aigw-converter` extension

The `kongctl-ext-aigw-converter` extension is used to translate your existing declarative configuration into the {{site.ai_gateway}} 2.x entity model.

Install it with `kongctl install extension Kong/kongctl-ext-aigw-converter` and type `yes` when prompted by the terminal.

### Step 2: Export your current configuration

Use `deck` to dump the declarative configuration from the {{site.base_gateway}} 3.x deployment that currently runs your AI plugins. Replace the placeholders with your Admin API address and token.

```sh
deck gateway dump -o kong.yaml
```

The resulting `kong.yaml` contains your Services, Routes, plugins (including `ai-proxy-advanced`, `ai-mcp-proxy`, and `ai-a2a-proxy`), Consumers, and Vaults.

{:.warning}
> **Converter requirements:**
> * Each `ai-proxy` or `ai-proxy-advanced` plugin you're migrating needs a model name (for example `gpt-4o`) configured. The converter can't generate one for you, and a converted AI Model with no model name fails validation when you apply it. If any of your plugins are missing one, set it on the source deployment before you export.
> * Each `ai-proxy` or `ai-proxy-advanced` plugin's target needs authentication (`auth`) configured if the upstream provider requires it. The converter carries this into the {{site.ai_gateway}} Model Provider's `config.auth`. If the target has no `auth` configured, the converted provider is missing `config` entirely and fails validation when you apply it.
> * `ai-proxy-advanced`, `ai-mcp-proxy`, and `ai-a2a-proxy` plugins can be attached to a Service or a Route, but the Service they're attached to **must** have at least one Route attached, or the plugin won't convert to the {{site.ai_gateway}} 2.x entity model.

### Step 3: Prepare the configuration directory

The converter cannot recover some configuration from the decK export:
* Auth strategies
* Per-model ACLs

Declare these in a `./config` directory before you run the converter, and it merges them into the output. Create the directory:

```sh
mkdir -p ./config
```

#### Auth strategies

Authentication works differently in version 2.x. Route auth plugins are **not** carried over onto AI Models, AI MCP Servers, or AI Agents. Instead you declare auth strategies here, and the converter attaches them to the entities you list. AI Models, AI MCP Servers, and AI Agents all support auth strategies the same way, referenced from the entity's `access.auth_strategies`.

Add a `config/auth_strategies.yaml` with an entry for each authentication method (`key-auth` or `openid-connect`). Each entry may optionally list the `models`, `agents`, and `mcp_servers` it attaches to by name, or `"*"` to attach to every entity of that kind:

<!--vale off-->
```yaml
# config/auth_strategies.yaml
auth_strategies:
- ref: key-auth-prod
  name: key-auth-prod
  display_name: Key Auth
  type: key-auth
  config:
    key_names:
    - x-api-key
  # Optional entity selectors
  models: ['*']
  mcp_servers: ['*']
  agents: ['*']
```
<!--vale on-->

At most two auth strategies are allowed (at most one `key-auth` and one `openid-connect`), and at most one may use the `"*"` wildcard per entity kind. An AI Agent or AI MCP Server accepts at most **one** auth strategy, so linkage that would attach two to the same agent or MCP server fails the run; AI Models are uncapped. See [Auth strategies](/ai-gateway/v2-migration-guide/#auth-strategies) in the {{site.konnect_short_name}} migration guide for the full `openid-connect` shape.

#### Per-model ACLs

Optionally, add a `config/model_acls.yaml` to control which AI Consumers or AI Consumer Groups can reach each AI Model. Each entry names a model and sets `allow` or `deny`:

<!--vale off-->
```yaml
# config/model_acls.yaml
acls:
- name: azure-gpt-4o
  allow:
  - Azure-OpenAI-Gold
  - Azure-OpenAI-Silver
```
<!--vale on-->

`name` must match the AI Model's converted name, which the converter derives from the v1 **Route** name the `ai-proxy`/`ai-proxy-advanced` plugin is attached to, not from any field inside the plugin itself. If you're not sure what a model will be named, run the converter once without `model_acls.yaml`, check the `ref`/`name` values in `models.yaml` in `./out`, then add your ACLs and re-run.

### Step 4: Run the converter

Run `kongctl convert ai-gateway` against the exported `kong.yaml` file and your `./config` directory. The tool reads the {{site.ai_gateway}} running on {{site.base_gateway}} plugin configuration, merges the manual config, and emits an {{site.ai_gateway}} 2.x entity and Policy configuration to `./out`.

```sh
kongctl convert ai-gateway \
  --input kong.yaml \
  --config ./config \
  --out ./out
```

It inspects each AI plugin and translates it into the matching version 2.x entity or Policy:

- Each `ai-proxy-advanced` plugin becomes an [AI Model](/ai-gateway/entities/ai-model/) (and one [AI Model Provider](/ai-gateway/entities/ai-model-provider/) per distinct upstream provider and credential set).
- Each `ai-mcp-proxy` plugin becomes an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) whose type matches the plugin mode.
- Each `ai-a2a-proxy` plugin becomes an [AI Agent](/ai-gateway/entities/ai-agent/).
- Non-auth supporting plugins on the same Service or Route become [AI Policies](/ai-gateway/entities/ai-policy/) attached to the relevant entity.
- Authentication plugins (`key-auth`, `openid-connect`) on **any** AI route are stripped; identity comes from the auth strategies you declared in `./config`, attached to each entity's `access.auth_strategies`.

This output is shaped for {{site.konnect_short_name}} (the `ai_gateway_*` entity collections, each referencing a control plane by `ref`/`ai_gateway`). The next step adapts it for an on-prem deployment.

### Step 5: Adapt the output to decK format

An on-prem {{site.ai_gateway}} applies configuration with [`deck ai sync`](/deck/ai/sync/), which expects a decK-shaped entity file, not the `kongctl`-shaped one the converter just produced in `./out`. For each file in `./out`, make the following changes:

* Drop each entity's `ref` field. decK entities don't use `ref` for cross-references the way `kongctl` does.
* Drop each entity's `ai_gateway: !lookup {id: ...}` field. On-prem, there's only one {{site.ai_gateway}}, so entities don't need to reference one by ID.
* Rename the top-level entity collections from their `kongctl` names to their decK names, for example `ai_gateway_models` becomes `models`, and `ai_gateway_model_providers` becomes `model_providers`. See [Configure {{site.ai_gateway}} on-prem](/ai-gateway/configure-on-prem/) for the full set of entity names decK expects.
* Add `protocols: [http, https]` under `config.route` on each AI Model. The {{site.ai_gateway}} entity schema defaults to both protocols, but that default isn't carried through by `deck ai sync`'s conversion, so the generated Route ends up with {{site.base_gateway}}'s own https-only default instead.

{:.info}
> Secret handling also differs on-prem. The {{site.konnect_short_name}} migration flow wraps write-only credential fields in a deferred `!secret {source: !env ...}` value for `kongctl`. On-prem, reference a secret with [AI Vault](/ai-gateway/entities/ai-vault/) `{vault://vault-name/secret-key}` syntax instead, or substitute the real value with your shell before piping the file into `deck ai sync`. decK's own `${% raw %}{{ env "..." }}{% endraw %}` templating does **not** resolve through `deck ai sync`, so a literal, unresolved template string would otherwise end up in the generated plugin config.

### Step 6: Validate the converted configuration

Open the adapted `yaml` files and confirm they capture everything you expect. At minimum, check that:

- Every AI Proxy plugin-based model has a corresponding AI Model entry, with the right `capabilities`, `formats`, and `targets`.
- Existing `input_cost` and `output_cost` parameters are inherited from the `ai-proxy-advanced` plugin. Optionally, you can set additional [cost management parameters](/ai-gateway/model-cost-management/#model-cost-configuration) per target on the converted AI Model file.
- Provider credentials were extracted correctly, and each `targets[].provider` reference resolves to a declared AI Model Provider.
- Every AI MCP Server has the correct `type` for its original plugin mode, and that each `listener` names its tool sets in `sources`.
- Each AI Agent points at the correct upstream URL and carries the logging settings you had configured.
- The auth strategies you declared in `./config` were merged in and attached to the right AI Models, AI MCP Servers, and AI Agents via `access.auth_strategies`.
- Non-auth supporting plugins were converted to AI Policies and attached to the right entities.
- Every AI Model's `config.route` carries `protocols: [http, https]` (see [Step 5](#step-5-adapt-the-output-to-deck-format)).
- Any write-only credential field carried over as a plain string is replaced with a real vault reference or secret value, not left as a literal placeholder.

Pay particular attention to anything the converter can't infer from the config of {{site.ai_gateway}} running on {{site.base_gateway}}, such as an AI Model Provider `display_name` or an AI Model `display_name`. These are required in {{site.ai_gateway}} 2.x and may be generated from the source data, so rename them to something meaningful before you apply.

For a detailed, per-entity breakdown of what the converter produces (with example input and output files for AI Models, AI MCP Servers, AI Agents, and AI Policies), see [Validate the converted configuration](/ai-gateway/v2-migration-guide/#step-5-validate-the-converted-configuration) in the {{site.konnect_short_name}} migration guide — the entity shapes are the same; only the surrounding `ref`/collection-name/`protocols` differences from [Step 5](#step-5-adapt-the-output-to-deck-format) apply on-prem.

### Step 7: Apply the configuration

Apply the adapted configuration to your on-prem {{site.ai_gateway_name}} 2.x deployment:

```sh
deck ai sync ai.yaml
```

{:.danger}
> `deck ai sync` replaces any configuration in {{site.ai_gateway}} that isn't present in the file you apply. 

After the apply succeeds, send a representative request to each migrated AI Model, MCP server, and Agent to confirm behavior matches {{site.ai_gateway}} running on {{site.base_gateway}} before you transfer traffic over.

Once you've successfully migrated and tested the configuration, you can uninstall the `kongctl-ext-aigw-converter` extension with `kongctl uninstall extension kong/ai-gateway-converter`.

## Verify your migration

After you apply the converted configuration, verify the new deployment before moving production traffic:

- Confirm each AI Model responds. Send a chat or embeddings request to the migrated AI Model route and compare the response and the `X-Kong-LLM-Model` header against its plugin equivalent.
- Confirm AI MCP tool discovery and invocation. Connect an MCP client and list tools, then invoke one. If you migrated ACLs, test with both an allowed and a denied Consumer.
- Confirm AI Agent traffic. Send an A2A request and check that the agent card URL is rewritten to the gateway address.
- Confirm AI Policies took effect. Exercise rate limiting, authentication, and any AI policies such as `ai-sanitizer` to confirm they behave as they did before.
- Compare entity counts. The number of AI Models, MCP Servers, and Agents in the new deployment should match the number of corresponding plugins in your {{site.base_gateway}} 3.x export.

Run the old and new deployments in parallel during cutover so you can roll back by routing traffic to the original deployment if needed.

## Troubleshooting

### Recover from a failed sync

If `deck ai sync` fails partway through, fix the underlying issue, then re-run it rather than editing the applied state directly:

1. Fix the underlying issue. This might mean editing a file in `./config`, editing `kong.yaml`, fixing configuration on the source {{site.base_gateway}} deployment (for example, setting a missing model name) and re-exporting with `deck gateway dump`, or correcting a field from the [adaptation step](#step-5-adapt-the-output-to-deck-format).
1. Delete `./out` and regenerate it from scratch with `kongctl convert ai-gateway`, rather than editing the partially generated files directly.
1. Repeat the [adaptation step](#step-5-adapt-the-output-to-deck-format) on the regenerated output.
1. Re-run `deck ai sync`.
