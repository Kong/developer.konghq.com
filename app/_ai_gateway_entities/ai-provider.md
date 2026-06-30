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
      Set [`target_models[].provider`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-provider) on the AI Model to the AI Provider's `name` or `id`.

  - q: Do AI Providers generate any runtime primitives on their own?
    a: |
      No. An AI Provider entity is a write-time template. Credentials and configuration only enter
      the runtime when an AI Model references the AI Provider; at that point, the AI Provider's values are
      materialized into the underlying primitives generated for the AI Model.
---

## What is an AI Provider?

An AI Provider is a first-class {{site.ai_gateway}} entity that represents an upstream LLM service connection and its credentials, endpoint configuration, and provider-type-specific options. Each AI Provider has a [`type`](#schema-aigateway-provider-type) that selects the upstream LLM service. See the schema below for supported values, and the per-provider pages under [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific guidance.

[AI Models](/ai-gateway/entities/ai-model/) reference an AI Provider through [`target_models[].provider`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-provider) to route their `target_models` to that upstream. The reference can use either the AI Provider `name` or `id`. {{site.ai_gateway}} materializes the AI Provider's credentials into the underlying primitives of every AI Model that references it. Updating an AI Provider propagates credential changes to all referencing AI Models.

### Relationship to AI Models

An AI Provider stores how to reach and authenticate to an upstream LLM service. An [AI Model](/ai-gateway/entities/ai-model/) decides which upstream AI Provider model to call and how requests are load-balanced, formatted, and logged. The relationship is many-to-many at the target level: a single AI Provider can back many AI Models (for example, an `openai` AI Provider used by both a chat AI Model and an embeddings AI Model), and a single AI Model can route across multiple AI Providers through its `target_models` array (for example, an AI Model with one OpenAI target and one Anthropic target for fallback).

AI Providers don't expose model endpoints on their own. They become routable only through an AI Model that references them.

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

## Supported providers

{{site.ai_gateway}} supports the following upstream providers. The AI Provider's [`type`](#schema-aigateway-provider-type) field selects one of these connections. Per-provider pages document supported capabilities, configuration requirements, and provider-specific limitations.

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

The [`config.auth`](#schema-aigateway-provider-config-auth) object declares how {{site.ai_gateway}} authenticates to the upstream provider. The shape of `auth` depends on the AI Provider's [`type`](#schema-aigateway-provider-type):

* **`basic`**: header- or query-parameter-based auth. Used by most provider types.
* **`aws`**: IAM access-key and assume-role auth. Used by [Bedrock](/ai-gateway/ai-providers/bedrock/).
* **`azure`**: Microsoft Entra ID or managed-identity auth. Used by [Azure OpenAI](/ai-gateway/ai-providers/azure/).
* **`gcp`**: Google service-account auth. Used by [Gemini](/ai-gateway/ai-providers/gemini/) and [Vertex AI](/ai-gateway/ai-providers/vertex/).

[Bedrock](/ai-gateway/ai-providers/bedrock/), [Azure OpenAI](/ai-gateway/ai-providers/azure/), and [Gemini](/ai-gateway/ai-providers/gemini/) can also fall back to `basic` auth.

### AWS Bedrock authentication

The [Bedrock](/ai-gateway/ai-providers/bedrock/) provider uses `aws` auth type to authenticate via IAM. You can provide static credentials (access key and secret key), assume an IAM role for temporary credentials, or let {{site.ai_gateway}} auto-detect credentials from the environment (EC2 instance profiles, environment variables, or local AWS configuration). Assuming a role is recommended for production deployments. Cross-account access is supported via role assumption. Alternatively, [Bedrock](/ai-gateway/ai-providers/bedrock/) also accepts `basic` auth if you prefer API key authentication.

### Azure authentication

The [Azure OpenAI](/ai-gateway/ai-providers/azure/) provider uses `azure` auth type to authenticate via Microsoft Entra ID. The recommended approach is to enable Managed Identity when running {{site.ai_gateway}} in Azure (VMs, containers, functions). For scenarios requiring explicit credentials, provide a client ID, secret, and tenant ID. Alternatively, [Azure OpenAI](/ai-gateway/ai-providers/azure/) also accepts `basic` auth for API key authentication.

### GCP authentication

The [Gemini](/ai-gateway/ai-providers/gemini/) and [Vertex AI](/ai-gateway/ai-providers/vertex/) providers use `gcp` auth type to authenticate via Google service accounts. The default approach is to let {{site.ai_gateway}} auto-detect credentials from the environment (service account JSON file or Compute Engine metadata server). For restricted network environments, you can provide custom metadata or OAuth token endpoints. Alternatively, [Gemini](/ai-gateway/ai-providers/gemini/) and [Vertex AI](/ai-gateway/ai-providers/vertex/) also accept `basic` auth for API key authentication.

{:.warning}
> Don't commit credential values to source control. Use a secret-management system to inject
> auth values at deployment time, and treat any value checked into a configuration file as
> compromised. Store sensitive values in a Vault and reference them using the vault reference syntax.

## Provider references

[AI Models](/ai-gateway/entities/ai-model/) reference an AI Provider through the [`target_models[].provider`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-provider) field. The same reference shape is used elsewhere in the schema (such as the embeddings model under an AI Model's load balancer config). AI Provider references in {{site.ai_gateway}} entities accept either the AI Provider [`name`](#schema-aigateway-provider-name) or `id`.

If references use [`name`](#schema-aigateway-provider-name), the `name` field acts as a stable human-readable handle. Renaming an AI Provider (changing `name`) breaks any AI Model references that point at the old name.

## Lifecycle

Creating an AI Provider stores the entity but doesn't generate any runtime primitives. AI Provider credentials enter the runtime only when an AI Model references the AI Provider. At that point, the credentials are materialized into the underlying primitives of the AI Model.

Updating an AI Provider re-materializes credentials into every AI Model that references it. The change takes effect on the next request through any referencing AI Model.

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
