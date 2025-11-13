---
title: 'AI Proxy'
name: 'AI Proxy'

content_type: plugin

publisher: kong-inc
description: The AI Proxy plugin lets you transform and proxy requests to a number of AI providers and models.


products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.6'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-proxy.png

categories:
  - ai

tags:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Gateway providers
    url: /ai-gateway/ai-providers/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Get started with AI Gateway
    url: /ai-gateway/get-started/

examples_groups:
  - slug: open-ai
    text: OpenAI use cases
  - slug: multimodal-open-ai
    text: Multimodal route types for OpenAI
  - slug: openai-processing
    text: Other OpenAI processing routes
  - slug: azure-processing
    text: Azure processing routes
  - slug: native-routes
    text: Native routes

faqs:
  - q: Can I authenticate to Azure AI with Azure Identity?
    a: |
      Yes, if {{site.base_gateway}} is running on Azure, AI Proxy can detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource, and use it accordingly.
      In your AI Proxy configuration, set the following parameters:
      * [`config.auth.azure_use_managed_identity`](./reference/#schema--config-auth-azure-use-managed-identity) to `true` to use an Azure-Assigned Managed Identity.
      * [`config.auth.azure_use_managed_identity`](./reference/#schema--config-auth-azure-use-managed-identity) to `true` and an [`config.auth.azure_client_id`](./reference/#schema--config-auth-azure-client-id) to use a User-Assigned Identity.
  - q: Can I override `config.model.name` by specifying a different model name in the request?
    a: |
      No. The model name must match the one configured in `config.model.name`. If a different model is specified in the request, the plugin returns a 400 error.
  - q: |
      Can I override `temperature`, `top_p`, and `top_k` from the request?
    a: |
      Yes. The values for [`temperature`](./reference/#schema--config-model-options-temperature), [`top_p`](./reference/#schema--config-model-options-top-p), and [`top_k`](./reference/#schema--config-model-options-top-k) in the request take precedence over those set in `config.targets.model.options`.

  - q: How can I set model generation parameters when calling Gemini?
    a: |
      You have several options, depending on the SDK and configuration:

      - Use the **Gemini SDK**:

        1. Set [`llm_format`](./reference/#schema--config-llm-format) to `gemini`.
        1. Use the Gemini provider.
        1. Configure parameters like [`temperature`](./reference/#schema--config-model-options-temperature), [`top_p`](./reference/#schema--config-model-options-top-p), and [`top_k`](./reference/#schema--config-model-options-top-k) on the client side:
            ```python
            model = genai.GenerativeModel(
                'gemini-1.5-flash',
                generation_config=genai.types.GenerationConfig(
                    temperature=0.7,
                    top_p=0.9,
                    top_k=40,
                    max_output_tokens=1024
                )
            )
            ```

      - Use the **OpenAI SDK** with the Gemini provider:
        1. Set [`llm_format`](./reference/#schema--config-llm-format) to `openai`.
        1. You can configure parameters in one of three ways:
          - Configure them in the plugin only.
          - Configure them in the client only.
          - Configure them in both—the client-side values will override plugin config.

  - q: Can I override authentication values from the request?
    a: |
      Yes, but only if [`config.auth.allow_override`](./reference/#schema--config-auth-allow-override) is set to `true` in the plugin configuration.
      When enabled, this allows request-level auth parameters (such as API keys or bearer tokens) to override the static values defined in the plugin.
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Request and response formats
{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

## Templating {% new_in 3.7 %}

{% include plugins/ai-proxy/templating.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}
