---
title: AI Model Providers
content_type: reference
entities:
  - ai-model-provider
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-model-provider/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI Model Provider credentials and configuration used by {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayModelProvider
works_on:
  - konnect
tools:
  - konnect-api
  - kongctl
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
    url: /ai-gateway/ai-providers/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Identity Provider entity
    url: /ai-gateway/entities/ai-identity-provider/
faqs:
  - q: What happens when I update an AI Model Provider's credentials?
    a: |
      {{site.ai_gateway}} propagates the credential change to every AI Model that references the
      AI Model Provider (by `name` or `id`). The next request through any of those AI Models uses the updated
      credentials.

  - q: How does an AI Model reference an AI Model Provider?
    a: |
      Set the `provider` field in each item of the [`targets`](/ai-gateway/entities/ai-model/#schema-aigateway-model-targets) array on the AI Model to the AI Model Provider's `name` or `id`.
---

## What is an AI Model Provider?

The AI Model Provider entity lets you securely store and manage credentials for connecting to upstream LLM services. Use AI Model Providers to:
* Store API keys for OpenAI, Azure, Bedrock, or any other LLM provider
* Centrally manage and rotate credentials across multiple [AI Models](/ai-gateway/entities/ai-model/)
* Enforce consistent authentication across your deployments

An AI Model Provider manages outbound credentials, which is distinct from the inbound authentication managed by an [AI Identity Provider](/ai-gateway/entities/ai-identity-provider/). When an AI Consumer calls an AI Model, the AI Identity Provider checks who they are. The AI Model then uses the AI Model Provider's credentials to forward the request upstream.

Each AI Model Provider has a [`type`](#schema-aigateway-model-provider-type) that selects the upstream LLM service and configures provider-specific options. See the [schema](#schema) for supported types, and the per-provider pages under [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific configuration and limitations.

## Manage AI Model Providers

AI Model Providers can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/model-providers`
* [kongctl](/kongctl/)

For configuration examples and step-by-step setup instructions, see [Set up an AI Model Provider](#set-up-an-ai-model-provider).

### Relationship to AI Models

AI Model Providers and AI Models have a many-to-many relationship: one AI Model Provider can back many AI Models, and one AI Model can route to multiple AI Model Providers. For example, a single `openai` AI Model Provider might be used by both a chat AI Model and an embeddings AI Model, while a single AI Model might route to OpenAI and Anthropic targets for failover.

When configuring an [AI Model](/ai-gateway/entities/ai-model/), you reference an AI Model Provider by setting the `provider` field in each item of the [`targets`](/ai-gateway/entities/ai-model/#schema-aigateway-model-targets) array. You can reference by [`name`](#schema-aigateway-model-provider-name) or `id`. Use `id` if you plan to rename the AI Model Provider later.

## Supported upstream LLM providers

{{site.ai_gateway}} supports the following upstream LLM providers. The AI Model Provider's [`type`](#schema-aigateway-model-provider-type) field selects one of these targets. The following provider-specific pages document supported capabilities, configuration requirements, and limitations.

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

## Outbound authentication

The [`config.auth`](#schema-aigateway-model-provider-config-auth) object declares how {{site.ai_gateway}} authenticates to the upstream AI provider. The shape of `auth` depends on the AI Model Provider's [`type`](#schema-aigateway-model-provider-type):

* **`basic`**: Header- or parameter-based auth. Supports up to one auth header (`config.auth.headers`) and one auth parameter (`config.auth.params`). Parameters can be sent as a query string or in the request body (`config.auth.params[].location`). Used by most AI Model Provider types.
* **`aws`**: IAM access-key and assume-role auth. Used by [Bedrock](/ai-gateway/ai-providers/bedrock/).
* **`azure`**: Microsoft Entra ID or managed-identity auth. Used by [Azure OpenAI](/ai-gateway/ai-providers/azure/).
* **`gcp`**: Google service-account auth. Used by [Gemini](/ai-gateway/ai-providers/gemini/) and [Vertex AI](/ai-gateway/ai-providers/vertex/).

{:.info}
> Bedrock, Azure OpenAI, Gemini, and Vertex AI can also fall back to `basic` auth.

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
    approach: "IAM via static credentials, assume role, or environment auto-detection (EC2 instance profiles, environment variables, local AWS config). Role assumption recommended for production. Cross-account access supported. Use `config.auth.batch_role_arn` to specify a separate IAM role for Bedrock batch API calls."
    fallback: "`basic`"
  - type: "`azure`"
    providers: "[Azure OpenAI](/ai-gateway/ai-providers/azure/)"
    approach: "Microsoft Entra ID via Managed Identity (recommended when running in Azure). For explicit credentials, provide client ID, secret, and tenant ID. Requires `config.instance` (your Azure instance name, for example `kong-az-east`)."
    fallback: "`basic`"
  - type: "`gcp`"
    providers: "[Gemini](/ai-gateway/ai-providers/gemini/), [Vertex AI](/ai-gateway/ai-providers/vertex/)"
    approach: "Google service accounts via environment auto-detection (service account JSON or Compute Engine metadata server). For restricted networks, set `config.auth.metadata_url` or `config.auth.oauth_token_url` to custom endpoints."
    fallback: "`basic`"
{% endtable %}

## Lifecycle

An AI Model Provider stores the credentials, but doesn't generate any runtime primitives.

AI Model Provider credentials are passed to the runtime only when an AI Model references the AI Model Provider. At that point, the credentials are then passed to the AI Model.

When you update the credentials of an AI Model Provider, the new credentials are passed to every AI Model that references it the next time a request is made through the AI Model.

## AI Policies and AI Model Providers

You can't attach [AI Policies](/ai-gateway/entities/ai-policy/) directly to an AI Model Provider entity instance. AI Policies attach to [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), [AI Consumers](/ai-gateway/entities/ai-consumer/), or [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) to control security, rate limiting, guardrails, and observability.

To apply an AI Policy across requests using a particular AI Model Provider, you can:
1. Set the policy to `global: true` to apply it to all resources in the gateway.
1. Attach the same policy to each AI Model that references the AI Model Provider.
1. Create an AI Consumer Group with the policy and control access to AI Models via ACLs.

## Set up an AI Model Provider

The following example creates an OpenAI AI Model Provider that authenticates with a single bearer-token header. An AI Model can then route to this AI Model Provider by setting the `provider` field in a `targets` array item to `my-openai-account` (or the AI Model Provider `id`).

{% entity_example %}
type: model-provider
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
