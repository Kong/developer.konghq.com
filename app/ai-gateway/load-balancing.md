---
title: "Load balancing with {{site.ai_gateway_name}}"
layout: reference
content_type: reference
description: "This guide provides an overview of load balancing and retry and fallback strategies in {{site.ai_gateway}}."
breadcrumbs:
  - /ai-gateway/

works_on:
 - on-prem
 - konnect

products:
  - gateway
  - ai-gateway

tools:
  - admin-api
  - konnect-api

tags:
  - ai
  - load-balancing

min_version:
  ai-gateway: '2.0.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Model entity
    url: /ai-gateway/entities/ai-model/
---

{{site.ai_gateway}} provides load balancing capabilities to distribute requests across multiple LLM models. You can use these features to improve fault tolerance, optimize resource utilization, and balance traffic across your AI systems.

In {{site.ai_gateway}} 2.0.0 and later, load balancing is configured on the [Model entity](/ai-gateway/entities/ai-model/) through `config.balancer` and `target_models`.

<!-- Commented out for future reference - Compatibility with existing configurations
{:.info}
> With {{site.ai_gateway}} 2.0.0, both configuration approaches can appear in existing deployments:
> - Legacy plugin-based approach: configure load balancing directly on [AI Proxy Advanced](/plugins/ai-proxy-advanced/) plugin instances.
> - {{site.ai_gateway}} 2.0.0 approach: configure load balancing on the [Model entity](/ai-gateway/entities/model/) with `config.balancer` and `target_models`.
>
> For new {{site.ai_gateway}} deployments, use the Model entity workflow.
-->

### Request routing by model alias

Model aliases allow clients to send an alias instead of the actual model name in the request. This decouples the external model identifier from the internal provider model, enabling flexible routing without changing client code.

