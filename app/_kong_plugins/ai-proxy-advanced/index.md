---
title: 'AI Proxy Advanced'
name: 'AI Proxy Advanced'

ai_gateway_enterprise: true

content_type: plugin

publisher: kong-inc
description: The AI Proxy Advanced plugin lets you transform and proxy requests to multiple AI providers and models at the same time. This lets you set up load balancing between targets.


products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-proxy-advanced.png

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
  - text: AI Proxy
    url: /plugins/ai-proxy/

examples_groups:
  - slug: open-ai
    text: OpenAI use cases
  - slug: load-balancing
    text: Load balancing use cases

faqs:
  - q: Can I authenticate to Azure AI with Azure Identity?
    a: |
      Yes, if {{site.base_gateway}} is running on Azure, AI Proxy Advanced can detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource, and use it accordingly. 
      In your AI Proxy Advanced configuration, you need to set:
      * [`config.auth.azure_use_managed_identity`](./reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` to use an Azure-Assigned Managed Identity.
      * [`config.targets.auth.azure_use_managed_identity`](./reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` and an [`config.targets.auth.azure_client_id`](./reference/#schema--config-auth-azure-client-id) to use a User-Assigned Identity.
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

## Load balancing

This plugin supports several load-balancing algorithms, similar to those used for Kong upstreams, allowing efficient distribution of requests across different AI models. The supported algorithms include:

<!--vale off-->
{% table %}
columns:
  - title: Algorithm
    key: algorithm
  - title: Description
    key: description
rows:
  - algorithm: "[Consistent-hashing (sticky-session on given header value)](/plugins/ai-proxy-advanced/examples/consistent-hashing/)"
    description: |
      The consistent-hashing algorithm routes requests based on a specified header value (`X-Hashing-Header`). Requests with the same header are repeatedly routed to the same model, enabling sticky sessions for maintaining context or affinity across user interactions.
  - algorithm: "[Lowest-latency](/plugins/ai-proxy-advanced/examples/lowest-latency/)"
    description: |
      The lowest-latency algorithm is based on the response time for each model. It distributes requests to models with the lowest response time.
  - algorithm: "[Lowest-usage](/plugins/ai-proxy-advanced/examples/lowest-usage/)"
    description: |
      The lowest-usage algorithm in AI Proxy Advanced is based on the volume of usage for each model. It balances the load by distributing requests to models with the lowest usage, measured by factors such as:

      * Prompt token counts
      * Response token counts
      * Cost {% new_in 3.10 %}

      Or other resource metrics.
  - algorithm: |
      [Priority group](/plugins/ai-proxy-advanced/examples/priority/) {% new_in 3.10 %}
    description: |
      The priority algorithm routes requests to groups of models based on assigned weights. Higher-weighted groups are preferred, and if all models in a group fail, the plugin falls back to the next group. This allows for reliable failover and cost-aware routing across multiple AI models.
  - algorithm: "[Round-robin (weighted)](/plugins/ai-proxy-advanced/examples/round-robin/)"
    description: |
      The round-robin algorithm distributes requests across models based on their respective weights. For example, if your models `gpt-4`, `gpt-4o-mini`, and `gpt-3` have weights of `70`, `25`, and `5` respectively, they’ll receive approximately 70%, 25%, and 5% of the traffic in turn. Requests are distributed proportionally, independent of usage or latency metrics.
  - algorithm: "[Semantic](/plugins/ai-proxy-advanced/examples/semantic/)"
    description: |
      The semantic algorithm distributes requests to different models based on the similarity between the prompt in the request and the description provided in the model configuration. This allows Kong to automatically select the model that is best suited for the given domain or use case. This feature enhances the flexibility and efficiency of model selection, especially when dealing with a diverse range of AI providers and models.
{% endtable %}
<!--vale on-->

## Retry and fallback

The load balancer has customizable retries and timeouts for requests, and can redirect a request to a different model in case of failure. This allows you to have a fallback in case one of your targets is unavailable.

For versions {% new_in 3.10 %} this plugin supports fallback across targets with any supported formats.
For versions earlier than 3.10, fallback is not supported across targets with different formats. You can still use multiple providers, but only if the formats are compatible.
For example, load balancers with the following target combinations are supported:
* Different OpenAI models
* OpenAI models and Mistral models with the OpenAI format
* Mistral models with the OLLAMA format and Llama models with the OLLAMA format

{:.info}
> Some errors, such as client errors, result in a failure and don't failover to another target.<br/><br/> {% new_in 3.10 %} To configure failover in addition to network errors, set [`config.balancer.failover_criteria`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-failover-criteria) to include:
> * Additional HTTP error codes, like `http_429` or `http_502`
> * The `non_idempotent` setting, as most AI services accept POST requests

## Request and response formats
{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

## Templating {% new_in 3.7 %}

{% include plugins/ai-proxy-advanced/templating.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}