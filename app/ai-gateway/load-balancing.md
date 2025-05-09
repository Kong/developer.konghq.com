---
title: "Load balancing with AI gateway [WIP]"
layout: reference
content_type: reference
description: This guide provides an overview of load balancing and reatry and fallback strategies in AI Proxy Advanced plugin.

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
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
  - text: "{{site.base_gateway}} load balancing"
    url: /gateway/load-balancing/
  - text: "{{site.base_gateway}} round-robin load balancing"
    url: /gateway/entities/upstream/#round-robin
  - text: "{{site.base_gateway}} round-robin load balancing"
    url: /gateway/entities/upstream/#consistent-hashing
  - text: "{{site.base_gateway}} least connections load balancing"
    url: /gateway/entities/upstream/#least-connections
  - text: "{{site.base_gateway}} latency load balancing"
    url: /gateway/entities/upstream/#latency

---

## Load balancing in AI Gateway

Kong AI Gateway provides advanced load balancing capabilities to efficiently distribute requests across multiple LLM models. It ensures fault tolerance, efficient resource utilization, and load distribution across AI models

The AI Proxy Advanced plugin supports several load balancing algorithms, similar to those used for Kong upstreams, and extends them for AI model routing. Kong AI Gateway uses the [Upstream entity](/gateway/entities/upstream/) to configure load balancing, offering multiple algorithm options to fine-tune traffic distribution to various AI Providers and LLM models.


### Load balancing strategies

