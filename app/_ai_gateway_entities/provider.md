---
title: AI Providers
content_type: reference
entities:
  - ai-provider
products:
  - ai-gateway
description: AI provider credentials and configuration used by {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayProvider
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/
  - text: Model entity
    url: /ai-gateway/entities/model/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
faqs:
  - q: What happens when I update a Provider's credentials?
    a: |
      {{site.ai_gateway}} propagates the credential change to every Model that references the
      Provider by `name`. The next request through any of those Models uses the updated credentials.

  - q: How does a Model reference a Provider?
    a: |
      Set `target_models[].provider.name` on the Model to the Provider's `name`. Provider references
      take a `name` only, not an ID.

  - q: Do Providers generate any runtime primitives on their own?
    a: |
      No. A Provider entity is a write-time template. Credentials and configuration only enter
      the runtime when a Model references the Provider; at that point, the Provider's values are
      materialized into the AI Proxy Advanced plugin instances generated for the Model.
---

## What is a Provider?

A Provider is a first-class {{site.ai_gateway}} entity that represents an upstream LLM service connection: credentials, endpoint configuration, and provider-type-specific options. Each Provider has a `type` that selects the upstream LLM service (see the schema below for supported values, and the per-provider pages under [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific guidance).

Models reference a Provider by `name` to route their `target_models` to that upstream. {{site.ai_gateway}} materializes the Provider's credentials into the AI Proxy Advanced plugin configuration of every Model that references it. Updating a Provider propagates credential changes to all referencing Models.

Providers are managed through the {{site.ai_gateway}} entity API surface in both deployment modes:

{% table %}
columns:
  - title: Deployment
    key: deployment
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - deployment: "{{site.konnect_short_name}}"
    cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/providers
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/providers
{% endtable %}

## Authentication

The `config.auth` object declares how {{site.ai_gateway}} authenticates to the upstream provider. The shape of `auth` depends on the Provider's `type`:

* **`basic`**: header- or query-parameter-based auth. Used by most provider types.
* **`aws`**: IAM access-key and assume-role auth. Used by `bedrock`.
* **`azure`**: Microsoft Entra ID or managed-identity auth. Used by `azure`.
* **`gcp`**: Google service-account auth. Used by `gemini`.

`bedrock`, `azure`, and `gemini` can also fall back to `basic` auth. See the schema below for field-level details, and the per-provider pages under [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific guidance.

{:.warning}
> Don't commit credential values to source control. Use a secret-management system to inject
> auth values at deployment time, and treat any value checked into a configuration file as
> compromised.

## Provider references

Models reference a Provider by `name` through the `target_models[].provider.name` field. The same reference shape is used elsewhere in the schema (such as the embeddings model under a Model's load balancer config). Provider references in {{site.ai_gateway}} entities accept the Provider's `name` only, not its ID.

Because references resolve by `name`, the `name` field is the stable handle for a Provider across the entity surface. Renaming a Provider (changing `name`) breaks any Model reference that pointed at the old value.

## Lifecycle

Creating a Provider stores the entity but doesn't generate any runtime primitives. Provider credentials enter the runtime only when a Model references the Provider — at that point, the credentials are materialized into the AI Proxy Advanced plugin configuration of the Model's derived primitives.

Updating a Provider re-materializes credentials into every Model that references it. The change takes effect on the next request through any referencing Model.

<!-- TODO: confirm what happens when a Provider is deleted while still referenced by a Model. The EE proposal doesn't specify whether deletion is rejected or cascades. -->

## Set up a Provider

The following example creates an OpenAI Provider that authenticates with a single bearer-token header. A Model can then route to this Provider by setting `target_models[].provider.name` to `my-openai-account`.

{% entity_example %}
type: provider
data:
  display_name: OpenAI Production
  name: my-openai-account
  type: openai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer <your-openai-key>
{% endentity_example %}

## Schema

{% entity_schema %}
