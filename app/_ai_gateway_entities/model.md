---
title: Model
content_type: reference
entities:
  - model
products:
  - ai-gateway
description: AI Models registered with the {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayModel
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: About {{site.ai_gateway}}
    url: /ai-gateway/
  - text: AI Proxy plugin
    url: /plugins/ai-proxy/
  - text: AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: Plugin entity
    url: /gateway/entities/plugin/
  - text: Consumer entity
    url: /gateway/entities/consumer/
  - text: Consumer Group entity
    url: /gateway/entities/consumer-group/
faqs:
  - q: What happens if a request's model doesn't match any Model entity?
    a: Plugins scoped to a Model won't run. Plugins without a Model scope run normally.

  - q: Can the same plugin be configured for multiple Models?
    a: Yes. Create one plugin entry per Model scope. Each entry is resolved independently by the plugin iterator.

  - q: Can I scope a plugin to both a Model and a Consumer, Route, or Service?
    a: Yes. Combined scopes are supported and follow the precedence chain described in [Plugin configuration precedence](#plugin-configuration-precedence).

  - q: Does the Model entity configure the provider, credentials, or endpoint?
    a: |
      Model identifies the model and defines model-level behavior. Provider credentials are managed separately (for example, through provider configuration) and are not stored on the Model itself.

  - q: Does the runtime Model entity have the same fields as the {{site.konnect_short_name}} Model entity?
    a: |
      Not necessarily. The runtime entity is a smaller surface than the {{site.konnect_short_name}} entity, and field parity isn't guaranteed across releases.
      See [Models in {{site.konnect_short_name}} and on-prem deployments](#models-in-konnect-and-on-prem-deployments).

  - q: Where do {{site.konnect_short_name}} Policies fit in?
    a: |
      Policies are control-plane entities. They are translated into runtime plugin configurations scoped to the matching Model. There is no separate runtime Policy entity.
---

## What is a Model?

A Model is a first-class AI Gateway entity that defines a named AI model (for example, `openai/gpt-4o`) for model selection and policy targeting.

You can target policies and supported plugin behavior to a specific Model. This lets you apply different rate limits, guardrails, and transformations per model without duplicating Routes or Services.

In both deployment modes, you configure AI Gateway through first-class AI entities (for example, `ai_model`, `ai_provider`, and `ai_policy`). The control plane derives and manages the underlying runtime primitives (such as Services, Routes, and plugins) from those entities.

For on-prem deployments, this `/ai/*` surface is a bridge architecture that aligns on-prem AI Gateway with the same domain model used in {{site.konnect_short_name}} while the next-generation runtime is introduced.

## Model and plugin interaction

Model participates in runtime plugin resolution alongside other scoping dimensions, such as [Consumer](/gateway/entities/consumer/), [Consumer Group](/gateway/entities/consumer-group/), [Route](/gateway/entities/route/), and [Service](/gateway/entities/service/).

A plugin configuration can reference a Model through its `model` field. When a plugin entry is scoped to a Model, that entry only applies to requests where AI Proxy or AI Proxy Advanced resolves the same model name from the request. Plugin entries without a `model` field apply regardless of which model the request targets.

At runtime, the request model is resolved by the AI routing flow (AI Proxy, AI Proxy Advanced, or a model shim flow, depending on deployment configuration). The plugin iterator then uses the resolved Model to select matching plugin configurations.

{:.warning}
> **Caveat for plugins with priority higher than AI Proxy**
>
> The AI Proxy and AI Proxy Advanced plugins run at priority `770`. Any plugin with a higher priority runs *before* the model is resolved. For those earlier plugins, the Model context is not yet available, and Model-scoped configurations won't activate on that request. See [Limitations](#limitations).

## Models in {{site.konnect_short_name}} and on-prem deployments

The Model entity exists in both {{site.konnect_short_name}} (control plane) and {{site.base_gateway}} (runtime).

In {{site.konnect_short_name}}, you declare Model through the AI Gateway control-plane APIs. During config sync, the control plane translates the configuration into runtime-native data plane configuration.

In on-prem AI Gateway, you declare Model through the `/ai/models` API surface (or compatible tooling such as decK). The on-prem control plane stores AI entities as first-class objects and manages derived runtime primitives for you.

### Deployment mode differences

* In {{site.konnect_short_name}}, Model is managed through {{site.konnect_short_name}} AI Gateway APIs.
* In on-prem AI Gateway, Model is managed through `/ai/*` Admin API endpoints (no workspace prefix).
* In both modes, Model is first-class and runtime primitives are derived from AI entities.

### Policies are control-plane only

AI Gateway exposes a Policy entity for declaring AI guardrails, rate limits, and similar controls against Models. <!-- TODO: link to Policy entity docs once available. -->

The Policy entity has no runtime counterpart. During config sync, each Policy is translated into one or more runtime plugin configurations that target the corresponding runtime Model.

### {{site.konnect_short_name}} and runtime field parity

The runtime Model entity is intentionally a smaller surface than control-plane Model APIs. Depending on deployment mode, some control-plane fields may not map 1:1 to runtime fields.

## Plugin configuration precedence

When multiple plugin configurations could match a request, {{site.base_gateway}} picks the most specific one. Model is treated as an additional specificity axis: within any Consumer / Route / Service tier, the variant with `+ Model` outranks the variant without.

The full precedence chain is:

{% table %}
columns:
  - title: Rank
    key: rank
  - title: Scope combination
    key: scope
rows:
  - rank: 1
    scope: Consumer + Route + Service + Model
  - rank: 2
    scope: Consumer + Route + Service
  - rank: 3
    scope: Consumer Group + Route + Service + Model
  - rank: 4
    scope: Consumer Group + Route + Service
  - rank: 5
    scope: Consumer + Route + Model
  - rank: 6
    scope: Consumer + Route
  - rank: 7
    scope: Consumer + Service + Model
  - rank: 8
    scope: Consumer + Service
  - rank: 9
    scope: Consumer Group + Route + Model
  - rank: 10
    scope: Consumer Group + Route
  - rank: 11
    scope: Consumer Group + Service + Model
  - rank: 12
    scope: Consumer Group + Service
  - rank: 13
    scope: Route + Service + Model
  - rank: 14
    scope: Route + Service
  - rank: 15
    scope: Consumer + Model
  - rank: 16
    scope: Consumer
  - rank: 17
    scope: Consumer Group + Model
  - rank: 18
    scope: Consumer Group
  - rank: 19
    scope: Route + Model
  - rank: 20
    scope: Route
  - rank: 21
    scope: Service + Model
  - rank: 22
    scope: Service
  - rank: 23
    scope: Model
  - rank: 24
    scope: Global
{% endtable %}

## Limitations

Not every plugin can be scoped to a Model. Some plugins run before model context is available, and some are structurally incompatible with Model scoping.

### Plugins that cannot be scoped to a Model

The following plugins do not accept a Model scope:

* Authentication plugins, because they must run before any AI-specific processing to establish the consumer identity that Model-scoped configs depend on:
  * [Basic Authentication](/plugins/basic-auth/)
  * [HMAC Authentication](/plugins/hmac-auth/)
  * [JWE Decrypt](/plugins/jwe-decrypt/)
  * [JWT](/plugins/jwt/)
  * [JWT Signer](/plugins/jwt-signer/)
  * [Key Authentication](/plugins/key-auth/)
  * [Key Authentication Encrypted](/plugins/key-auth-enc/)
  * [LDAP Authentication](/plugins/ldap-auth/)
  * [LDAP Authentication Advanced](/plugins/ldap-auth-advanced/)
  * [OAuth 2.0](/plugins/oauth2/)
  * [OAuth 2.0 Introspection](/plugins/oauth2-introspection/)
  * [OpenID Connect](/plugins/openid-connect/)
  * [Session](/plugins/session/)
  * [Mutual TLS Authentication](/plugins/mtls-auth/)
  * [Header Certificate Authentication](/plugins/header-cert-auth/)
  * [SAML](/plugins/saml/)
  * [Vault Authentication](/plugins/vault-auth/)
* AI routing and agent plugins, because these plugins resolve the model (AI Proxy, AI Proxy Advanced) or operate on protocols where Model scoping is not meaningful (A2A, MCP):
  * [AI Proxy](/plugins/ai-proxy/)
  * [AI Proxy Advanced](/plugins/ai-proxy-advanced/)
  * [AI A2A Proxy](/plugins/ai-a2a-proxy/)
  * [AI MCP Proxy](/plugins/ai-mcp-proxy/)

### Plugins that run before model resolution

Any plugin with a priority higher than `770` (the priority of AI Proxy and AI Proxy Advanced) runs before the model is known. For those plugins, Model-scoped configs are not applied unless one of the following is true:

* [Dynamic plugin ordering](/gateway/plugin-development/entities/plugin/) is enabled to push the plugin's execution after AI Proxy.
* The AI Model Shim plugin is deployed on the route or service to resolve the model during the access phase before other plugins run. <!-- TODO: link once the shim plugin page exists -->

## Set up a Model

The following example shows a Model named `openai/gpt-4o`.

{% entity_example %}
type: model
data:
  name: openai/gpt-4o
formats:
  - deck
  - admin-api
  - konnect-api
{% endentity_example %}

## Scope a plugin to a Model

Once a Model exists, you can scope a Model-aware plugin configuration by setting the `model` field on the plugin.

The following example assumes two Models (`openai/gpt-4o` and `openai/gpt-4o-mini`) already exist and applies a quota to one of them.

{% entity_example %}
type: plugin
data:
  name: ai-rate-limiting-advanced
  model: openai/gpt-4o
  config:
    llm_providers:
      - name: openai
        limit:
          - 3
        window_size:
          - 30
    window_type: fixed
formats:
  - deck
  - admin-api
{% endentity_example %}



## Schema

{% entity_schema %}
