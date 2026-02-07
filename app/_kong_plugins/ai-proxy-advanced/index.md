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
  - ai-proxy

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} providers"
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
  - q: Can I override `config.model.name` by specifying a different model name in the request?
    a: |
      No. The model name must match the one configured in `config.model.name`. If a different model is specified in the request, the plugin returns a 400 error.
  - q: |
      Can I override `temperature`, `top_p`, and `top_k` from the request?
    a: |
      Yes. The values for [`temperature`](./reference/#schema--config-targets-model-options-temperature), [`top_p`](./reference/#schema--config-targets-model-options-top-p), and [`top_k`](./reference/#schema--config-targets-model-options-top-k) in the request take precedence over those set in `config.targets.model.options`.

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

AI Proxy Advanced supports several load balancing algorithms for distributing requests across AI models:

* **[Round-robin](./examples/round-robin/)**: Weighted traffic distribution.
* **[Consistent-hashing](./examples/consistent-hashing/)**: Sticky sessions based on header values.
* **[Least-connections](./examples/least-connections/)**: Route to backends with spare capacity.
* **[Lowest-latency](./examples/lowest-latency/)**: Route to fastest-responding models.
* **[Lowest-usage](./examples/lowest-usage/)**: Route based on token counts or cost.
* **[Semantic](./examples/semantic/)**: Route based on prompt-to-model similarity.
* **[Priority](./examples/priority/)**: Tiered failover across model groups.

{:.info}
> For detailed algorithm descriptions and selection guidance, see [Load balancing algorithms](/ai-gateway/load-balancing/#load-balancing-algorithms).
>
> For load balancing across Gateway Upstreams and Targets instead of LLMs, see [load balancing with {{ site.base_gateway }}](/gateway/load-balancing/).

## Retry and fallback

The [AI load balancer](/ai-gateway/load-balancing/) supports configurable retries, timeouts, and failover to different models when a target is unavailable.

{% new_in 3.10 %} Fallback works across targets with any supported format. You can mix providers freely, for example OpenAI and Mistral. Earlier versions require compatible formats between fallback targets. For configuration details, see [Retry and fallback configuration](/ai-gateway/load-balancing/#retry-and-fallback).

{:.success}
> Client errors don't trigger failover.
> To failover on additional error types, set [`config.balancer.failover_criteria`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-failover-criteria) to include HTTP codes like `http_429` or `http_502`, and `non_idempotent` for POST requests.

## Health check and circuit breaker {% new_in 3.13 %}

The [AI load balancer](/ai-gateway/load-balancing/) supports circuit breakers to improve reliability. If a target reaches the failure threshold defined by [`config.balancer.max_fails`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-max-fails), the load balancer stops routing requests to it until the timeout period ([`config.balancer.fail_timeout`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-fail-timeout)) elapses.

{:.info}
> For configuration details and behavior examples, see [Circuit breaker](/ai-gateway/load-balancing/#health-check-and-circuit-breaker).

## Templating {% new_in 3.7 %}

{% include plugins/ai-proxy-advanced/templating.md plugin=page.name params=site.data.plugins.ai-proxy-advanced.parameters %}

## Vector databases

{% include_cached /plugins/ai-vector-db.md name=page.name %}

{% include plugins/redis-cloud-auth.md %}
