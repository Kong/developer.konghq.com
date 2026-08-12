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

description: This guide walks you through moving your configuration from the {{site.ai_gateway}} running on {{site.base_gateway}} plugin model to the new {{site.ai_gateway}} 2.x Policies model.

related_resources:
  - text: "{{site.ai_gateway}} 2.x concepts"
    url: /ai-gateway/ai-gateway-v2-concepts/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/entities/ai-policy/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
---

{{site.ai_gateway}} 2.x introduces a dedicated control plane for AI workloads in {{site.konnect_short_name}}. Instead of requiring users to manually build AI behavior on top of {{site.base_gateway}} through proxy plugins, {{site.ai_gateway}} exposes first-class AI entities: AI Model Providers, AI Models, AI MCP Servers, and AI Agents.

This guide walks you through migrating an existing configuration using the `kongctl` {{site.ai_gateway}} conversion extension.

This guide is intended for teams running {{site.ai_gateway}} on {{site.base_gateway}} 3.x who want to move to the {{site.ai_gateway}} 2.x control plane. If you are starting fresh, see [Set up a fresh install with the {{site.konnect_short_name}} MCP Server](#set-up-a-fresh-install-with-the-konnect-mcp-server).

## Prerequisites 

Before migrating, make sure you have:

- Read the [{{site.ai_gateway}} 2.x concepts](/ai-gateway/ai-gateway-v2-concepts/) guide.
- An existing Kong API Gateway control plane in {{site.konnect_short_name}} running {{site.ai_gateway}} on {{site.base_gateway}} 3.x with the AI plugins you want to migrate.
- A new {{site.ai_gateway}} 2.x control plane created in {{site.konnect_short_name}}. Note its control plane name.
- A [{{site.konnect_short_name}} Personal Access Token (PAT) or System Account Access Token](/konnect-api/#konnect-api-authentication) with permission to read the source control plane and write to the {{site.ai_gateway}} control plane.
- The [`deck` CLI](/deck/#install-deck) for exporting your current configuration.
- The [`kongctl` CLI](/kongctl/) for applying the converted configuration to the {{site.ai_gateway}} control plane.
- The identity providers, Vaults, and per-model ACLs you want the migrated AI Models, AI MCP Servers, and AI Agents to use. The converter cannot recover these from the decK export, so you declare them manually.

## Migration overview

Migration uses the `kongctl convert ai-gateway extension` to translate your existing declarative configuration into the {{site.ai_gateway}} 2.x entity model, then applies it with `kongctl`.

1. Install the `kongctl convert ai-gateway` extension.
1. Export the declarative configuration from your existing {{site.base_gateway}} control plane with decK.
1. Prepare a `./config` directory with the target control plane, identity providers, Vaults, and per-model ACLs the converter cannot recover from the decK export.
1. Run the converter to merge `./config` and produce a directory of {{site.ai_gateway}} entity configuration files.
1. Validate that the output includes all of your AI Models, AI MCP Servers, and AI Agents.
1. Authenticate `kongctl` with a {{site.konnect_short_name}} PAT or System Account Access Token.
1. Apply the converted configuration to the new {{site.ai_gateway}} control plane.

The diagram below shows where each tool sits in the flow:

{% mermaid %}
sequenceDiagram
    participant A as API Gateway CP<br/>{{site.ai_gateway}} v1
    participant B as kong.yaml
    participant C as ./config (manual config)
    participant D as ./out (entity files)
    participant E as {{site.ai_gateway}} CP<br/>{{site.ai_gateway}} v2

    A->>B: deck gateway dump
    Note over C: add control plane, identity<br/>providers, vaults, and ACLs
    B->>D: kongctl convert ai-gateway
    C-->>D: merged on conversion
    D->>D: review and validate
    D->>E: kongctl apply
{% endmermaid %}

### Step 1: Install the `kongctl-ext-aigw-converter` extension

The `kongctl-ext-aigw-converter` extension is used to translate your existing declarative configuration into the {{site.ai_gateway}} 2.x entity model.

Install it with `kongctl install extension Kong/kongctl-ext-aigw-converter` and type `yes` when prompted by the terminal.

### Step 2: Export your current configuration

Use `deck` to dump the declarative configuration from the {{site.base_gateway}} control plane that currently runs your AI plugins. Replace the placeholders with your {{site.konnect_short_name}} PAT and the name of the source control plane.

```sh
deck gateway dump \
  --konnect-token $KONNECT_TOKEN \
  --konnect-control-plane-name $KONNECT_API_GATEWAY_CONTROL_PLANE_NAME \
  > kong.yaml

```

The resulting `kong.yaml` contains your Services, Routes, plugins (including `ai-proxy-advanced`, `ai-mcp-proxy`, and `ai-a2a-proxy`), Consumers, and Vaults.

{:.warning}
> **Converter requirements:** 
> * Each `ai-proxy` or `ai-proxy-advanced` plugin you're migrating needs a real model name (for example `gpt-4o`) configured. The converter can't generate one for you, and a converted AI Model with no model name fails validation when you apply it. If any of your plugins are missing one, set it on the {{site.base_gateway}} 3.x control plane before you export.
> * `ai-proxy-advanced`, `ai-mcp-proxy`, and `ai-a2a-proxy` plugins **must** be scoped to a Service and Route to convert to the {{site.ai_gateway}} 2.x entity model.

### Step 3: Prepare the configuration directory

The converter cannot recover some configuration from the decK export, such as the target {{site.ai_gateway}} 2.x control plane, identity providers, Vaults, and per-model ACLs. Declare these in a `./config` directory before you run the converter, and it will merge them into the output. 
Create the directory:

```sh
mkdir -p ./config
```

#### Target control plane

Add a `config/gateway.yaml` that points at the {{site.ai_gateway}} 2.x control plane you created in the [prerequisites](#prerequisites). Use an `_external` selector to reference the existing control plane by name so `kongctl` does not create a new one:

<!--vale off-->
```yaml
# config/gateway.yaml
ai_gateways:
- ref: ai-gateway
  _external:
    selector:
      matchFields:
        name: "your-ai-gateway-name"
```
<!--vale on-->

#### Identity providers

Authentication works differently in version 2.x. Route auth plugins are **not** carried over onto AI Models, AI MCP Servers, or AI Agents. Instead you declare identity providers here, and the converter attaches them to the entities you list. AI Models, AI MCP Servers, and AI Agents all support identity providers the same way, referenced from the entity's `access.identity_providers`.

Add a `config/identity_providers.yaml` with an entry for each authentication method (`key-auth` or `openid-connect`). Each entry may optionally list the `models`, `agents`, and `mcp_servers` it attaches to by name, or `"*"` to attach to every entity of that kind:

<!--vale off-->
```yaml
# config/identity_providers.yaml
identity_providers:
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
- ref: oidc-prod
  name: oidc-prod
  display_name: OIDC
  type: openid-connect
  config:
    issuer: "https://your-idp.example.com"
    client_id:
    - your-client-id
    client_secret:
    - your-client-secret
    scopes:
    - openid
    cache_tokens_salt: "a-random-string"
  # Only one identity provider per entity kind can use the '*' wildcard,
  # so name the specific models, MCP servers, and agents that use OIDC.
  models: ['my-model']
  mcp_servers: ['my-mcp-server']
  agents: ['my-agent']
```
<!--vale on-->

The `openid-connect` entry above shows only the fields {{site.ai_gateway}} requires at minimum. Add any other fields your identity provider actually uses (additional scopes, claims, cookie settings, and so on). Don't copy fields straight from your v1 `openid-connect` plugin config if they're unset (`null`) there. {{site.ai_gateway}} 2.x rejects explicit `null` values for most fields, so it's easier to start minimal and add only what you need.

At most two identity providers are allowed (at most one `key-auth` and one `openid-connect`), and at most one may use the `"*"` wildcard per entity kind. The converter attaches each provider to the listed entities via their `access.identity_providers`.

#### Vaults

Add a `config/vaults.yaml` with an entry for any secret store your migrated config references with `{vault://...}` syntax:

<!--vale off-->
```yaml
# config/vaults.yaml
vaults:
- ref: ai-vault
  name: ai-vault
  display_name: AI Gateway Vault
  type: konnect
  description: Credential store for AI Gateway
  config:
    config_store_id: "$KONNECT_CONFIG_STORE_ID"
```
<!--vale on-->

{:.info}
> **Note:** For a [{{site.konnect_short_name}} Config Store vault](/how-to/configure-the-konnect-config-store/) (`type: konnect`), the Config Store you reference must already exist in {{site.konnect_short_name}} before you apply the configuration. `kongctl` does not create it for you. If you created the Config Store through the {{site.konnect_short_name}} UI, it's created without a `name`. Set one with the [Update Config Store API](/api/konnect/control-planes-config/v2/#/operations/update-config-store) before you apply the configuration.

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

The `--out` flag sets the output directory for the converted files, which the converter creates for you. It inspects each AI plugin and translates it into the matching version 2.x entity or Policy:

- Each `ai-proxy-advanced` plugin becomes an [AI Model](/ai-gateway/entities/ai-model/) (and one [AI Model Provider](/ai-gateway/entities/ai-model-provider/) per distinct upstream provider and credential set).
- Each `ai-mcp-proxy` plugin becomes an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) whose type matches the plugin mode.
- Each `ai-a2a-proxy` plugin becomes an [AI Agent](/ai-gateway/entities/ai-agent/).
- Non-auth supporting plugins on the same Service or Route become [AI Policies](/ai-gateway/entities/ai-policy/) attached to the relevant entity.
- Authentication plugins (`key-auth`, `openid-connect`) on **any** AI route (AI Model, AI MCP Server, or AI Agent) are stripped; identity comes from the [identity providers](/ai-gateway/entities/ai-identity-provider/) you declared in `./config`, attached to each entity's `access.identity_providers`.

### Step 5: Validate the converted configuration

Open the `yaml` files in `./out` and confirm that the converter captured everything you expect. At minimum, check that:

- Every AI Proxy plugin-based model has a corresponding AI Model entry in `models.yaml`, with the right `capabilities`, `formats`, and `targets`.
- Provider credentials were extracted correctly, and each `targets[].provider` reference resolves to a declared AI Model Provider in `providers.yaml`.
- Every AI MCP Server in `mcp_servers.yaml` has the correct `type` for its original plugin mode, and that `conversion-only` and `listener` pairs are linked by matching tags.
- Each AI Agent points at the correct upstream URL and carries the logging settings you had configured.
- The identity providers you declared in `./config` were merged into `identity_providers.yaml` and attached to the right AI Models, AI MCP Servers, and AI Agents via `access.identity_providers`, and `vaults.yaml` and `gateway.yaml` reflect what you declared.
- Non-auth supporting plugins were converted to AI Policies and attached to the right entities.

Pay particular attention to anything the converter can't infer from the config of {{site.ai_gateway}} running on {{site.base_gateway}}, such as an AI Model Provider `display_name` or an AI Model `display_name`. These are required in {{site.ai_gateway}} 2.x and may be generated from the source data, so rename them to something meaningful before you apply.

#### Validate AI Models

In {{site.ai_gateway}} running on {{site.base_gateway}}, a model is an [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin attached to a Service and Route. The plugin holds the provider, credentials, route type, model options, and load balancer all in one place. 

In {{site.ai_gateway}} version 2.x, that single plugin becomes two entities: an [AI Model Provider](/ai-gateway/entities/ai-model-provider) that holds the upstream connection and credentials, and an [AI Model](/ai-gateway/entities/ai-model/) that holds routing, capabilities, format, load balancing, and one or more `targets` that each reference an AI Model Provider.
This allows you to reuse AI Model Providers in multiple AI Models.

##### Converted configuration files

The following `deck` snippet defines a chat model that load balances across two OpenAI models using round-robin:

<!--vale off-->
```yaml
# kong.yaml (AI Gateway v1, exported with deck gateway dump)
services:
- name: openai-chat
  url: https://api.openai.com:443
  routes:
  - name: openai-chat-route
    paths:
    - /chat
  plugins:
  - name: ai-proxy-advanced
    config:
      balancer:
        algorithm: round-robin
      targets:
      - route_type: llm/v1/chat
        weight: 70
        auth:
          header_name: Authorization
          header_value: Bearer {vault://openai-vault/api-key}
        model:
          provider: openai
          name: gpt-4o
          options:
            max_tokens: 512
            temperature: 0.7
      - route_type: llm/v1/chat
        weight: 30
        auth:
          header_name: Authorization
          header_value: Bearer {vault://openai-vault/api-key}
        model:
          provider: openai
          name: gpt-4o-mini
          options:
            max_tokens: 512
            temperature: 0.7
```
{:.collapsible}
<!--vale on-->

The converter splits the credentials into an AI Model Provider and the routing and balancing into an AI Model. The route_type of `llm/v1/chat` becomes `capabilities: [generate]` with an `openai` format, and each target references the AI Model Provider by name.

<!--vale off-->
```yaml
# providers.yaml (AI Gateway v2 entity model)
ai_gateway_model_providers:
- ref: openai-prod
  ai_gateway: !ref ai-gateway#id
  type: openai
  name: openai-prod
  display_name: OpenAI Production
  config:
    auth:
      # Carried over from the v1 target auth block.
      type: basic
      headers:
      - name: Authorization
        value: Bearer {vault://openai-vault/api-key}

# models.yaml (AI Gateway v2 entity model)
ai_gateway_models:
- ref: openai-chat
  ai_gateway: !ref ai-gateway#id
  type: model
  name: openai-chat
  display_name: OpenAI Chat
  enabled: true
  capabilities:
  - generate
  formats:
  - type: openai
  access:
    acls:
      allow: []
      deny: []
  policies: []
  config:
    route:
      paths:
      - /chat
    model:
      name_header: true
    balancer:
      algorithm: round-robin
  targets:
  - name: gpt-4o
    provider: openai-prod
    weight: 70
    config:
      type: openai
      max_tokens: 512
      temperature: 0.7
  - name: gpt-4o-mini
    provider: openai-prod
    weight: 30
    config:
      type: openai
      max_tokens: 512
      temperature: 0.7
```
{:.collapsible}
<!--vale on-->

##### Verify AI Models entity configuration

To verify your AI Models entity migration, be sure to check the following:

- Capabilities and format: Confirm the `route_type` was decomposed correctly. For example, `llm/v1/chat` maps to `capabilities: [generate]` and `formats: [{type: openai}]`, while `llm/v1/embeddings` maps to `capabilities: [embeddings]`. Asynchronous file and batch route types map to an AI Model with `type: api` and `capabilities` of `files` or `batches`.
- Provider reuse: If several {{site.ai_gateway}} running on {{site.base_gateway}} targets shared the same provider and credentials, the converter should produce a single AI Model Provider that all targets reference. Deduplicate any near-identical AI Model Providers it couldn't merge.
- Model options: Per-target options such as `max_tokens`, `temperature`, `top_p`, and `top_k` move into each `targets[].config`, keyed by the provider `type`.
- Auth override: If you relied on `config.targets.auth.allow_override` when running {{site.ai_gateway}} on {{site.base_gateway}}, set `allow_auth_override: true` on the corresponding target in version 2.x.
- Identity: AI Models have no route auth after conversion. Confirm the identity providers you added previously are attached via `access.identity_providers`.
- Vector database and embeddings: `config.vectordb` and `config.embeddings` settings carry over onto the AI Model config under the `balancer` config, keeping the same Redis or pgvector strategy.


#### Validate MCP Servers

In {{site.ai_gateway}} running on {{site.base_gateway}}, an MCP server is an [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin attached to a Service and Route. The plugin runs in one of four modes and holds the tools, Access Control Lists (ACLs), and logging settings in its config.

In {{site.ai_gateway}} version 2.x, that plugin becomes a single [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity, with the following changes:
* The plugin `mode` setting becomes an MCP Server `type` setting. This part of the migration essentially consists in copying the value you set in `config.mode` to the `type` setting.
* ACLs, which were plugin fields in {{site.ai_gateway}} running on {{site.base_gateway}}, become a top-level fields on the AI MCP Server.

The following table maps each {{site.base_gateway}} plugin mode to its version 2.x MCP Server type:

{% table %}
columns:
  - title: "V1 MCP proxy `config.mode`"
    key: mode
  - title: "V2 AI MCP Server `type`"
    key: type
rows:
  - mode: "`passthrough-listener`"
    type: "`passthrough-listener`"
  - mode: "`conversion-listener`"
    type: "`conversion-listener`"
  - mode: "`conversion-only`"
    type: "`conversion-only`"
  - mode: "`listener`"
    type: "`listener`"
  - mode: "(no V1 equivalent)"
    type: "`upstream-server`"
{% endtable %}

##### Converted configuration files

The following {{site.ai_gateway}} running on {{site.base_gateway}} example config:
* Converts a REST flights API into MCP tools
* Serves the tools on a Route, with `key-auth` in front and a default ACL

<!--vale off-->
```yaml
# kong.yaml (AI Gateway v1, exported with deck gateway dump)
services:
- name: kongair-flights
  url: https://flights.internal.kongair.com
  routes:
  - name: kongair-flights-mcp
    paths:
    - /flights-mcp
  plugins:
  - name: key-auth
  - name: ai-mcp-proxy
    config:
      mode: conversion-listener
      logging:
        log_statistics: true
        log_audits: true
      default_acl:
        allow:
        - flight-operators
      tools:
      - name: search_flights
        description: Search available flights
        # ...OpenAPI-derived tool definition...
```
{:.collapsible}
<!--vale on-->

Converting the example to use the version 2.x model:
* Moves the upstream URL, route, tools, and logging settings onto a single AI MCP Server entity
* Copies the value from the plugin `mode` into the MCP Server `type` 
* Strips the `key-auth` plugin. Like AI Models, an AI MCP Server declares identity separately: add an identity provider manually and reference it from the server's `access.identity_providers`.
* Renames `default_acl` to `default_tool_acls` and sets the ACL evaluation mode explicitly with `acl_attribute_type`
* Renames the `config.logging` fields: `log_audits` becomes `audits` and `log_payloads` becomes `payloads`. `log_statistics` has no AI Gateway 2.x equivalent and is dropped.

<!--vale off-->
```yaml
# identity_providers.yaml (in ./out — generated from the provider you declared
# in ./config in Step 3; the v1 key-auth plugin itself is stripped on conversion)
ai_gateway_identity_providers:
- ref: flights-key-auth
  ai_gateway: !ref ai-gateway#id
  type: key-auth
  name: flights-key-auth
  display_name: Flights Key Auth
  config:
    key_names:
    - apikey

# mcp_servers.yaml (AI Gateway v2 entity model)
ai_gateway_mcp_servers:
- ref: kongair-flights
  ai_gateway: !ref ai-gateway#id
  type: conversion-listener
  name: kongair-flights
  display_name: Kong Air Flights
  enabled: true
  access:
    acl_attribute_type: consumer
    acls:
      allow: []
      deny: []
    default_tool_acls:
      allow:
      - flight-operators
      deny: []
    identity_providers:
    - flights-key-auth
  config:
    url: https://flights.internal.kongair.com
    route:
      paths:
      - /flights-mcp
    logging:
      audits: true
  tools:
  - name: search_flights
    description: Search available flights
    # ...OpenAPI-derived tool definition...
```
{:.collapsible}
<!--vale on-->

##### Verify AI MCP Servers entity configuration

To verify your AI MCP Servers entity migration, be sure to check the following:

- Mode and type: Confirm the `type` matches the original mode. The `conversion-only` and `conversion-listener` modes require Route information, so make sure the converted entity includes a `config.route`.
- Listener aggregation: If you used `conversion-only` plugins feeding a `listener` plugin via tags, confirm the converter preserved the tags so the version 2.x listener AI MCP Server still aggregates the right tools.
- ACL mode: Version 2.x makes the ACL subject explicit. Use `acl_attribute_type: consumer` to evaluate against Consumers and Consumer Groups, or `acl_attribute_type: oauth_access_token` with `access_token_claim_field` to evaluate against a claim in an OAuth2 access token.
- Per-tool ACLs: A per-tool `acl` replaces the default for that tool and does not merge with `default_tool_acls`. Ensure every allowed subject is listed on the tool explicitly.
- Logging field names: `log_payloads` and `log_audits` become `payloads` and `audits` under `config.logging`. `log_statistics` has no AI Gateway 2.x equivalent and is dropped.
- Authentication: Like AI Models, auth plugins on MCP routes (like the `key-auth` example above) are stripped on conversion. Declare the identity provider manually and reference it from the server's `access.identity_providers`.

#### Validate AI Agents

In {{site.ai_gateway}} running on {{site.base_gateway}}, an agent is an [AI A2A Proxy](/plugins/ai-a2a-proxy/) plugin attached to a Service and Route. The plugin is a transparent proxy that adds observability and agent card URL rewriting to Agent-to-Agent (A2A) traffic (where the gateway automatically changes the agent's address so clients connect through the gateway instead of directly to the agent.)

In {{site.ai_gateway}} version 2.x, that plugin becomes an [AI Agent](/ai-gateway/entities/ai-agent/) entity, which captures the following in a single entity and applies the agent card which automatically rewrites the:
* Upstream URL
* Routing
* Logging

##### Converted configuration files

The following example for {{site.ai_gateway}} running on {{site.base_gateway}} defines an A2A agent that proxies an upstream agent that handles flight bookings:

<!--vale off-->
```yaml
# kong.yaml (AI Gateway v1, exported with deck gateway dump)
services:
- name: flight-booking-agent
  url: https://booking-agent.internal.kongair.com
  routes:
  - name: flight-booking-agent-route
    paths:
    - /booking-agent
  plugins:
  - name: ai-a2a-proxy
    config:
      max_request_body_size: 8388608
      logging:
        log_statistics: true
        log_payloads: false
        max_payload_size: 1048576
```
{:.collapsible}
<!--vale on-->

Converting the example to use the version 2.x model:
* Moves the upstream URL, route, request-size limit, and logging settings onto a single AI Agent entity.
* Renames the `config.logging` fields: `log_payloads` becomes `payloads`. `log_statistics` has no AI Gateway 2.x equivalent and is dropped.

Like AI Models and AI MCP Servers, any authentication plugin on the agent's route is stripped on conversion. If the agent needs auth, declare an identity provider manually and reference it from the agent's `access.identity_providers`.

<!--vale off-->
```yaml
# agents.yaml (AI Gateway v2 entity model)
ai_gateway_agents:
- ref: kongair-flight-booking-agent
  ai_gateway: !ref ai-gateway#id
  type: a2a
  name: kongair-flight-booking-agent
  display_name: Kong Air Flight Booking Agent
  enabled: true
  access:
    acls:
      allow: []
      deny: []
  policies: []
  config:
    url: https://booking-agent.internal.kongair.com
    route:
      paths:
      - /booking-agent
    max_request_body_size: 8388608
    logging:
      payloads: false
      max_payload_size: 1048576
```
{:.collapsible}
<!--vale on-->

##### Verify AI Agent entity configuration

To verify your AI Agent entity migration, be sure to check the following:

- Agent type: Most A2A workloads use `type: a2a`. Use `type: http` for plain HTTP agent traffic that does not follow the A2A protocol bindings.
- URL rewriting: The AI Agent entity rewrites the agent card `url` and `additionalInterfaces[].url` fields to the gateway address automatically, the same behavior the older plugin provided. No extra configuration is needed.
- Logging field names: As with AI MCP Servers, `log_payloads` becomes `payloads` under `config.logging`, and `log_statistics` is dropped (no AI Gateway 2.x equivalent).
- Identity: Like AI Models, an AI Agent has no route auth after conversion. If the agent needs authentication, confirm the identity provider you declared is attached via `access.identity_providers`.
- Analytics: A2A metrics flow into {{site.konnect_short_name}} analytics. View them under Agentic usage analytics in {{site.konnect_short_name}} [Explorer](/observability/explorer/) and [Dashboards](/observability/#dashboard).

### Step 6: Authenticate kongctl

`kongctl apply` needs a {{site.konnect_short_name}} PAT or System Account Access Token to reach your control plane. Reuse the token from the [prerequisites](#prerequisites) with one of the following:

- Run `kongctl login` to authenticate interactively through the browser.
- Pass the token with the `--pat` flag on the `apply` command.
- Set the `KONGCTL_DEFAULT_KONNECT_PAT` environment variable.

### Step 7: Apply the configuration

Preview the changes before applying them:

```sh
kongctl diff -f ./out
```

Review the plan, then sync the converted configuration to the {{site.ai_gateway}} control plane:

```sh
kongctl apply -f ./out
```

`kongctl` creates the AI Model Providers, Models, MCP Servers, Agents, and Policies defined in the files. Because the configuration is declarative, you can re-run to apply after edits and `kongctl` will reconcile the control plane to match the files.

After the apply succeeds, the {{site.ai_gateway}} exposes its configuration and telemetry endpoints. Send a representative request to each migrated AI Model, MCP server, and Agent to confirm behavior matches {{site.ai_gateway}} running on {{site.base_gateway}} before you transfer traffic over.

## Verify your migration

After you apply the converted configuration, verify the new control plane before moving production traffic:

- Confirm each AI Model responds. Send a chat or embeddings request to the migrated AI Model route and compare the response and the `X-Kong-LLM-Model` header against its plugin equivalent.
- Confirm AI MCP tool discovery and invocation. Connect an MCP client and list tools, then invoke one. If you migrated ACLs, test with both an allowed and a denied Consumer.
- Confirm AI Agent traffic. Send an A2A request and check that the agent card URL is rewritten to the gateway address and that A2A metrics appear in {{site.konnect_short_name}} analytics.
- Confirm AI Policies took effect. Exercise rate limiting, authentication, and any AI policies such as `ai-sanitizer` to confirm they behave as they did before.
- Compare entity counts. The number of AI Models, MCP Servers, and Agents in the control plane should match the number of corresponding plugins in your {{site.ai_gateway}} running on {{site.base_gateway}} export.

Run the old and new configurations in parallel during cutover so you can roll back by routing traffic to the original control plane if needed.

Once you've successfully generated the `kongctl` config, applied it to your environment, and tested the configuration, you can uninstall the `kongctl-ext-aigw-converter` extension with `kongctl uninstall extension kong/ai-gateway-converter`.

## Troubleshooting

### Recover from a failed apply

If `kongctl apply` fails partway through, `kongctl` skips every remaining resource in that run as "blocked by failed dependencies," even resources that don't actually depend on the one that failed. 
You may hit several different failures in sequence as you fix each one and re-run, since a later error can't surface until an earlier one is resolved.

To recover:

1. Fix the underlying issue. Depending on the error, this might mean editing a file in `./config`, editing `kong.yaml`, or fixing configuration on the source {{site.base_gateway}} control plane (for example, setting a missing model name) and re-exporting with `deck gateway dump`.
1. Delete `./out` and regenerate it from scratch with `kongctl convert ai-gateway`, rather than editing the partially generated files directly.
1. Run `kongctl diff -f ./out` again to confirm the plan looks correct before re-running `kongctl apply -f ./out`.

### Drive kongctl extensions from the converter output

The `./out` directory produced by the converter is a declarative artifact, which makes it a useful input to `kongctl` extensions. `kongctl` ships installable skills for coding agents, including a declarative skill for plan, apply, sync, delete, and adopt flows, and an extension builder for creating local CLI extensions.

Install the skills from the root of the repository where your agent works:

```sh
kongctl install skills
```

By default, this writes skill files to `.kongctl/skills/` and symlinks them for supported agent tooling, for example `.claude/skills/kongctl-declarative` and `.agents/skills/kongctl-extension-builder`. Use `--dry-run` to preview the files and symlinks first, or `--path` to choose a different directory.

With the converter output and these skills in place, you can build extensions that:

- Diff the freshly converted files in `./out` against the live {{site.ai_gateway}} control plane and surface drift before an apply.
- Wrap the full `deck gateway dump`, `kongctl convert ai-gateway`, and `kongctl apply` sequence into a single repeatable command for many control planes.
- Validate that every `targets[].provider` reference resolves and that required fields such as `display_name` are populated, as a pre-apply gate.

This lets you treat {{site.ai_gateway}} migration as a versioned, reviewable, and automated pipeline rather than a one-time manual conversion.


### Set up a fresh install with the {{site.konnect_short_name}} MCP Server

If you would rather start clean instead of converting an existing configuration, you can provision AI Models, AI MCP Servers, and AI Agents directly through the [Kong {{site.konnect_short_name}} MCP Server](/konnect-platform/konnect-mcp/). This is well suited to teams that want to drive setup from an AI assistant or IDE copilot.

Connect your MCP client to the regional {{site.konnect_short_name}} MCP Server endpoint, for example `https://us.mcp.konghq.com/` for the US region, and authenticate with a {{site.konnect_short_name}} PAT or System Account Access Token. All actions respect the permissions of the token you use.

The {{site.konnect_short_name}} MCP Server exposes a discover-then-execute pattern with three core tools:

- `search` finds the relevant API operation from a natural-language description, for example "create an {{site.ai_gateway}} model."
- `get_schema` returns the full schema for that operation so the assistant knows which fields are required.
- `execute` calls the operation with the right inputs.

Using this pattern, you can ask your assistant to create an {{site.ai_gateway}}, declare AI Model Providers, then add AI Models, AI MCP Servers, and AI Agents, with the assistant reasoning over the live schema at each step rather than relying on hardcoded field lists. The same tools power [KAi](/konnect-platform/kai/), Kong's in-product AI assistant, so the workflow is consistent whether you work from an IDE, the terminal, or {{site.konnect_short_name}} itself.