Kong AI Gateway supports multiple load balancing strategies to optimize traffic distribution across AI models. Each algorithm is suited for different performance goals such as balancing load, improving cache-hit ratios, reducing latency, or ensuring [failover reliability](#retry-and-fallback).

The table below provides a detailed overview of the available algorithms, along with considerations to keep in mind when selecting the best option for your use case.

<!--vale off-->
{% table %}
columns:
  - title: Strategy
    key: strategy
  - title: Description
    key: description
  - title: Considerations
    key: considerations
rows:
  - strategy: "[Round-robin (weighted)](/plugins/ai-proxy-advanced/examples/round-robin/)"
    description: |
      Distributes requests across models in a circular pattern with weight-based allocation. The [`weight`](/plugins/ai-proxy-advanced/reference/#schema--config-targets-weight) parameter (e.g., `weight: 70`) controls the proportion of traffic sent to each model.
    considerations: |
      * Traffic is routed proportionally based on weights.
      * Requests follow a sequence adjusted by weight.
      * Focuses purely on traffic distribution, not cache-hit ratios.
  - strategy: "[Consistent-hashing](/plugins/ai-proxy-advanced/examples/consistent-hashing/)"
    description: |
      Routes requests based on a hash of a configurable client input, such as a header or user ID. The [`hash_on_header`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-hash-on-header) setting (e.g., `X-Hashing-Header`) defines the source for the hash and drives all routing decisions.
    considerations: |
      * Especially effective with consistent keys like user IDs.
      * Requires diverse hash inputs for balanced distribution.
      * Ideal for maintaining session persistence.
  - strategy: "[Lowest-usage](/plugins/ai-proxy-advanced/examples/lowest-usage/)"
    description: |
      Routes requests to the least-utilized models based on resource usage metrics. In the configuration, the [`tokens_count_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-tokens-count-strategy) (e.g., `prompt-tokens`) defines how usage is measured, focusing on prompt tokens or other resource indicators.
    considerations: |
      * Dynamically balances load based on measured usage.
      * Useful for optimizing cost and avoiding overloading heavier models.
      * Ensures more efficient resource allocation across available models.
  - strategy: "[Lowest-latency](/plugins/ai-proxy-advanced/examples/lowest-latency/)"
    description: |
      Routes requests to the models with the lowest observed latency. In the configuration, the [`latency_strategy`](/plugins/ai-proxy-advanced/reference/#schema--config-balancer-latency-strategy) parameter (e.g., `latency_strategy: e2e`) defines how latency is measured, typically based on end-to-end response times.
    considerations: |
      * Prioritizes models with the fastest response times.
      * Optimizes for real-time performance in time-sensitive applications.
      * Less suitable for long-lived or persistent connections (e.g., WebSockets).
  - strategy: "[Semantic](/plugins/ai-proxy-advanced/examples/semantic/)"
    description: |
      Routes requests based on semantic similarity between the prompt and model descriptions. In the configuration, embeddings are generated using a specified model (e.g., `text-embedding-3-small`), and similarity is calculated using vector search.
    considerations: |
      * Uses vector search (e.g., Redis) to find the best match based on prompt embeddings.
      * `distance_metric` and `threshold` settings fine-tune matching sensitivity.
      * Best for routing prompts to domain-specialized models, like coding, analytics, text generation.
  - strategy: "[Priority](/plugins/ai-proxy-advanced/examples/priority/)"
    description: |
      Routes requests to models based on assigned priority groups and weights. In the configuration, models are grouped by priority and can have individual [`weight`](/plugins/ai-proxy-advanced/reference/#schema--config-targets-weight) settings (e.g., `weight: 70` for GPT-4), allowing proportional load distribution within each priority tier.
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

{% mermaid %}
sequenceDiagram
    participant Client
    participant AI Gateway
    participant Provider1 as AI Provider 1
    participant Provider2 as AI Provider 2 (fallback)

    %% Step 1
    Client ->> AI Gateway: (1) Send request

    %% Step 2
    AI Gateway ->> Provider1: (2) Select target & forward request

    %% Step 3
    alt AI Provider 1 success
        Provider1 -->> AI Gateway: 2xx Response
    else AI Provider 1 failure
        AI Gateway ->> Provider1: Retry (3a) (if allowed)
        alt Retry success
            Provider1 -->> AI Gateway: 2xx Response
        else Retry failure
            AI Gateway ->> Provider2: Fallback to another AI provider (3b)
            alt AI Provider 2 success
                Provider2 -->> AI Gateway: 2xx Response
            else AI Provider 2 failure
                AI Gateway -->> Client: (4) Return failure
            end
        end
    end

    %% Final response
    AI Gateway -->> Client: 2xx Response (on success)
{% endmermaid %}

#### Retry and fallback configuration

The AI Gateway load balancer offers several configuration options to fine-tune request retries, timeouts, and failover behavior.

The table below summarizes the key configuration parameters available:

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: "`retries`"
    description: |
      Defines how many times to retry a failed request before reporting failure to the client.
      Increase for better resilience to transient errors; decrease if you need lower latency and faster failure.
  - setting: "`failover_criteria`"
    description: |
      Specifies which types of failures (e.g., `http_429`, `http_500`) should trigger a failover to a different target.
      Customize based on your tolerance for specific errors and desired failover behavior.
  - setting: "`connect_timeout`"
    description: |
      Sets the maximum time allowed to establish a TCP connection with a target.
      Lower it for faster detection of unreachable servers; raise it if some servers may respond slowly under load.
  - setting: "`read_timeout`"
    description: |
      Defines the maximum time to wait for a server response after sending a request.
      Lower it for real-time applications needing quick responses; increase it for long-running operations.
  - setting: "`write_timeout`"
    description: |
      Sets the maximum time allowed to send the request payload to the server.
      Increase if large request bodies are common; keep short for small, fast payloads.
{% endtable %}
<!--vale on-->

#### Retry and fallback scenarios

The AI Gateway load balancer can be customized to fit different application needs, such as minimizing latency, enabling sticky sessions, or optimizing for cost. The table below maps common scenarios to key configuration options that control load balancing behavior:

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
    action: "Adjust `connect_timeout`, `read_timeout`, `write_timeout`"
    description: |
      Shorten these timeouts to quickly fail if a server is slow or unresponsive, ensuring faster error handling and responsiveness.
  - scenario: "Prioritize the lowest-latency target"
    action: "Set `latency_strategy` to `e2e`"
    description: |
      Optimize routing based on full end-to-end response time, selecting the target that minimizes total latency.
  - scenario: "Need predictable fallback for the same user"
    action: "Use `hash_on_header`"
    description: |
      Ensure that the same user consistently routes to the same target, enabling sticky sessions and reliable fallback behavior.
  - scenario: "Models have different costs"
    action: "Set `tokens_count_strategy` to `cost`"
    description: |
      Route requests intelligently by considering cost, balancing model performance with budget optimization.
{% endtable %}
<!--vale on-->

#### Version compatibility for fallbacks

{:.info}
> **{{site.base_gateway}} version compatibility for fallbacks:**
> {% new_in 3.10 %}
> - Full fallback support across targets, even with different API formats.
> - Mix models from different providers if needed (e.g., OpenAI and Mistral).
>
> Pre-v3.10:
> - Fallbacks only allowed between targets using the same API format.
> - Example: OpenAI-to-OpenAI fallback is supported; OpenAI-to-OLLAMA is not.