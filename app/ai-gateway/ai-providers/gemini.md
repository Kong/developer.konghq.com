---
title: "Gemini provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for the Gemini provider, covering both Gemini Standard and Gemini Enterprise
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-providers/

permalink: /ai-gateway/ai-providers/gemini/

works_on:
 - konnect

products:
  - ai-gateway

tools:
  - konnect-api
  - kongctl

tags:
  - ai

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} Policies"
    url: /ai-gateway/policies/
  - text: AI Providers
    url: /ai-gateway/ai-providers/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/

faqs:
  - q: How can I set model generation parameters when calling Gemini?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-model-params.md %}
  - q: How do I use Gemini's `googleSearch` tool for real-time web searches?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-search.md %}
  - q: How do I control aspect ratio and resolution for Gemini image generation?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-image.md %}
  - q: How do I get reasoning traces from Gemini models?
    a: |
      {% include md/ai-gateway/v2/faqs/gemini-thinking.md %}

---

{% include md/ai-gateway/v2/providers.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini" compare_provider_name="Gemini Enterprise" variant_label="Gemini Standard" compare_variant_label="Gemini Enterprise" %}

{% include md/ai-gateway/v2/native-routes.md providers=site.data.ai-gateway.v2.providers provider_name="Gemini" compare_provider_name="Gemini Enterprise" variant_label="Gemini Standard" compare_variant_label="Gemini Enterprise" %}

## Configure Gemini

To use Gemini with {{site.ai_gateway}}, configure a new [AI Model Provider](/ai-gateway/entities/ai-model-provider/). You can then access supported [AI Models](/ai-gateway/entities/ai-model/) from Gemini.

### Gemini Standard

Here's a minimal configuration for chat completions, authenticating with an API key:

{% entity_example %}
type: model-provider
data:
  display_name: Gemini Production
  name: my-gemini-account
  type: gemini
  config:
    auth:
      type: basic
      headers:
        - name: x-goog-api-key
          value: ${key}
variables:
  key:
    value: $GEMINI_API_KEY
    secret: true
    description: The API key used to connect to Gemini.
{% endentity_example %}

### Gemini Enterprise

Gemini Enterprise requires GCP credentials instead of an API key. The provider only handles authentication; `auth.type: gcp` by itself doesn't select Gemini Enterprise, since Gemini Standard can use the same GCP auth. What actually routes to Gemini Enterprise is `config.gcp_environment` on the AI Model's target that attaches to this provider.

Create the provider to store your GCP credentials:

{% entity_examples %}
formats:
  - kongctl
ai_gateway_model_providers:
  - ref: my-gemini-enterprise-account
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-gemini-enterprise-account
    display_name: "Gemini Enterprise Production"
    type: gemini
    config:
      auth:
        type: gcp
        use_gcp_service_account: true
        service_account_json: !env GCP_ACCOUNT_JSON
{% endentity_examples %}

Then attach an AI Model to it, setting `config.gcp_environment` on the target to route to Gemini Enterprise:

{% entity_examples %}
formats:
  - kongctl
ai_gateway_models:
  - ref: my-gemini-enterprise-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-gemini-enterprise-model
    display_name: "my-gemini-enterprise-model"
    type: model
    capabilities:
      - generate
    formats:
      - type: openai
    config:
      route:
        paths:
          - /v1
    targets:
      - name: gemini-2.5-flash
        provider: my-gemini-enterprise-account
        config:
          type: gemini
          gcp_environment:
            api_endpoint: us-east5-aiplatform.googleapis.com
            location_id: us-east5
            project_id: my-gcp-project-id
    policies: []
{% endentity_examples %}

`targets[].config.gcp_environment` requires `location_id` and `project_id`. `api_endpoint` is optional. When it's unset, {{site.ai_gateway}} derives the Vertex AI hostname from `location_id`:

{% table %}
columns:
  - title: "`location_id`"
    key: location
  - title: Derived `api_endpoint`
    key: endpoint
rows:
  - location: "`global`"
    endpoint: "`aiplatform.googleapis.com`"
  - location: "Any other value, for example `us-east5`"
    endpoint: "`{location_id}-aiplatform.googleapis.com`, for example `us-east5-aiplatform.googleapis.com`"
{% endtable %}

Set `api_endpoint` explicitly to use a different hostname, such as a Private Service Connect endpoint. An explicit value always takes precedence over the derived one.
In {{site.ai_gateway}} 2.2 and earlier, `api_endpoint` is required.

<!-- TODO(AI-174 OQ5): Confirm the derivation rule for `global` and for non-standard regions (for example, multi-region locations such as `us` or `eu`) before publishing. -->
<!-- TODO(AI-174 OQ7): Confirm the minimum data plane version and what the control plane does (block or warn) when `api_endpoint` is omitted for older data planes, then document it here. -->

## Select Gemini Standard or Gemini Enterprise

Gemini Standard and Gemini Enterprise use the same `gemini` provider type.
{{site.ai_gateway}} selects the variant for each request by checking the following, in order:

1. **Inbound request path.** A Vertex AI path that contains `projects/{project_id}/locations/{location}` routes to Gemini Enterprise. A Gemini API path, such as `/v1beta/models/{model_name}:generateContent`, routes to Gemini Standard.
1. **Credential type.** If the path doesn't identify a variant, an API key routes to Gemini Standard, and [GCP service account or OAuth credentials](#authentication-with-gcp-iam) route to Gemini Enterprise.

Existing configurations that set `config.gcp_environment` on the target keep routing to Gemini Enterprise.

<!-- TODO(AI-174 OQ1): Confirm precedence when the request path and credential type disagree, and when either conflicts with an explicit `config.gcp_environment`. The "Gemini Enterprise" section says `auth.type: gcp` alone doesn't select Gemini Enterprise; reconcile that sentence with the credential-type fallback once engineering confirms the behavior. Also confirm where `project_id` and `location_id` come from when the credential type selects Gemini Enterprise without `gcp_environment`. -->

## Authentication with GCP IAM

Gemini Enterprise requires credentials from Google Cloud Platform (GCP). Gemini Standard can also use GCP credentials instead of an API key by setting `auth` to `gcp`.

The authentication chain follows the same order of precedence as the `gcloud` tool:
1. Service account JSON defined directly in the provider: `auth.service_account_json`.
1. Service account JSON defined in environment variable `GCP_SERVICE_ACCOUNT`.
1. Workload IAM role (for example, a GKE or deployment service account).
1. IAM role attached to the VM instance.

For restricted networks, override the default endpoints with `auth.metadata_url` or `auth.oauth_token_url`.

## Authentication with GCP Workload Identity Federation

Instead of a static service account key, you can configure the GCP provider to obtain temporary GCP credentials through Workload Identity Federation, exchanging credentials from an external identity provider for short-lived GCP tokens. This applies to both Gemini Standard and Gemini Enterprise, since both authenticate through the same GCP Provider auth.

To use Workload Identity Federation, set `auth.type` to `gcp` and add a `workload_identity_federation` object:

* **`source`** (required): The identity provider used to obtain temporary GCP credentials. Currently, only `aws_iam` is supported.
* **`auth_json`** (optional): JSON configuration for the Workload Identity Federation token exchange, Google's `external_account` credential config (audience, token URL, credential source, and optional service account impersonation URL). If not set, Kong falls back to the file path in the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

When `source` is `aws_iam`, provide AWS IAM credentials under `aws` to identify the AWS principal used in the token exchange, or omit them to fall back to the default AWS credentials provider chain (EC2 instance profiles, environment variables, and so on):

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`aws.type`"
    description: "Required if `aws` is set. Must be `aws`."
  - field: "`aws.access_key_id`"
    description: "AWS access key ID for static IAM user credentials."
  - field: "`aws.secret_access_key`"
    description: "AWS secret access key paired with `access_key_id`."
  - field: "`aws.session_token`"
    description: "AWS session token for temporary IAM credentials."
  - field: "`aws.region`"
    description: "The AWS region to use. Overrides the region inferred from the environment."
  - field: "`aws.assume_role_arn`"
    description: "IAM role ARN to assume for generating authentication tokens."
  - field: "`aws.role_session_name`"
    description: "Session name for the temporary credentials when assuming the IAM role. Required if `aws.assume_role_arn` is set."
  - field: "`aws.sts_endpoint_url`"
    description: "Custom STS endpoint for role assumption. Defaults to `https://sts.amazonaws.com`."
{% endtable %}

Here's a configuration that authenticates with GCP by assuming an AWS IAM role:

{% entity_example %}
type: model-provider
data:
  display_name: Gemini Production
  name: my-gemini-account
  type: gemini
  config:
    auth:
      type: gcp
      workload_identity_federation:
        source: aws_iam
        aws:
          type: aws
          assume_role_arn: ${role_arn}
          role_session_name: kong-gemini-wif
variables:
  role_arn:
    value: $AWS_ASSUME_ROLE_ARN
    description: The ARN of the AWS IAM role to assume for the Workload Identity Federation token exchange.
{% endentity_example %}

## Thought signatures on the OpenAI-compatible route

A thought signature is an opaque `thoughtSignature` value that Gemini thinking models attach to response parts.
The model needs the signature on the matching part of the next request to keep reasoning context across multi-turn conversations and function calls.
When an AI Model uses the `openai` format with a Gemini target, {{site.ai_gateway}} captures each `thoughtSignature` from the Gemini response and returns it to the client in the OpenAI-compatible response.
When {{site.ai_gateway}} translates the next request back to Gemini, it re-attaches the signature to the matching part.

To keep signatures intact, send the assistant message from the previous response back unchanged in the conversation history, including any tool calls.
{{site.ai_gateway}} doesn't inspect or modify signature contents and doesn't log them at default log levels.

<!-- TODO(AI-174 OQ3): Document where the signature sits in the OpenAI-compatible payload (an extra field or encoded in an existing field), add a short request/response example, and state whether streaming responses are supported. -->
<!-- TODO(AI-174 OQ6): Confirm which capabilities carry signatures (chat completions and Responses are expected). -->

## Gemini Interactions API

{{site.ai_gateway}} forwards requests for the [Gemini Interactions API](https://ai.google.dev/gemini-api/docs/interactions) to Gemini Standard without translating the request or response body.
{{site.ai_gateway}} still authenticates to Gemini with the credentials in the AI Model Provider, and AI Consumer authentication, rate limiting, and logging apply as they do for other Gemini traffic.

{{site.ai_gateway}} supports the Interactions API only in the native Gemini format.
It doesn't translate requests to or from the OpenAI or Anthropic formats.

<!-- TODO(AI-174 OQ4): Document how an AI Model exposes the Interactions API (a `gemini` format route, a new capability, or the `passthrough` format with path detection) and add a kongctl example plus a sample request. -->
<!-- TODO(AI-174 OQ2): List which Policies (guardrails, semantic caching, and so on) and which token and cost analytics apply to Interactions API traffic. Until then, see the passthrough FAQ on Policy compatibility: /ai-gateway/passthrough/ -->

## Vertex AI predict endpoints

Gemini Enterprise supports the Vertex AI [`predict` method](https://cloud.google.com/vertex-ai/docs/reference/rest/v1/projects.locations.endpoints/predict) for Model Garden models that you deploy to your own Vertex AI endpoint, such as TranslateGemma.
{{site.ai_gateway}} proxies both forms of the request:

* Deployed endpoint: `/v1/projects/{project_id}/locations/{location}/endpoints/{endpoint_id}:predict`
* Publisher model: `/v1/projects/{project_id}/locations/{location}/publishers/{publisher}/models/{model_name}:predict`

{{site.ai_gateway}} forwards the `instances` and `parameters` in the request body to Vertex AI unchanged.
The body must match the input schema of the deployed model.

<!-- TODO(AI-174 OQ4): platform-api#3664 doesn't add an `endpoint_id` field to `GCPModelConfig`. Confirm how an AI Model targets a deployed endpoint (endpoint ID taken from the inbound path, a new target field, or `upstream_url`) and whether a new capability or format is needed, then add a kongctl example for TranslateGemma. -->
<!-- TODO(AI-174 OQ2): State which token and cost analytics and which Policies apply to Predict traffic. -->
