---
title: 'AI Proxy Advanced'
name: 'AI Proxy Advanced'

tier: ai_gateway_enterprise
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
  - text: Embedding-based similarity matching in Kong AI gateway plugins
    url: /ai-gateway/semantic-similarity/

examples_groups:
  - slug: open-ai
    text: OpenAI use cases
  - slug: load-balancing
    text: Load balancing use cases
  - slug: multimodal-open-ai
    text: Multimodal route types for OpenAI
  - slug: openai-processing
    text: Other OpenAI processing routes
  - slug: azure-processing
    text: Azure processing routes
  - slug: native-routes
    text: Native routes
  - slug: claude-code
    text: claude-code

faqs:
  - q: Can I authenticate to Azure AI with Azure Identity?
    a: |
      Yes, if {{site.base_gateway}} is running on Azure, AI Proxy Advanced can detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource, and use it accordingly.
      In your AI Proxy Advanced configuration, set the following parameters:
      * [`config.auth.azure_use_managed_identity`](./reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` to use an Azure-Assigned Managed Identity.
      * [`config.targets.auth.azure_use_managed_identity`](./reference/#schema--config-targets-auth-azure-use-managed-identity) to `true` and an [`config.targets.auth.azure_client_id`](./reference/#schema--config-targets-auth-azure-client-id) to use a User-Assigned Identity.
  - q: Can I override `config.model.name` by specifying a different model name in the request?
    a: |
      No. The model name must match the one configured in `config.model.name`. If a different model is specified in the request, the plugin returns a 400 error.
  - q: |
      Can I override `temperature`, `top_p`, and `top_k` from the request?
    a: |
      Yes. The values for [`temperature`](./reference/#schema--config-targets-model-options-temperature), [`top_p`](./reference/#schema--config-targets-model-options-top-p), and [`top_k`](./reference/#schema--config-targets-model-options-top-k) in the request take precedence over those set in `config.targets.model.options`.

  - q: How can I set model generation parameters when calling Gemini?
    a: |
      You have several options, depending on the SDK and configuration:

      - Use the **Gemini SDK**:

        1. Set [`llm_format`](./reference/#schema--config-llm-format) to `gemini`.
        1. Use the Gemini provider.
        1. Configure parameters like [`temperature`](./reference/#schema--config-targets-model-options-temperature), [`top_p`](./reference/#schema--config-targets-model-options-top-p), and [`top_k`](./reference/#schema--config-targets-model-options-top-k) on the client side:
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
      Yes, but only if [`config.targets.auth.allow_override`](./reference/#schema--config-targets-auth-allow-override) is set to `true` in the plugin configuration.
      When enabled, this allows request-level auth parameters (such as API keys or bearer tokens) to override the static values defined in the plugin.

  - q: What algorithm does `ai-proxy-advanced` use for selecting the lowest latency target?
    a: |
      It uses Kong’s built-in load balancing mechanism with the EWMA (Exponentially Weighted Moving Average) algorithm to dynamically route traffic to the backend with the lowest observed latency.

  - q: What is the duration of the learning phase with AI Proxy Advanced?
    a: |
      There’s no fixed time window. EWMA continuously updates with every response, giving more weight to recent observations. Older latencies decay over time, but still contribute in smaller proportions.

  - q: How does AI Proxy Advanced distribute traffic once a faster model is identified?
    a: |
      The fastest model gets a majority of traffic, but Kong never sends 100% to a single target unless it's the only one available. In practice, the dominant target may receive ~90–99% of traffic, depending on how much better its EWMA score is.

  - q: Does the system continue testing other targets when the AI Proxy Advanced plugin identifies the fastest model?
    a: |
      Yes. EWMA ensures all targets continue to receive a small amount of traffic. This ongoing probing lets the system adapt if a previously slower model becomes faster later.

  - q: What’s the approximate percentage of traffic sent to non-dominant targets with AI Proxy Advanced?
    a: |
      While exact percentages vary with latency gaps, less performant targets typically get between 0.1%–5% of traffic, just enough to keep updating their EWMA score for comparison.
  - q: |
      How do I resolve the MemoryDB error `Number of indexes exceeds the limit`?
    a: |
      If you see the following error in the logs:

      ```sh
      failed to create memorydb instance failed to create index: LIMIT Number of indexes (11) exceeds the limit (10)
      ```

      This means that the hardcoded MemoryDB instance limit has been reached.
      To resolve this, create more MemoryDB instances to handle multiple {{page.name}} plugin instances.

---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

## Request and response formats

{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

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
  - algorithm: "[Least-connections](/plugins/ai-proxy-advanced/examples/least-connections/)"
    description: |
      {% new_in 3.13 %} The least-connections algorithm tracks the number of in-flight requests for each backend. Weights are used to calculate the connection capacity of a backend. Requests are routed to the backend with the highest spare capacity. This option is more dynamic, automatically routing new requests to other backends when slower backends accumulate more open connections.
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
      The round-robin algorithm distributes requests across models based on their respective weights. For example, if your models `gpt-4`, `gpt-4o-mini`, and `gpt-3` have weights of `70`, `25`, and `5` respectively, they'll receive approximately 70%, 25%, and 5% of the traffic in turn. Requests are distributed proportionally, independent of usage or latency metrics.
  - algorithm: "[Semantic](/plugins/ai-proxy-advanced/examples/semantic/)"
    description: |
      The semantic algorithm distributes requests to different models based on the similarity between the prompt in the request and the description provided in the model configuration. This allows Kong to automatically select the model that is best suited for the given domain or use case.

      {% new_in 3.13 %} Multiple targets can be [configured with identical descriptions](/plugins/ai-proxy-advanced/examples/semantic-with-fallback/). When multiple targets share the same description, the AI balancer performs round-robin fallback among these targets if the primary target fails. Weights affect the order in which fallback targets are selected.
{% endtable %}
<!--vale on-->

## Retry and fallback

The [load balancer](/ai-gateway/load-balancing/) has customizable retries and timeouts for requests, and can redirect a request to a different model in case of failure. This allows you to have a fallback in case one of your targets is unavailable.

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

## Health check and circuit breaker {% new_in 3.13 %}

{% include ai-gateway/circuit-breaker.md %}

## Templating {% new_in 3.7 %}

{% include plugins/ai-proxy-advanced/templating.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

## Vector databases

{% include_cached /plugins/ai-vector-db.md name=page.name %}

{% include plugins/redis-cloud-auth.md %}
