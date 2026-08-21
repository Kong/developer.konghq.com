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
    description: The API key used to connect to Gemini.
{% endentity_example %}

### Gemini Enterprise

Gemini Enterprise requires GCP credentials instead of an API key. The Provider only handles authentication; `auth.type: gcp` by itself doesn't select Gemini Enterprise, since Gemini Standard can use the same GCP auth. What actually routes to Gemini Enterprise is `config.gcp_environment` on the AI Model's target that attaches to this Provider (see [Gemini base URL](#gemini-base-url)).

Create the Provider to store your GCP credentials:

{% entity_examples %}
formats:
  - kongctl
ai_gateway_model_providers:
  - ref: my-gemini-enterprise-account
    ai_gateway: !lookup name:ai-quickstart
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
    ai_gateway: !lookup name:ai-quickstart
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

{:.info}
> `targets[].config.gcp_environment` requires `api_endpoint`, `location_id`, and `project_id` together. Without it, this same Provider would route to Gemini Standard instead.

## Authentication with GCP IAM

Gemini Enterprise requires credentials from Google Cloud Platform (GCP). Gemini Standard can also use GCP credentials instead of an API key by setting `auth` to `gcp`.

The authentication chain follows the same order of precedence as the `gcloud` tool:
1. Service account JSON defined directly in the Provider: `auth.service_account_json`.
1. Service account JSON defined in environment variable `GCP_SERVICE_ACCOUNT`.
1. Workload IAM Role (for example, a GKE or Deployment Service Account).
1. VM Instance defined IAM Role.

For restricted networks, override the default endpoints with `auth.metadata_url` or `auth.oauth_token_url`.
