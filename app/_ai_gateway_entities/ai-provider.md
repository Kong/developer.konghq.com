---
title: AI Providers
content_type: reference
entities:
  - ai-provider
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-provider/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI Provider credentials and configuration used by {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayProvider
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
faqs:
  - q: What happens when I update an AI Provider's credentials?
    a: |
      {{site.ai_gateway}} propagates the credential change to every AI Model that references the
      AI Provider (by `name` or `id`). The next request through any of those AI Models uses the updated
      credentials.

  - q: How does an AI Model reference an AI Provider?
    a: |
      Set the `provider` field in each item of the [`targets`](/ai-gateway/entities/ai-model/#schema-aigateway-model-targets) array on the AI Model to the AI Provider's `name` or `id`.

  - q: Do AI Providers generate any runtime primitives on their own?
    a: |
      No. An AI Provider entity is a write-time template. Credentials and configuration only enter
      the runtime when an AI Model references the AI Provider; at that point, the AI Provider's values are
      materialized into the underlying primitives generated for the AI Model.
---

## What is an AI Provider?

The AI Provider entity lets you securely store and manage credentials for connecting to upstream LLM services. Use AI Providers to store API keys for OpenAI, Azure, Bedrock, or any other LLM provider; centrally manage and rotate credentials across multiple AI Models; and enforce consistent authentication across your deployments.

Each AI Provider has a [`type`](#schema-aigateway-provider-type) that selects the upstream LLM service and configures provider-specific options. See the schema below for supported types, and the per-provider pages under [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific configuration and limitations.

AI Providers can be created and managed through the {{site.konnect_short_name}} UI and the {{site.ai_gateway}} API:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/providers
{% endtable %}

### Relationship to AI Models

AI Providers and AI Models have a many-to-many relationship: one AI Provider can back many AI Models, and one AI Model can route to multiple AI Providers. For example, a single `openai` AI Provider might be used by both a chat AI Model and an embeddings AI Model, while a single AI Model might route to OpenAI and Anthropic targets for failover.

When configuring an [AI Model](/ai-gateway/entities/ai-model/), you reference an AI Provider by setting the `provider` field in each item of the [`targets`](/ai-gateway/entities/ai-model/#schema-aigateway-model-targets) array. You can reference by [`name`](#schema-aigateway-provider-name) or `id`. Use `id` if you plan to rename the AI Provider later.

## Supported AI Providers

{{site.ai_gateway}} supports the following upstream AI providers. The AI Provider's [`type`](#schema-aigateway-provider-type) field selects one of these targets. The following AI Provider-specific pages document supported capabilities, configuration requirements, and limitations.

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
{% icon_card icon="kimi.svg" title="Kimi" cta_url="/ai-gateway/ai-providers/kimi/" %}
{% icon_card icon="metaai.svg" title="Llama" cta_url="/ai-gateway/ai-providers/llama/" %}
{% icon_card icon="xai.svg" title="xAI" cta_url="/ai-gateway/ai-providers/xai/" %}
{% icon_card icon="dashscope.svg" title="Alibaba Cloud DashScope" cta_url="/ai-gateway/ai-providers/dashscope/" %}
{% icon_card icon="cerebras.svg" title="Cerebras" cta_url="/ai-gateway/ai-providers/cerebras/" %}
{% icon_card icon="deepseek.svg" title="DeepSeek" cta_url="/ai-gateway/ai-providers/deepseek/" %}
{% icon_card icon="ollama.svg" title="Ollama" cta_url="/ai-gateway/ai-providers/ollama/" %}
{% icon_card icon="databricks.svg" title="Databricks" cta_url="/ai-gateway/ai-providers/databricks/" %}
{% icon_card icon="vercel.svg" title="Vercel" cta_url="/ai-gateway/ai-providers/vercel/" %}
{% icon_card icon="vllm.svg" title="vLLM" cta_url="/ai-gateway/ai-providers/vllm/" %}
{% endhtml_tag %}

## Authentication

The [`config.auth`](#schema-aigateway-provider-config-auth) object declares how {{site.ai_gateway}} authenticates to the upstream AI Provider. The shape of `auth` depends on the AI Provider's [`type`](#schema-aigateway-provider-type):

* **`basic`**: header- or query-parameter-based auth. Used by most AI Provider types.
* **`aws`**: IAM access-key and assume-role auth. Used by [Bedrock](/ai-gateway/ai-providers/bedrock/).
* **`azure`**: Microsoft Entra ID or managed-identity auth. Used by [Azure OpenAI](/ai-gateway/ai-providers/azure/).
* **`gcp`**: Google service-account auth. Used by [Gemini](/ai-gateway/ai-providers/gemini/) and [Vertex AI](/ai-gateway/ai-providers/vertex/).

{:.info}
> Bedrock, Azure OpenAI, and Gemini can also fall back to `basic` auth.

{% table %}
columns:
  - title: Auth type
    key: type
  - title: Provider name
    key: providers
  - title: Primary approach
    key: approach
  - title: Fallback auth
    key: fallback
rows:
  - type: "`aws`"
    providers: "[Bedrock](/ai-gateway/ai-providers/bedrock/)"
    approach: "IAM via static credentials, assume role, or environment auto-detection (EC2 instance profiles, environment variables, local AWS config). Role assumption recommended for production. Cross-account access supported."
    fallback: "`basic`"
  - type: "`azure`"
    providers: "[Azure OpenAI](/ai-gateway/ai-providers/azure/)"
    approach: "Microsoft Entra ID via Managed Identity (recommended when running in Azure). For explicit credentials, provide client ID, secret, and tenant ID."
    fallback: "`basic`"
  - type: "`gcp`"
    providers: "[Gemini](/ai-gateway/ai-providers/gemini/), [Vertex AI](/ai-gateway/ai-providers/vertex/)"
    approach: "Google service accounts via environment auto-detection (service account JSON or Compute Engine metadata server). Custom metadata or OAuth token endpoints for restricted networks."
    fallback: "`basic`"
{% endtable %}

## Lifecycle

Creating an AI Provider stores the entity but doesn't generate any runtime primitives. AI Provider credentials enter the runtime only when an AI Model references the AI Provider. At that point, the credentials are materialized into the underlying primitives of the AI Model.

Updating an AI Provider re-materializes credentials into every AI Model that references it. The change takes effect on the next request through any referencing AI Model.

## AI Policies and AI Providers

You cannot attach AI Policies directly to an AI Provider entity instance. Policies attach to [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), [AI Consumers](/ai-gateway/entities/ai-consumer/), or [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) to control security, rate limiting, guardrails, and observability.

To apply an AI Policy across requests using a particular AI Provider, you can:
1. Set the policy to `global: true` to apply it to all resources in the gateway
2. Attach the same policy to each AI Model that references the AI Provider
3. Create an AI Consumer Group with the policy and control access to AI Models via ACLs

## Set up an AI Provider

The following example creates an OpenAI Provider that authenticates with a single bearer-token header. A Model can then route to this Provider by setting the `provider` field in a `targets` array item to `my-openai-account` (or the Provider `id`).

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
