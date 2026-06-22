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
  - q: What happens when I update a Provider's credentials?
    a: |
      {{site.ai_gateway}} propagates the credential change to every Model that references the
      Provider (by `name` or `id`). The next request through any of those Models uses the updated
      credentials.

  - q: How does an AI Model reference an AI Provider?
    a: |
      Set [`target_models[].provider`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-provider) on the AI Model to the AI Provider's `name` or `id`.

  - q: Do AI Providers generate any runtime primitives on their own?
    a: |
      No. An AI Provider entity is a write-time template. Credentials and configuration only enter
      the runtime when an AI Model references the AI Provider; at that point, the AI Provider's values are
      materialized into the underlying primitives generated for the AI Model.

  # - q: How do I configure providers in on-prem deployments?
  #   a: |
  #     {{site.ai_gateway}} entities are available only in {{site.konnect_short_name}}.
  #     For on-prem deployments, configure provider credentials and endpoints using {{site.base_gateway}} plugins directly (for example, the AI Proxy plugin).
  #     See the [{{site.base_gateway}} plugin catalog](/gateway/plugins/) for available AI-related plugins.
---

## What is an AI Provider?

An AI Provider is a first-class {{site.ai_gateway}} entity that represents an upstream LLM service connection and its credentials, endpoint configuration, and provider-type-specific options. Each AI Provider has a [`type`](#schema-aigateway-provider-type) that selects the upstream LLM service. See the schema below for supported values, and the per-provider pages under [{{site.ai_gateway}} providers](/ai-gateway/ai-providers/) for provider-specific guidance.

[AI Models](/ai-gateway/entities/ai-model/) reference an AI Provider through [`target_models[].provider`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-provider) to route their `target_models` to that upstream. The reference can use either the AI Provider `name` or `id`. {{site.ai_gateway}} materializes the AI Provider's credentials into the underlying primitives of every AI Model that references it. Updating an AI Provider propagates credential changes to all referencing AI Models.

### Relationship to AI Models

An AI Provider stores how to reach and authenticate to an upstream LLM service. An [AI Model](/ai-gateway/entities/ai-model/) decides which upstream AI Provider model to call and how requests are load-balanced, formatted, and logged. The relationship is many-to-many at the target level: a single AI Provider can back many AI Models (for example, an `openai` AI Provider used by both a chat AI Model and an embeddings AI Model), and a single AI Model can route across multiple AI Providers through its `target_models` array (for example, an AI Model with one OpenAI target and one Anthropic target for fallback).

AI Providers don't expose model endpoints on their own. They become routable only through an AI Model that references them.

AI Providers can be created and managed through the {{site.konnect_short_name}} UI, the {{site.ai_gateway}} API, or decK:

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

The [`config.auth`](#schema-aigateway-provider-config-auth) object declares how {{site.ai_gateway}} authenticates to the upstream provider. The shape of `auth` depends on the Provider's [`type`](#schema-aigateway-provider-type):

* **`basic`**: header- or query-parameter-based auth. Used by most provider types.
* **`aws`**: IAM access-key and assume-role auth. Used by `bedrock`.
* **`azure`**: Microsoft Entra ID or managed-identity auth. Used by `azure`.
* **`gcp`**: Google service-account auth. Used by `gemini` and `vertex`.

`bedrock`, `azure`, and `gemini` can also fall back to `basic` auth.

### AWS Bedrock authentication

For the `bedrock` provider, use `aws` auth type with:

* **`access_key_id`** (optional): AWS access key ID for static IAM user credentials. If omitted, the default AWS credentials provider chain is used (EC2 instance profiles, environment variables, etc.).
* **`secret_access_key`** (optional): AWS secret access key paired with `access_key_id`. Required if `access_key_id` is set.
* **`assume_role_arn`** (optional): IAM role ARN to assume for temporary credentials. Useful for cross-account access.
* **`role_session_name`** (optional): Session name for the assumed role. Required if `assume_role_arn` is set.
* **`sts_endpoint_url`** (optional): Custom STS endpoint for role assumption. Defaults to `https://sts.amazonaws.com`.
* **`batch_role_arn`** (optional): Separate role ARN for Bedrock batch API calls.

Fallback to `basic` auth is supported for API key-based authentication if your Bedrock setup requires it.

### Azure authentication

For the `azure` provider, use `azure` auth type with:

* **`use_managed_identity`**: Set to `true` to use Azure Managed Identity (recommended for deployments in Azure). When true, the system uses the identity of the current Azure resource (VM, container, function app, etc.).
* **`client_id`** (optional): Entra ID (formerly AAD) application client ID. Required if using a user-assigned managed identity or service principal instead of system-assigned managed identity.
* **`client_secret`** (optional): Client secret for the Entra ID application. Required if `client_id` is set.
* **`tenant_id`** (optional): Azure tenant ID (directory ID). Required if using service principal credentials.
* **`instance`** (optional): Azure cloud instance (e.g. `china`, `government`). Defaults to public cloud.

Fallback to `basic` auth is supported for Azure API key authentication.

### GCP authentication

For the `gemini` and `vertex` providers, use `gcp` auth type with:

* **`use_gcp_service_account`**: Set to `true` to use GCP service-account authentication. When true, the system retrieves credentials from the application default credentials chain (service account JSON file, Compute Engine metadata server, etc.).
* **`service_account_json`** (optional): Full JSON string of the GCP service account. If omitted, application default credentials are used. Can be referenced from a Vault.
* **`metadata_url`** (optional): Custom metadata server URL for GCP authentication. Useful in restricted network environments.
* **`oauth_token_url`** (optional): Custom OAuth token endpoint for GCP. Overrides the default Google token server.

Fallback to `basic` auth is supported for GCP API key authentication.

{:.warning}
> Don't commit credential values to source control. Use a secret-management system to inject
> auth values at deployment time, and treat any value checked into a configuration file as
> compromised. Store sensitive values in a Vault and reference them using the vault reference syntax.

## Provider references

[AI Models](/ai-gateway/entities/ai-model/) reference a Provider through the [`target_models[].provider`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-provider) field. The same reference shape is used elsewhere in the schema (such as the embeddings model under a Model's load balancer config). Provider references in {{site.ai_gateway}} entities accept either the Provider [`name`](#schema-aigateway-provider-name) or `id`.

If references use [`name`](#schema-aigateway-provider-name), the `name` field acts as a stable human-readable handle. Renaming a Provider (changing `name`) breaks any Model references that point at the old name.

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
