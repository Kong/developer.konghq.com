---
title: "Load balancing with AI Proxy Advanced"
layout: reference
content_type: reference
description: This guide provides an overview of load balancing and retry and fallback strategies in the AI Proxy Advanced plugin.
breadcrumbs:
  - /ai-gateway/

works_on:
 - on-prem
 - konnect

products:
  - ai-gateway
  - gateway

tags:
  - ai
  - load-balancing
  - ai-proxy

plugins:
  - ai-proxy-advanced

min_version:
  gateway: '3.10'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
---

{{site.ai_gateway}} provides load balancing capabilities to distribute requests across multiple LLM models. You can use these features to improve fault tolerance, optimize resource utilization, and balance traffic across your AI systems.

The [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin supports several load balancing algorithms similar to those used for Kong upstreams, extended for AI model routing. You configure load balancing through the [Upstream entity](/gateway/entities/upstream/), which lets you control how requests are routed to various AI providers and models.

### Load balancing algorithms

{{site.ai_gateway}} supports multiple load balancing strategies for distributing traffic across AI models. Each algorithm addresses different goals: balancing load, improving cache-hit ratios, reducing latency, or providing [failover reliability](#retry-and-fallback).

The following table describes the available algorithms and considerations for selecting one.

<!--vale off-->
{% table %}
columns:
  - title: Algorithm
    key: algorithm
  - title: Description
    key: description
  - title: Considerations
    key: considerations
rows:
  - algorithm: "[Round-robin (weighted)](/plugins/ai-proxy-advanced/examples/round-robin/)"
    description: |
      Distributes requests across models based on their assigned weights. For example, if models `gpt-4`, `gpt-4o-mini`, and `gpt-3` have weights of `70`, `25`, and `5`, they receive approximately 70%, 25%, and 5% of traffic respectively. Requests are distributed proportionally, independent of usage or latency metrics.
    considerations: |
      * Traffic is routed proportionally based on weights.
      * Requests follow a circular sequence adjusted by weight.
      * Does not account for cache-hit ratios, latency, or current load.
  - algorithm: "[Consistent-hashing](/plugins/ai-proxy-advanced/examples/consistent-hashing/)"
    description: |
      Routes requests based on a hash of a configurable header value. Requests with the same header value are routed to the same model, enabling sticky sessions for maintaining context across user interactions. The [`hash_on_header`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-hash-on-header) setting defines the header to hash. The default is `X-Kong-LLM-Request-ID`.
    considerations: |
      * Effective with consistent keys like user IDs.
      * Requires diverse hash inputs for balanced distribution.
      * Useful for session persistence and cache-hit optimization.
  - algorithm: "[Least-connections](/plugins/ai-proxy-advanced/examples/least-connections/)"
    description: |
      {% new_in 3.13 %} Tracks the number of in-flight requests for each backend and routes new requests to the backend with the highest spare capacity. The [`weight`](/plugins/ai-proxy-advanced/reference/#schema--config-targets-weight) parameter is used to calculate connection capacity.
    considerations: |
      * Dynamically adapts to backend response times.
      * Routes away from slower backends as they accumulate open connections.
      * Does not account for cache-hit ratios.
  - algorithm: "[Lowest-usage](/plugins/ai-proxy-advanced/examples/lowest-usage/)"
    description: |
      Routes requests to models with the lowest measured resource usage. The [`tokens_count_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-tokens-count-strategy) parameter defines how usage is measured: prompt token counts, response token counts, or cost {% new_in 3.10 %}.
    considerations: |
      * Balances load based on actual consumption metrics.
      * Useful for cost optimization and avoiding overloading individual models.
  - algorithm: "[Lowest-latency](/plugins/ai-proxy-advanced/examples/lowest-latency/)"
    description: |
      Routes requests to the model with the lowest observed latency. The [`latency_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-latency-strategy) parameter defines how latency is measured. The default (`tpot`) uses time-per-output-token. The `e2e` option uses end-to-end response time.
      <br><br>
      The algorithm uses peak EWMA (Exponentially Weighted Moving Average) to track latency from TCP connect through body response. Metrics decay over time.
    considerations: |
      * Prioritizes models with the fastest response times.
      * Suited for latency-sensitive applications.
      * Less suitable for long-lived connections like WebSockets.
  - algorithm: "[Semantic](/plugins/ai-proxy-advanced/examples/semantic/)"
    description: |
      Routes requests based on semantic similarity between the prompt and model descriptions. Embeddings are generated using a specified model (for example, `text-embedding-3-small`), and similarity is calculated using vector search.
      <br><br>
      {% new_in 3.13 %} Multiple targets can share [identical descriptions](/plugins/ai-proxy-advanced/examples/semantic-with-fallback/). When they do, the balancer performs round-robin fallback among them if the primary target fails. Weights affect fallback order.
    considerations: |
      * Requires a vector database (for example, Redis) for similarity matching.
      * The `distance_metric` and `threshold` settings control matching sensitivity.
      * Best for routing prompts to domain-specialized models.
  - algorithm: "[Priority](/plugins/ai-proxy-advanced/examples/priority/)"
    description: |
      {% new_in 3.10 %} Routes requests to models based on assigned priority groups. The balancer always selects from the highest-priority group first. If all targets in that group are unavailable, it falls back to the next group. Within each group, the [`weight`](/plugins/ai-proxy-advanced/reference/#schema--config-targets-weight) parameter controls traffic distribution.
    considerations: |
      * Higher-priority groups receive all traffic until they fail.
      * Lower-priority groups serve as fallback only.
      * Useful for cost-aware routing and controlled failover.
{% endtable %}
<!--vale on-->

### Retry and fallback

The load balancer includes built-in support for **retries** and **fallbacks**. When a request fails, the balancer can automatically retry the same target or redirect the request to a different upstream target.

#### How retry and fallback works

1. Client sends a request.
2. The load balancer selects a target based on the configured algorithm (round-robin, lowest-latency, etc.).
3. If the target fails (based on defined `failover_criteria`), the balancer:

   * **Retries** the same or another target.
   * **Fallbacks** to another available target.

4. If retries are exhausted without success, the load balancer returns a failure to the client.

<!-- vale off -->
{% mermaid %}
flowchart LR
    Client(((Application))) --> LBLB
    subgraph AIGateway
        LBLB[/Load Balancer/]
    end
    LBLB -->|Request| AIProvider1(AI Provider 1)
    AIProvider1 --> Decision1{Is Success?}
    Decision1 -->|Yes| Client
    Decision1 -->|No| AIProvider2(AI Provider 2)
    subgraph Retry
        AIProvider2 --> Decision2{Is Success?}
    end
    Decision2 ------>|Yes| Client
{% endmermaid %}
<!-- vale on -->
> _Figure 1:_ A simplified diagram of fallback and retry processing in {{site.ai_gateway}}'s load balancer.

#### Retry and fallback configuration

{{site.ai_gateway}} load balancer supports fine-grained control over failover behavior. Use [`failover_criteria`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-failover-criteria) to define when a request should retry on the next upstream target. By default, retries occur on `error` and `timeout`. An `error` means a failure occurred while connecting to the server, forwarding the request, or reading the response header. A `timeout` indicates that any of those stages exceeded the allowed time.

You can add more criteria to adjust retry behavior as needed:

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: "[`retries`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-retries)"
    description: |
      Defines how many times to retry a failed request before reporting failure to the client.
      Increase for better resilience to transient errors; decrease if you need lower latency and faster failure.
  - setting: "[`failover_criteria`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-failover-criteria)"
    description: |
      Specifies which types of failures (e.g., `http_429`, `http_500`) should trigger a failover to a different target.
      Customize based on your tolerance for specific errors and desired failover behavior.
  - setting: "[`connect_timeout`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-connect-timeout)"
    description: |
      Sets the maximum time allowed to establish a TCP connection with a target.
      Lower it for faster detection of unreachable servers; raise it if some servers may respond slowly under load.
  - setting: "[`read_timeout`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-read-timeout)"
    description: |
      Defines the maximum time to wait for a server response after sending a request.
      Lower it for real-time applications needing quick responses; increase it for long-running operations.
  - setting: "[`write_timeout`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-write-timeout)"
    description: |
      Sets the maximum time allowed to send the request payload to the server.
      Increase if large request bodies are common; keep short for small, fast payloads.
{% endtable %}
<!--vale on-->

#### Retry and fallback scenarios

You can customize {{site.ai_gateway}} load balancer to fit different application needs, such as minimizing latency, enabling sticky sessions, or optimizing for cost. The table below maps common scenarios to key configuration options that control load balancing behavior:

<!--vale off-->
{% table %}
columns:
  - title: Scenario
    key: scenario
  - title: Action
    key: action
  - title: Description
    key: description
rows:
  - scenario: "Requests must not hang longer than 3 seconds"
    action: "Adjust [`connect_timeout`](/plugins/ai-proxy-advanced/reference/#schema--config-vectordb-redis-connect-timeout), [`read_timeout`](/plugins/ai-proxy-advanced/reference/#schema--config-vectordb-redis-read-timeout), [`write_timeout`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-write-timeout)"
    description: |
      Shorten these timeouts to quickly fail if a server is slow or unresponsive, ensuring faster error handling and responsiveness.
  - scenario: "Prioritize the lowest-latency target"
    action: "Set [`latency_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-latency-strategy) to `e2e`"
    description: |
      Optimize routing based on full end-to-end response time, selecting the target that minimizes total latency.
  - scenario: "Need predictable fallback for the same user"
    action: "Use [`hash_on_header`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-hash-on-header)"
    description: |
      Ensure that the same user consistently routes to the same target, enabling sticky sessions and reliable fallback behavior.
  - scenario: "Models have different costs"
    action: "Set [`tokens_count_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-tokens-count-strategy) to `cost`"
    description: |
      Route requests intelligently by considering cost, balancing model performance with budget optimization.
{% endtable %}
<!--vale on-->

#### Version compatibility for fallbacks

{:.info}
> **{{site.base_gateway}} version compatibility for fallbacks:**
> {% new_in 3.10 %}
> - Full fallback support across targets, even with different API formats.
> - Mix models from different providers if needed (for example, OpenAI and Mistral).
>
> Pre-3.10:
> - Fallbacks only allowed between targets using the same API format.
> - Example: OpenAI-to-OpenAI fallback is supported; OpenAI-to-OLLAMA is not.

### Health check and circuit breaker {% new_in 3.13 %}

{% include ai-gateway/circuit-breaker.md %}