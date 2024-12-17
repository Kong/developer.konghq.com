---
title: 'AI Proxy Advanced'
name: 'AI Proxy Advanced'

content_type: plugin

publisher: kong-inc
description: ''
tier: enterprise


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

# topologies:
#    - hybrid
#    - db-less
#    - traditional

icon: ai-proxy-advanced.png
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

## Load balancing

This plugin supports several load-balancing algorithms, similar to those used for Kong upstreams, allowing efficient distribution of requests across different AI models. The supported algorithms include:
* **Lowest-usage**: The lowest-usage algorithm in AI Proxy Advanced is based on the volume of usage for each model. It balances the load by distributing requests to models with the lowest usage, measured by factors such as prompt token counts, response token counts, or other resource metrics.
* **Lowest-latency**: The lowest-latency algorithm is based on the response time for each model. It distributes requests to models with the lowest response time.
* **Semantic**: The semantic algorithm distributes requests to different models based on the similarity between the prompt in the request and the description provided in the model configuration. This allows Kong to automatically select the model that is best suited for the given domain or use case. This feature enhances the flexibility and efficiency of model selection, especially when dealing with a diverse range of AI providers and models.
* [Round-robin (weighted)](/gateway/latest/how-kong-works/load-balancing/#round-robin)
* [Consistent-hashing (sticky-session on given header value)](/gateway/latest/how-kong-works/load-balancing/#consistent-hashing)


## Retry and fallback

The load balancer has customizable retries and timeouts for requests, and can redirect a request to a different model in case of failure. This allows you to have a fallback in case one of your targets is unavailable.

This plugin does not support fallback over targets with different formats. You can use different providers as long as the formats are compatible.For example, load balancers with these combinations of targets are supported:
* Different OpenAI models
* OpenAI models and Mistral models with the OpenAI format
* Mistral models with the OLLAMA format and Llama models with the OLLAMA format

{:.note}
> Some errors, such as client errors, result in a failure and don't failover to another target.

{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}
{% include plugins/ai-proxy/links.md plugin=page.name %}
