This section applies to legacy {{site.base_gateway}} 3.x plugin-based configurations. The following table describes the available algorithms and considerations for selecting one.

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
