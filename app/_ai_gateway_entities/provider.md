---
title: AI Providers
content_type: reference
entities:
  - ai-provider
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
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
      Provider (by `name` or `id`). The next request through any of those Models uses the updated
      credentials.

  - q: How does a Model reference a Provider?
    a: |
      Set `target_models[].provider` on the Model to the Provider's `name` or `id`.

  - q: Do Providers generate any runtime primitives on their own?
    a: |
      No. A Provider entity is a write-time template. Credentials and configuration only enter
      the runtime when a Model references the Provider; at that point, the Provider's values are
      materialized into the underlying primitives generated for the Model.
---

## What is a Provider?

A Provider is a first-class {{site.ai_gateway}} entity that represents an upstream LLM service connection and their credentials, endpoint configuration, and provider-type-specific options. Each Provider has a `type` that selects the upstream LLM service. See the schema below for supported values, and the per-provider pages under [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific guidance.

Models reference a Provider through `target_models[].provider` to route their `target_models` to that upstream. The reference can use either the Provider `name` or `id`. {{site.ai_gateway}} materializes the Provider's credentials into the underlying primitives of every Model that references it. Updating a Provider propagates credential changes to all referencing Models.

### Relationship to Models

A Provider stores how to reach and authenticate to an upstream LLM service. A [Model](/ai-gateway/entities/model/) decides which upstream provider model to call and how requests are load-balanced, formatted, and logged. The relationship is many-to-many at the target level: a single Provider can back many Models (for example, an `openai` Provider used by both a chat Model and an embeddings Model), and a single Model can route across multiple Providers through its `target_models` array (for example, a Model with one OpenAI target and one Anthropic target for fallback).

Providers don't expose model endpoints on their own. They become routable only through a Model that references them.

Providers can be created and managed through the {{site.konnect_short_name}} UI, the {{site.ai_gateway}} API, decK, or the on-prem Admin API:

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

## Supported providers

{{site.ai_gateway}} supports the following upstream providers. The Provider's [`type`](#schema-aigateway-provider-type) field selects one of these connections. Per-provider pages document supported capabilities, configuration requirements, and provider-specific limitations.

{% html_tag type="div" css_classes="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3" %}
{% icon_card icon="openai.svg" title="OpenAI" cta_url="/ai-gateway/ai-providers/openai/" %}
{% icon_card icon="azure.svg" title="Azure OpenAI" cta_url="/ai-gateway/ai-providers/azure/" %}
{% icon_card icon="bedrock.svg" title="Amazon Bedrock" cta_url="/ai-gateway/ai-providers/bedrock/" %}
{% icon_card icon="anthropic.svg" title="Anthropic" cta_url="/ai-gateway/ai-providers/anthropic/" %}
{% icon_card icon="gemini.svg" title="Gemini" cta_url="/ai-gateway/ai-providers/gemini/" %}
{% icon_card icon="vertex.svg" title="Vertex AI" cta_url="/ai-gateway/ai-providers/vertex/" %}
{% icon_card icon="cohere.svg" title="Cohere" cta_url="/ai-gateway/ai-providers/cohere/" %}
{% icon_card icon="mistral.svg" title="Mistral" cta_url="/ai-gateway/ai-providers/mistral/" %}
{% icon_card icon="huggingface.svg" title="Hugging Face" cta_url="/ai-gateway/ai-providers/huggingface/" %}
{% icon_card icon="metaai.svg" title="Llama" cta_url="/ai-gateway/ai-providers/llama/" %}
{% icon_card icon="xai.svg" title="xAI" cta_url="/ai-gateway/ai-providers/xai/" %}
{% icon_card icon="dashscope.svg" title="Alibaba Cloud DashScope" cta_url="/ai-gateway/ai-providers/dashscope/" %}
{% icon_card icon="cerebras.svg" title="Cerebras" cta_url="/ai-gateway/ai-providers/cerebras/" %}
{% icon_card icon="deepseek.svg" title="DeepSeek" cta_url="/ai-gateway/ai-providers/deepseek/" %}
{% icon_card icon="ollama.svg" title="Ollama" cta_url="/ai-gateway/ai-providers/ollama/" %}
{% icon_card icon="databricks.svg" title="Databricks" cta_url="/ai-gateway/ai-providers/databricks/" %}
{% icon_card icon="vllm.svg" title="vLLM" cta_url="/ai-gateway/ai-providers/vllm/" %}
{% endhtml_tag %}

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

Models reference a Provider through the `target_models[].provider` field. The same reference shape is used elsewhere in the schema (such as the embeddings model under a Model's load balancer config). Provider references in {{site.ai_gateway}} entities accept either the Provider `name` or `id`.

If references use `name`, the `name` field acts as a stable human-readable handle. Renaming a Provider (changing `name`) breaks any Model references that point at the old name.

## Lifecycle

Creating a Provider stores the entity but doesn't generate any runtime primitives. Provider credentials enter the runtime only when a Model references the Provider. At that point, the credentials are materialized into the underlying primitives of the Model.

Updating a Provider re-materializes credentials into every Model that references it. The change takes effect on the next request through any referencing Model.

## Set up a Provider

The following example creates an OpenAI Provider that authenticates with a single bearer-token header. A Model can then route to this Provider by setting `target_models[].provider` to `my-openai-account` (or the Provider `id`).

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
