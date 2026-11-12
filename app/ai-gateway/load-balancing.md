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
  - ai-gateway

tools:
  - admin-api
  - konnect-api

tags:
  - ai
  - load-balancing

min_version:
  ai-gateway: '2.0'

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
---

{{site.ai_gateway}} provides load balancing capabilities to distribute requests across multiple LLM models. You can use these features to improve fault tolerance, optimize resource utilization, and balance traffic across your AI systems.

In {{site.ai_gateway}}, load balancing is configured on the [AI Model entity](/ai-gateway/entities/ai-model/) through `config.balancer` and `targets`.

### Load balancing algorithms

{{site.ai_gateway}} supports multiple load balancing strategies for distributing traffic across AI models. Each algorithm addresses different goals: balancing load, improving cache-hit ratios, reducing latency, or providing [failover reliability](#retry-and-fallback).

The following table describes the available algorithms for [AI Model entities](/ai-gateway/entities/ai-model/) and considerations for selecting one.

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
      Routes requests based on a hash of a configurable header value. Requests with the same header value are routed to the same model, enabling sticky sessions for maintaining context across user interactions. The [`hash_on_header`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-hash-on-header) setting defines the header to hash. The default is `X-Kong-LLM-Request-ID`.
    considerations: |
      * Effective with consistent keys like user IDs.
      * Requires diverse hash inputs for balanced distribution.
      * Useful for session persistence and cache-hit optimization.
  - algorithm: "Least-connections"
    description: |
      Tracks the number of in-flight requests for each backend and routes new requests to the backend with the highest spare capacity. The [`weight`](/ai-gateway/entities/ai-model/#schema-aigateway-model-targets-weight) parameter is used to calculate connection capacity.
    considerations: |
      * Dynamically adapts to backend response times.
      * Routes away from slower backends as they accumulate open connections.
      * Does not account for cache-hit ratios.
  - algorithm: "Lowest-usage"
    description: |
      Routes requests to models with the lowest measured resource usage. The [`tokens_count_strategy`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-tokens-count-strategy) parameter defines how usage is measured: prompt tokens, completion tokens, total tokens (the default), cost, or an LLM-accuracy score.

      {:.warning}
      > **Warning**: If a target has no cost fields and the model has no price in the catalog, {{site.ai_gateway}} counts its cost as `0`.
      > With `lowest-usage` and `tokens_count_strategy: cost`, all traffic routes to any zero-priced model.
      > Configure cost fields on the target or add a price for the model in the [price catalog](/ai-cost-management/price-catalog) to avoid this.
      > <br><br>
      > If you don't configure any cost fields on a target, {{site.ai_gateway}} falls back to the [price catalog](/ai-cost-management/price-catalog).
      > <br><br>
      > When dynamic pricing is off (`KONG_DYNAMIC_PRICING=off`), you must configure [cost fields](/ai-gateway/model-cost-management/) directly on each target.
      > <br><br>
      > For the full precedence order, see [How a request is priced](/ai-cost-management/price-catalog/#how-a-request-is-priced).
    considerations: |
      * Balances load based on actual consumption metrics.
      * Useful for cost optimization and avoiding overloading individual models.
  - algorithm: "Lowest-latency"
    description: |
      Routes requests to the model with the lowest observed latency. The [`latency_strategy`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-latency-strategy) parameter defines how latency is measured. The default (`tpot`) uses time-per-output-token. The `e2e` option uses end-to-end response time.
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
      Routes requests to models based on assigned priority groups. The balancer always selects from the highest-priority group first. If all targets in that group are unavailable, it falls back to the next group. Within each group, the [`weight`](/ai-gateway/entities/ai-model/#schema-aigateway-model-targets-weight) parameter controls traffic distribution.
    considerations: |
      * Higher-priority groups receive all traffic until they fail.
      * Lower-priority groups serve as fallback only.
      * Useful for cost-aware routing and controlled failover.
{% endtable %}
<!--vale on-->

For examples of each algorithm, see [Algorithm examples](/ai-gateway/entities/ai-model/#algorithm-examples) in the [AI Model entity](/ai-gateway/entities/ai-model/) reference.

### Session affinity

Session affinity keeps a multi-turn conversation on the target that served its earlier turns.
The configured algorithm places the first turn of a conversation, and session affinity sends later turns to that same target as long as it can take them.
Session affinity requires {{site.ai_gateway}} 2.4 or later.

Configure session affinity in [`config.balancer.session_affinity`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-session-affinity) on the AI Model.
It works with every algorithm except `consistent-hashing`.

#### Why use session affinity

LLM providers cache the prompt prefix on the target that served it.
In a long conversation, such as one with a coding agent, each turn includes the full history again.
When a turn goes to a different target than the earlier turns, the provider reprocesses the whole history at full cost and latency instead of reusing its cached prefix.

Before session affinity, the only way to keep a conversation on one target was `consistent-hashing`.
That forced a choice between prompt-cache savings and your preferred strategy (round-robin, latency, cost, or priority).
It also depended on clients sending a stable header on every request, which most clients don't do.

Use session affinity when you want to balance new conversations by cost, latency, or priority, but keep each running conversation on one target.

Session affinity is a performance optimization, not a correctness feature.
If a turn goes to a different target, the conversation still works and you only lose the provider's cached prefix.

#### How a conversation is bound to a target

Clients don't need to send a session header or key.
{{site.ai_gateway}} identifies a conversation from what the client already sends:

1. If the request includes the provider's identifier for the previous response, {{site.ai_gateway}} uses it.
   This applies to `previous_response_id` in OpenAI Responses requests and the previous message ID in Anthropic Messages requests.
1. Otherwise, {{site.ai_gateway}} uses a fingerprint of the conversation history up to the latest assistant message.
   This applies to Chat Completions and compatible providers, which don't return a stable response ID.

The binding works as follows:

1. The configured algorithm selects a target for the first turn.
1. After a successful response, {{site.ai_gateway}} records which target served the conversation.
1. For each follow-up turn, {{site.ai_gateway}} sends the request to the recorded target if that target can take it.

Only a successful response updates the recorded target.
A failed final attempt doesn't change which target a conversation is bound to.

#### Failover and re-binding

If the recorded target can't take a follow-up request, the configured algorithm selects a new target.
A target can't take a request when it's unhealthy, over its rate limit, or no longer part of the AI Model.
After a successful response, {{site.ai_gateway}} binds the conversation to the new target.
Later turns go to the new target, and the client doesn't see an error.

Retries and failover follow the [retry and fallback](#retry-and-fallback) settings.
When a retry or failover ends on a different target, that target becomes the conversation's new target after a successful response.

#### Relationship to consistent hashing

`consistent-hashing` is an algorithm that routes by a hash of a header value you control, such as a user ID.
Session affinity is a layer on top of an algorithm that routes by conversation, so it doesn't need a header.
You can't combine the two.

We recommend session affinity when your goal is prompt-cache reuse within a conversation, because it works with any algorithm and without client changes.
Keep `consistent-hashing` when you need requests routed by an identity you choose, such as a user ID.

#### Storage and requirements

{{site.ai_gateway}} stores which target served each conversation.
Set `storage.type` based on how your data plane is deployed:

{% table %}
columns:
  - title: Storage
    key: storage
  - title: Choose it when
    key: when
  - title: Trade-offs
    key: tradeoffs
rows:
  - storage: "`local`"
    when: |
      You run a single data plane node, or you are evaluating the feature.
    tradeoffs: |
      The state is held in the memory of each node and isn't shared.
      If a follow-up turn is sent to a different node, that node doesn't have a record of the conversation, and the configured algorithm selects a target.
      Restarting a node clears its state.
  - storage: "`redis`"
    when: |
      You run more than one data plane node.
    tradeoffs: |
      The state is shared through a Datastore of type `redis-ee`, so affinity holds across all nodes.
      You need to provision and monitor Redis.
{% endtable %}

We recommend `redis` for any multi-node data plane because `local` storage only preserves affinity when consecutive turns reach the same node.

Use `ttl` to control how long {{site.ai_gateway}} remembers a conversation's target.
Memory use grows with the number of active conversations and the TTL.
{{site.ai_gateway}} stores a small record per turn, not the conversation history.

#### Limitations

* **Context compaction can break the link.** Clients such as coding agents sometimes compact or summarize the history.
  When a request includes a provider response ID, affinity continues to work after compaction.
  When {{site.ai_gateway}} relies on the history fingerprint alone, the compacted history no longer matches, and the configured algorithm selects the target.
* **Fallback to the configured algorithm.** If the state store is unavailable, or a conversation's entry expired or was evicted, the configured algorithm selects the target without returning an error.
  The cost is a provider prompt-cache miss.
* **Identical conversations.** {{site.ai_gateway}} identifies conversations by their content, so two clients that send identical message histories can be sent to the same target.
* **Single Datastore scope.** Affinity isn't shared across gateways.
  State is shared only among the data plane nodes that use the same Datastore.

<!-- TODO (observability): AI-186 lists affinity outcome (hit, miss, rebound), identity source, and provider cached-token counts per session in Konnect observability. Add the metric and span attribute names once engineering confirms them. -->

#### Configure session affinity

The following AI Model `config.balancer` fragment enables session affinity on the `lowest-latency` algorithm and shares state through Redis:

```yaml
config:
  balancer:
    algorithm: lowest-latency
    session_affinity:
      enabled: true
      ttl: 21600
      storage:
        type: redis
        datastore:
          name: shared-redis
```

### Request routing rules

Routing rules allow clients to send an alias instead of the actual model name in the request. This decouples the external model identifier from the internal provider model, enabling flexible routing without changing client code.

An AI Model can have an optional [`config.route.model`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-route-model) field, matching on the request body, a header, or the path. For example, when `config.route.model` is set to `{ body_param: model, values: [alias-value] }` and a client sends `"model": "alias-value"` in the request body, {{site.ai_gateway}} routes to the matching AI Model. This feature works independently of load balancing algorithms. The routing rule determines which AI Model (or target set) handles the request, and the configured load balancing algorithm selects the final backend within that set.

### Retry and fallback

The load balancer includes built-in support for retries and fallbacks. When a request fails, the balancer can automatically retry the same target or redirect the request to a different target model.

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
    LBLB -->|Request| AIProvider1(AI Model Provider 1)
    AIProvider1 --> Decision1{Is Success?}
    Decision1 -->|Yes| Client
    Decision1 -->|No| AIProvider2(AI Model Provider 2)
    subgraph Retry
        AIProvider2 --> Decision2{Is Success?}
    end
    Decision2 ------>|Yes| Client
{% endmermaid %}
<!-- vale on -->
> _Figure 1:_ A simplified diagram of fallback and retry processing in {{site.ai_gateway}}'s load balancer.

#### Retry and fallback configuration

The {{site.ai_gateway}} load balancer supports fine-grained control over failover behavior on the [Model entity](/ai-gateway/entities/ai-model/). Use [`failover_criteria`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-failover-criteria) to define when a request should retry on the next target model. By default, retries occur on `error` and `timeout`. An `error` means a failure occurred while connecting to the server, forwarding the request, or reading the response header. A `timeout` indicates that any of those stages exceeded the allowed time.

You can add more criteria to adjust retry behavior as needed:

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Description
    key: description
rows:
  - setting: "[`retries`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-retries)"
    description: |
      Defines how many times to retry a failed request before reporting failure to the client.
      Increase for better resilience to transient errors; decrease if you need lower latency and faster failure.
  - setting: "[`failover_criteria`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-failover-criteria)"
    description: |
      Specifies which types of failures (e.g., `http_429`, `http_500`) should trigger a failover to a different target.
      Customize based on your tolerance for specific errors and desired failover behavior.
  - setting: "[`connect_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-connect-timeout)"
    description: |
      Sets the maximum time allowed to establish a TCP connection with a target.
      Lower it for faster detection of unreachable servers; raise it if some servers may respond slowly under load.
  - setting: "[`read_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-read-timeout)"
    description: |
      Defines the maximum time to wait for a server response after sending a request.
      Lower it for real-time applications needing quick responses; increase it for long-running operations.
  - setting: "[`write_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-write-timeout)"
    description: |
      Sets the maximum time allowed to send the request payload to the server.
      Increase if large request bodies are common; keep short for small, fast payloads.
{% endtable %}
<!--vale on-->

#### Retry and fallback scenarios

You can customize the {{site.ai_gateway}} load balancer to fit different application needs, such as minimizing latency, enabling sticky sessions, or optimizing for cost. The following table maps common scenarios to key configuration options that control load balancing behavior:

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
    action: "Adjust [`connect_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-connect-timeout), [`read_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-read-timeout), [`write_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-write-timeout)"
    description: |
      Shorten these timeouts to quickly fail if a target model is slow or unresponsive, ensuring faster error handling and responsiveness.
  - scenario: "Prioritize the lowest-latency target"
    action: "Set [`latency_strategy`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-latency-strategy) to `e2e`"
    description: |
      Optimize routing based on full end-to-end response time, selecting the target that minimizes total latency.
  - scenario: "Need predictable fallback for the same user"
    action: "Use [`hash_on_header`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-hash-on-header)"
    description: |
      Ensure that the same user consistently routes to the same target model, enabling sticky sessions and reliable fallback behavior.
  - scenario: "Keep a conversation on one target without giving up your balancing algorithm"
    action: "Enable [`session_affinity`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-session-affinity)"
    description: |
      Route follow-up turns to the target that served earlier turns to benefit from provider prompt caching, regardless of the algorithm that places new conversations. See [Session affinity](#session-affinity).
  - scenario: "Models have different costs"
    action: "Set [`tokens_count_strategy`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-tokens-count-strategy) to `cost`"
    description: |
      Route requests by considering cost, balancing model performance with budget targets.
      Targets with no cost fields are priced from the [price catalog](/ai-cost-management/price-catalog/#how-a-request-is-priced).
{% endtable %}
<!--vale on-->

### Health check and circuit breaker

For AI Model entity, circuit breaker behavior is controlled through the balancer configuration on the AI Model. Use these settings to fail fast when a target model is unhealthy and to retry or fall back to another target instead of waiting for repeated slow responses.

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Use
    key: use
rows:
  - setting: "[`connect_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-connect-timeout), [`read_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-read-timeout), [`write_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-write-timeout)"
    use: "Reduce how long {{site.ai_gateway}} waits before treating a target model as unavailable."
  - setting: "[`max_fails`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-max-fails)"
    use: "Set the number of failed attempts allowed before {{site.ai_gateway}} marks a target model unhealthy."
  - setting: "[`fail_timeout`](/ai-gateway/entities/ai-model/#schema-aigateway-model-config-balancer-fail-timeout)"
    use: "Set how long {{site.ai_gateway}} keeps a target model in a failed state before trying it again."
{% endtable %}
<!--vale on-->

{% include md/ai-gateway/v2/circuit-breaker.md %}
