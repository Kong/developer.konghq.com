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

Gemini Enterprise requires GCP credentials instead of an API key. The AI Model Provider only handles authentication. `auth.type: gcp` by itself doesn't select Gemini Enterprise, since Gemini Standard can use the same GCP auth. What routes to Gemini Enterprise is `config.gcp_environment` on the target of the AI Model that attaches to this provider. See [Select Gemini Standard or Gemini Enterprise](#select-gemini-standard-or-gemini-enterprise).

Create the provider to store your GCP credentials:

{% entity_example %}
type: model-provider
data:
  display_name: Gemini Enterprise Production
  name: my-gemini-enterprise-account
  type: gemini
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
      service_account_json: ${gcp_account_json}
variables:
  gcp_account_json:
    value: $GCP_ACCOUNT_JSON
    secret: true
    description: The GCP service account key JSON used to authenticate to Gemini Enterprise.
{% endentity_example %}

Then attach an AI Model to it, setting `config.gcp_environment` on the target to route to Gemini Enterprise:

{% entity_example %}
type: model
data:
  name: my-gemini-enterprise-model
  display_name: my-gemini-enterprise-model
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
    - name: gemini-3.5-flash
      provider: my-gemini-enterprise-account
      config:
        type: gemini
        gcp_environment:
          api_endpoint: aiplatform.googleapis.com
          location_id: global
          project_id: my-gcp-project-id
  policies: []
{% endentity_example %}

`targets[].config.gcp_environment` requires `api_endpoint`, `location_id`, and `project_id`. Set `api_endpoint` to the hostname for your location: `aiplatform.googleapis.com` for `global`, `{location_id}-aiplatform.googleapis.com` for a single region such as `us-east5`, or `aiplatform.{location_id}.rep.googleapis.com` for the multi-region locations `us` and `eu`. You can also set it to a Private Service Connect endpoint.

## Select Gemini Standard or Gemini Enterprise

Gemini Standard and Gemini Enterprise use the same `gemini` provider type.
{{site.ai_gateway}} routes to Gemini Enterprise only when the AI Model target sets `config.gcp_environment` with `api_endpoint`, `location_id`, and `project_id`. Otherwise, it routes to Gemini Standard, whatever the credential type.

For clients that send native Gemini requests, the request path must match the variant:

* If the target sets `gcp_environment`, send Gemini Enterprise paths, such as `/v1/projects/{project_id}/locations/{location}/publishers/google/models/{model_name}:generateContent`.
* If the target doesn't set `gcp_environment`, send Gemini Standard paths.

{{site.ai_gateway}} doesn't rewrite the path from one variant to the other.

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

* **`source`** (required): The identity provider used to obtain temporary GCP credentials. Only `aws_iam` is supported.
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
Gemini uses the signature on the matching part of the next request to keep reasoning context across multi-turn conversations and function calls.

When an AI Model uses the `openai` format with a Gemini target, {{site.ai_gateway}} doesn't return `thoughtSignature` in the OpenAI-compatible response, for streaming or non-streaming requests.
When it translates assistant tool calls in the conversation history to Gemini, {{site.ai_gateway}} sets a placeholder signature on them so that Gemini accepts the history.

To receive the real `thoughtSignature`, use the native Gemini format, which returns Gemini's response without translating it.

## Gemini Interactions API

{{site.ai_gateway}} forwards requests for the [Gemini Interactions API](https://ai.google.dev/gemini-api/docs/interactions) to Gemini without translating the request or response body.
{{site.ai_gateway}} authenticates to Gemini with the credentials in the AI Model Provider.

To use the Interactions API, create an AI Model with the `passthrough` format and a Gemini target:

{% entity_example %}
type: model
data:
  name: my-gemini-interactions
  display_name: my-gemini-interactions
  type: model
  capabilities:
    - generate
  formats:
    - type: passthrough
  config:
    route:
      paths:
        - /gemini
  targets:
    - name: gemini-2.5-flash
      provider: my-gemini-account
      config:
        type: gemini
  policies: []
{% endentity_example %}

Then send requests to the Interactions path through the AI Model's route. For Gemini Standard, the path is `/v1beta/interactions`:

```sh
curl -X POST http://localhost:8000/gemini/v1beta/interactions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-2.5-flash",
    "input": "Say hello"
  }'
```

The same route also forwards streaming requests (`"stream": true`, relayed as server-sent events), background runs (`"background": true`), `GET /gemini/v1beta/interactions/{id}`, `POST /gemini/v1beta/interactions/{id}/cancel`, and `DELETE /gemini/v1beta/interactions/{id}`.

For Gemini Enterprise, the target must set `config.gcp_environment`, and the path is `/v1beta1/projects/{project_id}/locations/{location}/interactions`. Gemini Enterprise supports the Interactions API only in the `global`, `us`, and `eu` regions.

{{site.ai_gateway}} supports the Interactions API only in the native Gemini format.
It doesn't translate OpenAI Responses requests to Interactions, or Interactions requests to the OpenAI or Anthropic formats.
