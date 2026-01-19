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
  - gateway
  - ai-gateway

tags:
  - ai
  - load-balancing

plugins:
  - ai-proxy-advanced

min_version:
  gateway: '3.10'

related_resources:
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
---

Kong AI Gateway gives you advanced load balancing capabilities to efficiently distribute requests across multiple LLM models. This helps you ensure fault tolerance, optimize resource utilization, and balance traffic across your AI systems.

With the [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin, you can select from several load balancing algorithms similar to those used for Kong upstreams but extended for AI model routing. You configure load balancing using the [Upstream entity](/gateway/entities/upstream/), giving you flexibility to fine-tune how requests are routed to various AI providers and LLM models.

### Load balancing algorithms

Kong AI Gateway supports multiple load balancing strategies to optimize traffic distribution across AI models. Each algorithm is suited for different performance goals such as balancing load, improving cache-hit ratios, reducing latency, or ensuring [failover reliability](#retry-and-fallback).

The table below provides a detailed overview of the available algorithms, along with considerations to keep in mind when selecting the best option for your use case.

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
      Distributes requests across models in a circular pattern with weight-based allocation. The [`weight`](/plugins/ai-proxy-advanced/reference/#schema--config-targets-weight) parameter (for example, `weight: 70`) controls the proportion of traffic sent to each model. By default, all models have the same weight and receive the same percentage of requests.
    considerations: |
      * Traffic is routed proportionally based on weights.
      * Requests follow a sequence adjusted by weight.
      * Focuses purely on traffic distribution, not cache-hit ratios.
  - algorithm: "[Consistent-hashing](/plugins/ai-proxy-advanced/examples/consistent-hashing/)"
    description: |
      Routes requests based on a hash of a configurable client input, such as a header or user ID. The [`hash_on_header`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-hash-on-header) setting (for example, `X-Hashing-Header`) defines the source for the hash and drives all routing decisions. By default, the header is set to `X-Kong-LLM-Request-ID`.
    considerations: |
      * Especially effective with consistent keys like user IDs.
      * Requires diverse hash inputs for balanced distribution.
      * Ideal for maintaining session persistence.
  - algorithm: "[Least-connections](/plugins/ai-proxy-advanced/examples/least-connections/)"
    description: |
      {% new_in 3.13 %} Routes requests to backends with the highest spare capacity based on in-flight request counts. In the configuration, the [`weight`](/plugins/ai-proxy-advanced/reference/#schema--config-targets-weight) parameter calculates the connection capacity of each backend.
    considerations: |
      * Provides good distribution of traffic.
      * More dynamic, automatically routing new requests to other backends when slower backends accumulate more open connections.
      * Does not improve cache-hit ratios.
  - algorithm: "[Lowest-usage](/plugins/ai-proxy-advanced/examples/lowest-usage/)"
    description: |
      Routes requests to the least-utilized models based on resource usage metrics. In the configuration, the [`tokens_count_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-tokens-count-strategy) (for example, `prompt-tokens`) defines how usage is measured, focusing on prompt tokens or other resource indicators.
    considerations: |
      * Dynamically balances load based on measured usage.
      * Useful for optimizing cost and avoiding overloading heavier models.
      * Ensures more efficient resource allocation across available models.
  - algorithm: "[Lowest-latency](/plugins/ai-proxy-advanced/examples/lowest-latency/)"
    description: |
      Routes requests to the models with the lowest observed latency. In the configuration, the [`latency_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-latency-strategy) parameter (for example, `latency_strategy: e2e`) defines how latency is measured, typically based on end-to-end response times. By default, the latency is calculated based on the time the model takes to generate each token (`tpot`).
      <br><br>
      The latency algorithm is based on peak EWMA (Exponentially Weighted Moving Average), which ensures that the balancer selects the backend by the lowest latency. The latency metric used is the full request cycle, from TCP connect to body response time. Since it's a moving average, the metrics will decay over time.
    considerations: |
      * Prioritizes models with the fastest response times.
      * Optimizes for real-time performance in time-sensitive applications.
      * Less suitable for long-lived or persistent connections (e.g., WebSockets).
  - algorithm: "[Semantic](/plugins/ai-proxy-advanced/examples/semantic/)"
    description: |
      Routes requests based on semantic similarity between the prompt and model descriptions. In the configuration, embeddings are generated using a specified model (e.g., `text-embedding-3-small`), and similarity is calculated using vector search.
      <br><br>
      {% new_in 3.13 %} Multiple targets can be configured with [identical descriptions](/plugins/ai-proxy-advanced/examples/semantic-with-fallback/). When multiple targets share the same description, the AI balancer performs round-robin fallback among these targets if the primary target fails. Weights affect the order in which fallback targets are selected.
    considerations: |
      * Uses vector search (for example, Redis) to find the best match based on prompt embeddings.
      * `distance_metric` and `threshold` settings fine-tune matching sensitivity.
      * Best for routing prompts to domain-specialized models, like coding, analytics, text generation.
  - algorithm: "[Priority](/plugins/ai-proxy-advanced/examples/priority/)"
    description: |
      Routes requests to models based on assigned priority groups and weights. In the configuration, models are grouped by priority and can have individual [`weight`](/plugins/ai-proxy-advanced/reference/#schema--config-targets-weight) settings (for example, `weight: 70` for GPT-4), allowing proportional load distribution within each priority tier.
      <br><br>
      By default, all models have the same priority. The balancer always chooses one of the targets in the group with the highest priority first. If all targets in the highest priority group are down, the balancer chooses one of the targets in the next highest priority group.
    considerations: |
      * Traffic first targets higher-priority groups; lower-priority groups are used only if needed (failover).
      * Useful for balancing reliability, cost-efficiency, and resource optimization.
      * Ideal for high-availability deployments needing controlled fallback behavior.
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
> _Figure 1:_ A simplified diagram of fallback and retry processing in AI Gateway's load balancer.

#### Retry and fallback configuration

The AI Gateway load balancer supports fine-grained control over failover behavior. Use [`failover_criteria`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-failover-criteria) to define when a request should retry on the next upstream target. By default, retries occur on `error` and `timeout`. An `error` means a failure occurred while connecting to the server, forwarding the request, or reading the response header. A `timeout` indicates that any of those stages exceeded the allowed time.

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

You can customize AI Gateway load balancer to fit different application needs, such as minimizing latency, enabling sticky sessions, or optimizing for cost. The table below maps common scenarios to key configuration options that control load balancing behavior:

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
> Pre-v3.10:
> - Fallbacks only allowed between targets using the same API format.
> - Example: OpenAI-to-OpenAI fallback is supported; OpenAI-to-OLLAMA is not.

### Health check and circuit breaker {% new_in 3.13 %}

{% include ai-gateway/circuit-breaker.md %}