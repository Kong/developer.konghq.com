---
title: 'AI Proxy Advanced'
name: 'AI Proxy Advanced'

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
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

## Load balancing

This plugin supports several load-balancing algorithms, similar to those used for Kong upstreams, allowing efficient distribution of requests across different AI models. The supported algorithms include:
* **Lowest-usage**: The lowest-usage algorithm in AI Proxy Advanced is based on the volume of usage for each model. It balances the load by distributing requests to models with the lowest usage, measured by factors such as prompt token counts, response token counts, cost {% new_in 3.10 %}, or other resource metrics.
* **Lowest-latency**: The lowest-latency algorithm is based on the response time for each model. It distributes requests to models with the lowest response time.
* **Semantic**: The semantic algorithm distributes requests to different models based on the similarity between the prompt in the request and the description provided in the model configuration. This allows Kong to automatically select the model that is best suited for the given domain or use case. This feature enhances the flexibility and efficiency of model selection, especially when dealing with a diverse range of AI providers and models.
* [Round-robin (weighted)](/gateway/entities/upstream/#round-robin)
* [Consistent-hashing (sticky-session on given header value)](/gateway/entities/upstream/#consistent-hashing)
* [Priority Group](/gateway/entities/upstream/#round-robin) {% new_in 3.10 %}


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

{% include plugins/ai-proxy/templating.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}