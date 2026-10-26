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

min_version:
  ai-gateway: '2.0'

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
With an on-prem {{site.ai_gateway}} 2.x deployment, you apply configuration in the {{site.ai_gateway}} 2.x model of AI entities and Policies, which will run on-prem using supported {{site.base_gateway}} 3.x primitives (like Routes, Services, and plugins).
This guide is intended for teams running {{site.ai_gateway}} on {{site.base_gateway}} 3.x on-prem who want to move to the on-prem {{site.ai_gateway_name}} 2.x [entity and policy model](/ai-gateway/ai-gateway-v2-concepts/), not just upgrade the runtime version.

If you want to migrate to {{site.konnect_short_name}} instead, see [Migrate to {{site.ai_gateway}} 2.x in {{site.konnect_short_name}}](/ai-gateway/v2-migration-guide/), which covers this migration using `kongctl` end-to-end.

## Prerequisites

Before migrating, make sure you have:

- An existing, self-managed {{site.base_gateway}} 3.x deployment running the AI plugins you want to migrate, such as [AI Proxy Advanced](/plugins/ai-proxy-advanced/), [AI MCP Proxy](/plugins/ai-mcp-proxy/), and [AI A2A Proxy](/plugins/ai-a2a-proxy/).
- Admin API access (address and token) for the source {{site.base_gateway}} deployment.
- The [`deck` CLI](/deck/#install-deck), for exporting your current configuration and applying the converted one.
- The [`kongctl` CLI](/kongctl/) 1.6.0 or later, for the conversion extension.
- Read the [{{site.ai_gateway}} 2.x concepts](/ai-gateway/ai-gateway-v2-concepts/) guide.
- A target on-prem {{site.ai_gateway_name}} 2.x deployment to migrate into. Follow the steps in [Install {{site.ai_gateway}} 2.x on-prem using Docker Compose](/ai-gateway/install/docker/) if you haven't set one up yet.

## Migration overview

Migration uses the `kongctl convert ai-gateway` extension to translate your existing declarative configuration directly into decK-shaped {{site.ai_gateway}} 2.x entity configuration, which you then apply with `deck ai sync`.

1. Install the `kongctl-ext-aigw-converter` extension.
1. Export the declarative configuration from your existing {{site.base_gateway}} 3.x deployment with decK.
1. Prepare a `./config` directory with the auth strategies, Vaults, and per-model ACLs the converter can't recover from the decK export.
1. Run the converter to merge `./config` and produce decK-ready {{site.ai_gateway}} entity configuration files.
1. Review the findings the converter reports and fix anything that needs manual attention.
1. Validate that the output includes all of your AI Models, AI MCP Servers, and AI Agents.
1. Apply the configuration to your on-prem {{site.ai_gateway}} deployment with `deck ai sync`.

### Step 1: Install the kongctl-ext-aigw-converter extension

The `kongctl-ext-aigw-converter` extension is used to translate your existing declarative configuration into the {{site.ai_gateway}} 2.x entity model.

Install it with `kongctl install extension Kong/kongctl-ext-aigw-converter` and type `yes` when prompted by the terminal.
You need v0.6.0 or later. 

### Step 2: Export your current configuration

Use `deck` to dump the declarative configuration from the {{site.base_gateway}} 3.x deployment that runs your AI plugins.

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

The converter can't recover auth strategies, Vaults, or per-model ACLs from the decK export. Declare these in a `./config` directory before you run it, and it merges them into the output. 

Create the directory:

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
- name: key-auth-prod
  display_name: Key Auth
  type: key-auth
  config:
    key_names:
    - x-api-key
  # Optional entity selectors
  models: ['*']
  mcp_servers: ['*']
  agents: ['*']
- name: oidc-prod
  display_name: OIDC
  type: openid-connect
  config:
    issuer: "https://your-idp.example.com"
    client_id:
    - your-client-id
    client_secret:
    - "{vault://hcv-prod/oidc-client-secret}"
    scopes:
    - openid
    cache_tokens_salt: "a-random-string"
  # Only one auth strategy per entity kind can use the '*' wildcard,
  # so name the specific models, MCP servers, and agents that use OIDC.
  models: ['my-model']
  mcp_servers: ['my-mcp-server']
  agents: ['my-agent']
```
<!--vale on-->

`client_secret` doesn't have to be a `{vault://...}` reference. A literal value also works: the converter detects it automatically, replaces it with a generated environment-variable reference, and writes the real value to the generated `secrets.env` for you to export before applying.

You can declare up to two auth strategies: one `key-auth` and one `openid-connect`. Only one of them may use the `"*"` wildcard per entity kind. An AI Agent or AI MCP Server takes a single auth strategy, so linkage that would attach two to the same agent or MCP server fails the run; AI Models can take more than one.

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

`name` must match the AI Model's converted name, which the converter derives from the v1 **Route** name the `ai-proxy`/`ai-proxy-advanced` plugin is attached to, not from any field inside the plugin itself. If you're not sure what a model will be named, run the converter once without `model_acls.yaml`, check the `name` values in `models.yaml` in `./out`, then add your ACLs and re-run.

#### Vaults

The converter can't recover Vaults from the decK export either. Add a `config/vaults.yaml` with an entry for each Vault backend your migrated AI Models, AI MCP Servers, and AI Agents need for credential storage:

<!--vale off-->
```yaml
# config/vaults.yaml
vaults:
- name: hcv-prod
  display_name: HashiCorp Vault
  type: hcv
  config:
    host: vault.example.com
    port: 8200
    protocol: https
    mount: secret
    kv: v2
    auth_method: token
    token: your-vault-token
```
<!--vale on-->

Unlike a literal `client_secret` in `auth_strategies.yaml` (see [Auth strategies](#auth-strategies)), a Vault's own credential fields, like `token` here, are carried through to the output as-is. Supply the real value directly, or substitute it yourself before running the converter.

### Step 4: Run the converter

Run `kongctl convert ai-gateway` against the exported `kong.yaml` file and your `./config` directory, with `--format deck` so the output is ready to apply with `deck ai sync` directly. The extension reads the {{site.ai_gateway}} running on {{site.base_gateway}} plugin configuration, merges the manual config, validates the result, and emits decK-shaped entity configuration to `./out`.

```sh
kongctl convert ai-gateway \
  --input kong.yaml \
  --config ./config \
  --out ./out \
  --format deck
```

It inspects each AI plugin and translates it into the matching version 2.x entity or Policy:

- Each `ai-proxy-advanced` plugin becomes an [AI Model](/ai-gateway/entities/ai-model/) (and one [AI Model Provider](/ai-gateway/entities/ai-model-provider/) per distinct upstream provider and credential set).
- Each `ai-mcp-proxy` plugin becomes an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) whose type matches the plugin mode.
- Each `ai-a2a-proxy` plugin becomes an [AI Agent](/ai-gateway/entities/ai-agent/).
- Non-auth supporting plugins on the same Service or Route become [AI Policies](/ai-gateway/entities/ai-policy/) attached to the relevant entity.
- Authentication plugins (`key-auth`, `openid-connect`) on **any** AI route are stripped; identity comes from the auth strategies you declared in `./config`, attached to each entity's `access.auth_strategies`.

### Step 5: Review findings and fix any issues

`kongctl convert ai-gateway` prints findings to stderr as it runs, prefixed by severity (`error`, `warn`), and writes the same findings to `./out/migration-report.md` and `./out/migration-report.json`. An `error` finding means the migration isn't safe to apply as-is.
A `warn` finding is something the converter corrected automatically that's still worth confirming, like a dropped balancer field or a forced `ssl_verify`. 
Read through both files and resolve anything that needs a manual fix before moving on.

{:.warning}
> Write-only values (like a plain-text `client_secret`) are converted to `{vault://env/...}` references resolved by Kong's env vault. The migration report's **Secrets to supply** section names the environment variable each reference needs (see also `secrets.env`). Export these in the data plane's environment before applying. This is a different mechanism from decK's own `{% raw %}{{ env "..." }}{% endraw %}` templating, which does **not** resolve when a file is applied with `deck ai sync` — don't use that syntax here.

### Step 6: Validate the converted configuration

Open the `yaml` files in `./out` and confirm they capture everything you expect. At minimum, check that:

- Every AI Proxy plugin-based model has a corresponding AI Model entry, with the right `capabilities`, `formats`, and `targets`.
- Existing `input_cost` and `output_cost` parameters are inherited from the `ai-proxy-advanced` plugin. Optionally, you can set additional [cost management parameters](/ai-gateway/model-cost-management/#model-cost-configuration) per target on the converted AI Model file.
- Provider credentials were extracted correctly, and each `targets[].provider` reference resolves to a declared AI Model Provider.
- Every AI MCP Server has the correct `type` for its original plugin mode, and that each `listener` names its tool sets in `sources`.
- Each AI Agent points at the correct upstream URL and carries the logging settings you had configured.
- The auth strategies you declared in `./config` were merged in and attached to the right AI Models, AI MCP Servers, and AI Agents via `access.auth_strategies`.
- Non-auth supporting plugins were converted to AI Policies and attached to the right entities.
- Any write-only credential field was replaced with a `{vault://env/...}` reference or an environment variable, not left as a literal placeholder.

Pay particular attention to anything the converter can't infer from the config of {{site.ai_gateway}} running on {{site.base_gateway}}, such as an AI Model Provider `display_name` or an AI Model `display_name`. These are required in {{site.ai_gateway}} 2.x and may be generated from the source data, so rename them to something meaningful before you apply.

For a detailed, per-entity breakdown of what the conversion produces (with example input and output files for AI Models, AI MCP Servers, AI Agents, and AI Policies), see [Validate the converted configuration](/ai-gateway/v2-migration-guide/#step-5-validate-the-converted-configuration) in the {{site.konnect_short_name}} migration guide. The entity shapes are the same, since `--format deck` follows the same {{site.ai_gateway}} 2.x schema as the default output.

### Step 7: Apply the configuration

Apply the configuration to your on-prem {{site.ai_gateway_name}} 2.x deployment:

```sh
deck ai sync ./out/ai-gateway.yaml
```

{:.danger}
> `deck ai sync` replaces any configuration in {{site.ai_gateway}} that isn't present in the file you apply. 

After the apply succeeds, send a representative request to each migrated AI Model, AI MCP Server, and AI Agent to confirm behavior matches {{site.ai_gateway}} running on {{site.base_gateway}} before you transfer traffic over.

After you've successfully migrated and tested the configuration, you can uninstall the `kongctl-ext-aigw-converter` extension with `kongctl uninstall extension kong/ai-gateway-converter`.

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

1. Fix the underlying issue. This might mean editing a file in `./config`, editing `kong.yaml`, or fixing configuration on the source {{site.base_gateway}} deployment (for example, setting a missing model name) and re-exporting with `deck gateway dump`.
1. Delete `./out` and regenerate it from scratch with `kongctl convert ai-gateway`, rather than editing the partially generated files directly.
1. Re-run `deck ai sync`.

## Configuring on-prem {{site.ai_gateway}} 2.x post-migration

After migrating, you'll need to apply any new {{site.ai_gateway}} configuration in a decK format using the {{site.ai_gateway}} 2.x model with [`deck ai sync`](/deck/ai/sync/). 
You can adapt any {{site.ai_gateway}} 2.x documentation, including the entities and how-to guides on this site, that is written in `kongctl` format for {{site.konnect_short_name}} by doing the following:

* Drop each entity's `ref` field. decK entities don't use `ref` for cross-references the way `kongctl` does.
* Drop each entity's `ai_gateway: !lookup {id: ...}` field. On-prem, there's only one {{site.ai_gateway}}, so entities don't need to reference one by ID.
* Rename the top-level entity collections from their `kongctl` names to their decK names, for example `ai_gateway_models` becomes `models`, and `ai_gateway_model_providers` becomes `model_providers`.

{:.info}
> Secret handling also differs on-prem. The {{site.konnect_short_name}} flow wraps write-only credential fields in a deferred `!secret {source: !env ...}` value for `kongctl`. On-prem, reference a secret with [AI Vault](/ai-gateway/entities/ai-vault/) `{vault://vault-name/secret-key}` syntax instead, or substitute the real value with your shell before piping the file into `deck ai sync`. decK's own `${% raw %}{{ env "..." }}{% endraw %}` templating does **not** resolve through `deck ai sync`, so a literal, unresolved template string would otherwise end up in the generated plugin config.
