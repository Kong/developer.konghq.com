The AI Rate Limiting Advanced Policy supports two rate limiting strategies: `local` and `redis`.
This is controlled by the [`config.strategy`](./reference/#schema--config-strategy) parameter.

{% table %}
columns:
  - title: Strategy
    key: strategy
  - title: Description
    key: description
  - title: Pros
    key: pros
  - title: Cons
    key: cons
rows:
  - strategy: "`local`"
    description: Counters are stored in-memory on the node.
    pros: Minimal performance impact.
    cons: Less accurate. Unless there's a consistent-hashing load balancer in front of {{site.ai_gateway}}, it diverges when scaling the number of nodes.
  - strategy: "`redis`"
    description: Counters are stored on a Redis server and shared across nodes.
    pros: Accurate<sup>1</sup>, and works consistently across all {{site.ai_gateway}} nodes.
    cons: Needs a Redis installation. Bigger performance impact than a `local` strategy.
{% endtable %}

{:.info}
> **\[1\]**: Only when [`config.sync_rate`](./reference/#schema--config-sync-rate) option is set to `0` (synchronous behavior).

Two common use cases for rate limiting are:

1. [_Every transaction counts_](#every-transaction-counts): The highest level of accuracy is needed. An example is a transaction with financial consequences.
2. [_Backend protection_](#backend-protection): Accuracy is not as relevant.
The requirement is only to protect backend services from overloading that's caused either by specific users or by attacks.

### Every transaction counts

In this scenario, because accuracy is important, the `local` strategy is not an option. Use the `redis` strategy instead.

If using a very high sync frequency, be aware that this can affect performance at scale.
The sync frequency becomes higher when the `sync_rate` setting is a lower number - for example, a `sync_rate` of 0.1 is a much higher sync frequency (10 counter syncs per second) than a `sync_rate` of 1 (1 counter sync per second).

You can calculate what is considered a very high sync rate in your environment based on your topology, number of Policies, their sync rates, and tolerance for loose rate limits.

Together, the interaction between sync rate and window size affects how accurately the AI Rate Limiting Advanced Policy can determine traffic across all nodes.
For example, the following table represents the worst-case scenario where a full sync interval's worth of data hasn't yet propagated across nodes:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Formula or config location
    key: formula_or_config
  - title: Value
    key: value
rows:
  - property: "Window size in seconds"
    formula_or_config: "Value set in `config.window_size`"
    value: "5"
  - property: "Limit (in window)"
    formula_or_config: "Value set in `config.limit`"
    value: "1000"
  - property: "Sync rate (interval)"
    formula_or_config: "Value set in `config.sync_rate`"
    value: "0.5"
  - property: "Number of nodes (>1)"
    formula_or_config: "--"
    value: "10"
  - property: "Estimated load balanced requests-per-second (RPS) to a node"
    formula_or_config: "Limit / Window size / Number of nodes"
    value: "1000 / 5 / 10 = 20"
  - property: "Max potential lag in count for a given node/s"
    formula_or_config: "Estimated load balanced RPS * Sync rate"
    value: "20 * 0.5 = 10"
  - property: "Max potential overage/s across all nodes"
    formula_or_config: "Max potential lag * Number of nodes"
    value: "10 * 10 = 100"
  - property: "Max potential overage/s across all nodes as a percentage"
    formula_or_config: "Max potential overage / Limit"
    value: "100 / 1000 = 10%"
  - property: "Effective worst case number of requests allowed at window size"
    formula_or_config: "Limit * Max potential overage"
    value: "1000 + 100 = 1100"
{% endtable %}
<!--vale on-->

### Backend protection

If accuracy is less important, choose the `local` strategy.
You might need to experiment a little before you get a setting that works for your scenario.
As {{site.ai_gateway}} scales to more nodes, more user requests are handled.
When the number of nodes scales down, the probability of false negatives increases.
Make sure to adjust your rate limits when scaling.

For example, if a user can make 100 requests every second, and you have an equally balanced 5-node {{site.ai_gateway}} deployment, you can set the `local` limit to 30 requests every second.
If you see too many false negatives, increase the limit.

To minimize inaccuracies, consider using a [consistent-hashing load balancer](/gateway/entities/upstream/#consistent-hashing) in front of {{site.ai_gateway}}.
The load balancer ensures that a user is always directed to the same {{site.ai_gateway}} node, which reduces inaccuracies and prevents scaling problems.