Each target in a Model entity can have an optional [`model.alias`](/ai-gateway/entities/ai-model/#schema-aigateway-model-target-models-model-alias) field. When a client sends `"model": "alias-value"` in the request body, {{site.ai_gateway}} routes to the matching target. This feature works independently of load balancing algorithms — the alias determines which target (or set of targets) handles the request, and the configured load balancing algorithm selects the final backend within that set.

### Load balancing algorithms

{{site.ai_gateway}} supports multiple load balancing strategies for distributing traffic across AI models. Each algorithm addresses different goals: balancing load, improving cache-hit ratios, reducing latency, or providing [failover reliability](#retry-and-fallback).

The following table describes the available algorithms for [Model entities](/ai-gateway/entities/model/) and considerations for selecting one.

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
  - algorithm: "Round-robin (weighted)"
    description: |
      Distributes requests across models based on their assigned weights. For example, if models `gpt-4`, `gpt-4o-mini`, and `gpt-3` have weights of `70`, `25`, and `5`, they receive approximately 70%, 25%, and 5% of traffic respectively. Requests are distributed proportionally, independent of usage or latency metrics.
    considerations: |
      * Traffic is routed proportionally based on weights.
      * Requests follow a circular sequence adjusted by weight.
      * Does not account for cache-hit ratios, latency, or current load.
  - algorithm: "Consistent-hashing"
    description: |
      Routes requests based on a hash of a configurable header value. Requests with the same header value are routed to the same model, enabling sticky sessions for maintaining context across user interactions. The [`hash_on_header`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-hash-on-header) setting defines the header to hash. The default is `X-Kong-LLM-Request-ID`.
    considerations: |
      * Effective with consistent keys like user IDs.
      * Requires diverse hash inputs for balanced distribution.
      * Useful for session persistence and cache-hit optimization.
  - algorithm: "Least-connections"
    description: |
      Tracks the number of in-flight requests for each backend and routes new requests to the backend with the highest spare capacity. The [`weight`](/ai-gateway/entities/model/#schema-aigateway-model-target-models-weight) parameter is used to calculate connection capacity.
    considerations: |
      * Dynamically adapts to backend response times.
      * Routes away from slower backends as they accumulate open connections.
      * Does not account for cache-hit ratios.
  - algorithm: "Lowest-usage"
    description: |
      Routes requests to models with the lowest measured resource usage. The [`tokens_count_strategy`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-tokens-count-strategy) parameter defines how usage is measured: prompt token counts, response token counts, or cost.
    considerations: |
      * Balances load based on actual consumption metrics.
      * Useful for cost optimization and avoiding overloading individual models.
  - algorithm: "Lowest-latency"
    description: |
      Routes requests to the model with the lowest observed latency. The [`latency_strategy`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-latency-strategy) parameter defines how latency is measured. The default (`tpot`) uses time-per-output-token. The `e2e` option uses end-to-end response time.
      <br><br>
      The algorithm uses peak EWMA (Exponentially Weighted Moving Average) to track latency from TCP connect through body response. Metrics decay over time.
    considerations: |
      * Prioritizes models with the fastest response times.
      * Suited for latency-sensitive applications.
      * Less suitable for long-lived connections like WebSockets.
  - algorithm: "Semantic"
    description: |
      Routes requests based on semantic similarity between the prompt and model descriptions. Embeddings are generated using a specified model (for example, `text-embedding-3-small`), and similarity is calculated using vector search.
      <br><br>
      Multiple targets can share identical descriptions. When they do, the balancer performs round-robin fallback among them if the primary target fails. Weights affect fallback order.
    considerations: |
      * Requires a vector database (for example, Redis) for similarity matching.
      * The `distance_metric` and `threshold` settings control matching sensitivity.
      * Best for routing prompts to domain-specialized models.
  - algorithm: "Priority"
    description: |
      Routes requests to models based on assigned priority groups. The balancer always selects from the highest-priority group first. If all targets in that group are unavailable, it falls back to the next group. Within each group, the [`weight`](/ai-gateway/entities/model/#schema-aigateway-model-target-models-weight) parameter controls traffic distribution.
    considerations: |
      * Higher-priority groups receive all traffic until they fail.
      * Lower-priority groups serve as fallback only.
      * Useful for cost-aware routing and controlled failover.
{% endtable %}
<!--vale on-->

For examples of each algorithm, see [Algorithm examples](/ai-gateway/entities/model/#algorithm-examples) in the [Model entity](/ai-gateway/entities/model/) reference.

### Retry and fallback

The load balancer includes built-in support for **retries** and **fallbacks**. When a request fails, the balancer can automatically retry the same target or redirect the request to a different target model.

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

The {{site.ai_gateway}} load balancer supports fine-grained control over failover behavior on the [Model entity](/ai-gateway/entities/model/). Use [`failover_criteria`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-failover-criteria) to define when a request should retry on the next target model. By default, retries occur on `error` and `timeout`. An `error` means a failure occurred while connecting to the server, forwarding the request, or reading the response header. A `timeout` indicates that any of those stages exceeded the allowed time.

You can add more criteria to adjust retry behavior as needed:

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: "[`retries`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-retries)"
    description: |
      Defines how many times to retry a failed request before reporting failure to the client.
      Increase for better resilience to transient errors; decrease if you need lower latency and faster failure.
  - setting: "[`failover_criteria`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-failover-criteria)"
    description: |
      Specifies which types of failures (e.g., `http_429`, `http_500`) should trigger a failover to a different target.
      Customize based on your tolerance for specific errors and desired failover behavior.
  - setting: "[`connect_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-connect-timeout)"
    description: |
      Sets the maximum time allowed to establish a TCP connection with a target.
      Lower it for faster detection of unreachable servers; raise it if some servers may respond slowly under load.
  - setting: "[`read_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-read-timeout)"
    description: |
      Defines the maximum time to wait for a server response after sending a request.
      Lower it for real-time applications needing quick responses; increase it for long-running operations.
  - setting: "[`write_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-write-timeout)"
    description: |
      Sets the maximum time allowed to send the request payload to the server.
      Increase if large request bodies are common; keep short for small, fast payloads.
{% endtable %}
<!--vale on-->

#### Retry and fallback scenarios

You can customize the {{site.ai_gateway}} load balancer to fit different application needs, such as minimizing latency, enabling sticky sessions, or optimizing for cost. The table below maps common scenarios to key configuration options that control load balancing behavior:

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
    action: "Adjust [`connect_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-connect-timeout), [`read_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-read-timeout), [`write_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-write-timeout)"
    description: |
      Shorten these timeouts to quickly fail if a target model is slow or unresponsive, ensuring faster error handling and responsiveness.
  - scenario: "Prioritize the lowest-latency target"
    action: "Set [`latency_strategy`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-latency-strategy) to `e2e`"
    description: |
      Optimize routing based on full end-to-end response time, selecting the target that minimizes total latency.
  - scenario: "Need predictable fallback for the same user"
    action: "Use [`hash_on_header`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-hash-on-header)"
    description: |
      Ensure that the same user consistently routes to the same target model, enabling sticky sessions and reliable fallback behavior.
  - scenario: "Models have different costs"
    action: "Set [`tokens_count_strategy`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-tokens-count-strategy) to `cost`"
    description: |
      Route requests by considering cost, balancing model performance with budget targets.
{% endtable %}
<!--vale on-->

#### Version compatibility for fallbacks

{:.info}
> **{{site.base_gateway}} version compatibility for fallbacks:**
> {% new_in 3.10 %}
> - Full fallback support across targets, even with different API formats.
> - Mix models from different providers if needed (for example, OpenAI and {{ site.mistral }}).
>
> Pre-3.10:
> - Fallbacks only allowed between targets using the same API format.
> - Example: OpenAI-to-OpenAI fallback is supported; OpenAI-to-OLLAMA is not.

### Health check and circuit breaker

For Model entities, circuit breaker behavior is controlled through the balancer configuration on the Model. Use these settings to fail fast when a target model is unhealthy and to retry or fall back to another target instead of waiting for repeated slow responses.

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Use
    key: use
rows:
  - setting: "[`connect_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-connect-timeout), [`read_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-read-timeout), [`write_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-write-timeout)"
    use: "Reduce how long {{site.base_gateway}} waits before treating a target model as unavailable."
  - setting: "[`max_fails`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-max-fails)"
    use: "Set the number of failed attempts allowed before {{site.base_gateway}} marks a target model unhealthy."
  - setting: "[`fail_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-fail-timeout)"
    use: "Set how long {{site.base_gateway}} keeps a target model in a failed state before trying it again."
{% endtable %}
<!--vale on-->

The load balancer supports health checks and circuit breakers to improve reliability. If the number of unsuccessful attempts to a target reaches [`config.balancer.max_fails`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-max-fails), the load balancer stops sending requests to that target until it reconsiders the target after the period defined by [`config.balancer.fail_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-fail-timeout). The diagram below illustrates this behavior:

![Circuit breaker](/assets/images/ai-gateway/circuit-breaker.jpg){: style="display:block; margin-left:auto; margin-right:auto; width:50%; border-radius:10px" }

Consider an example where [`config.balancer.max_fails`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-max-fails) is 3 and [`config.balancer.fail_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-fail-timeout) is 10 seconds. When failed requests for a target reach 3, the target is marked unhealthy and the load balancer stops sending requests to it. After 10 seconds, the target is reconsidered. If the request to this target still fails, the target remains unhealthy and the load balancer continues to exclude it. If the request succeeds, the target is marked healthy again and recovers from the circuit breaker.

The failure counter tracks total failures, not consecutive failures. If a target receives 2 failed requests, then 1 successful request within the timeout window, the counter remains at 2. The counter resets only when a successful request occurs after [`config.balancer.fail_timeout`](/ai-gateway/entities/model/#schema-aigateway-model-config-balancer-fail-timeout) has elapsed since the last failed request.

If all targets become unhealthy simultaneously, requests fail with `HTTP 500`.
