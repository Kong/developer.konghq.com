---
title: "Vertex AI provider"
layout: reference
content_type: reference
description: Reference for supported capabilities for Azure OpenAI provider
breadcrumbs:
  - /ai-gateway/v1/
  - /ai-gateway/v1/ai-providers/

permalink: /ai-gateway/v1/ai-providers/vertex/

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - ai

plugins:
  - ai-proxy-advanced
  - ai-proxy

min_version:
  gateway: '3.8'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/v1/
  - text: Vertex AI tutorials
    url: /how-to/?tags=vertex-ai
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: AI Providers
    url: /ai-gateway/v1/ai-providers/
how_to_list:
  config:
    products:
      - ai-gateway
    tags:
      - vertex-ai
    description: true
    view_more: false
major_version:
  ai-gateway: 1

---

{% include plugins/ai-proxy/providers/providers.md providers=site.data.plugins.ai-proxy provider_name="Gemini Vertex" %}

{% include plugins/ai-proxy/providers/native-routes.md providers=site.data.plugins.ai-proxy provider_name="Gemini Vertex" %}

## Configure {{ provider.name }} with AI Proxy

To use {{ provider.name }} with {{site.ai_gateway}}, configure the [AI Proxy](/plugins/ai-proxy/) or [AI Proxy Advanced](/plugins/ai-proxy-advanced/).

Here's a minimal configuration for chat completions:

{% entity_example %}
type: plugin
data:
  name: ai-proxy
  config:
    route_type: llm/v1/chat
    model:
      provider: gemini
      name: gemini-2.0-flash-exp
      options:
        gemini:
          api_endpoint: Bearer ${gcp_api_endpoint}
          project_id: Bearer ${gcp_project_id}
          location_id: Bearer ${gcp_location_id}
    auth:
      gcp_use_service_account: true
      gcp_service_account_json: Bearer ${gcp_service_account_json}
variables:
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_location_id:
    value: $GCP_LOCATION_ID
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
  gcp_api_endpoint:
    value: $GCP_API_ENDPOINT
{% endentity_example %}

{:.success}
> For more configuration options and examples, see:
> - [AI Proxy examples](/plugins/ai-proxy/examples/)
> - [AI Proxy Advanced examples](/plugins/ai-proxy-advanced/examples/)

<!-- TODO(AI-174): Confirm the {{site.base_gateway}} version that ships the AI Gateway 2.3 Gemini changes in AI Proxy and AI Proxy Advanced. The `new_in 3.17` tags on this page are placeholders. -->

### Derived API endpoint

{% new_in 3.17 %} `model.options.gemini.api_endpoint` is optional. When it's unset, {{site.ai_gateway}} derives the Vertex AI hostname from `model.options.gemini.location_id`: `{location_id}-aiplatform.googleapis.com`, or `aiplatform.googleapis.com` when `location_id` is `global`. Set `api_endpoint` explicitly to use a different hostname, such as a Private Service Connect endpoint. An explicit value always takes precedence over the derived one.

<!-- TODO(AI-174 OQ5): Confirm the derivation rule for `global` and for non-standard regions. -->

### Select Gemini or Vertex AI

{% new_in 3.17 %} Gemini and Vertex AI both use `model.provider: gemini`. {{site.ai_gateway}} decides where to send each request by checking the following, in order:

1. **Inbound request path.** A Vertex AI path that contains `projects/{project_id}/locations/{location}` routes to Vertex AI. A Gemini API path, such as `/v1beta/models/{model_name}:generateContent`, routes to the Gemini API.
1. **Credential type.** If the path doesn't identify a target, an API key (`auth.param_name` or `auth.header_name`) routes to the Gemini API, and GCP credentials (`auth.gcp_use_service_account`) route to Vertex AI.

If you set Vertex AI fields (`project_id`, `location_id`, `api_endpoint`, or `endpoint_id`) outside `model.options.gemini`, {{site.ai_gateway}} reads them as if they were set in `model.options.gemini`.

<!-- TODO(AI-174 OQ1): Confirm precedence when the request path and credential type disagree, and when either conflicts with explicitly configured `model.options.gemini` fields. Confirm the exact locations of "misplaced" Vertex fields that get relocated (AI-106) and list them here. -->

## Vertex AI Predict endpoints

{% new_in 3.17 %} To call a Model Garden model that you've deployed to a Vertex AI endpoint, such as TranslateGemma, set `model.options.gemini.endpoint_id` to the endpoint ID along with `project_id` and `location_id`. {{site.ai_gateway}} sends the request to the Vertex AI [`predict` method](https://cloud.google.com/vertex-ai/docs/reference/rest/v1/projects.locations.endpoints/predict) at `/v1/projects/{project_id}/locations/{location}/endpoints/{endpoint_id}:predict`. The publisher model form, `/v1/projects/{project_id}/locations/{location}/publishers/{publisher}/models/{model_name}:predict`, is also supported.

{{site.ai_gateway}} forwards the `instances` and `parameters` in the request body to Vertex AI unchanged, so the body must match the input schema of the deployed model.

<!-- TODO(AI-174 OQ4): Confirm the `route_type` for Predict (a new value, or `preserve` with path detection) and add an `entity_example` for TranslateGemma using that route type. -->
<!-- TODO(AI-174 OQ2): State which analytics, cost tracking, and guardrail plugins apply to Predict traffic. -->

For thought signature handling on the OpenAI-compatible route, see [Gemini provider](/ai-gateway/v1/ai-providers/gemini/#thought-signatures-on-the-openai-compatible-route).

## Authentication with GCP IAM

Using {{ provider.name }} requires credentials from Google Cloud Platform (GCP).

The authentication chain follows the same order of precedence as the `gcloud` tool:
1. Service account JSON defined directly in the AI Proxy or AI Proxy Advanced plugin: `auth.gcp_service_account_json`.
1. Service account JSON defined in environment variable `GCP_SERVICE_ACCOUNT`.
1. Workload IAM Role (for example, a GKE or Deployment Service Account).
1. VM Instance defined IAM Role.

{% include plugins/ai-proxy/providers/how-tos.md %}