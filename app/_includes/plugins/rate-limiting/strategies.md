{% if include.name == "Response Rate Limiting" %}
The {{include.name}} plugin supports three rate limiting strategies: `local`, `cluster`, and `redis`. 
This is controlled by the [`config.policy`](/plugins/rate-limiting/reference/#schema--config-policy) parameter.

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
    cons: Less accurate. Unless there's a consistent-hashing load balancer in front of Kong, it diverges when scaling the number of nodes.
  - strategy: "`cluster`"
    description: Counters are stored in the {{site.base_gateway}} data store and shared across nodes.
    pros: Accurate, no extra components to support.
    cons: Each request forces a read and a write on the data store. Therefore, relatively, the biggest performance impact. <br>Not supported in hybrid mode or {{site.konnect_short_name}} deployments.
  - strategy: "`redis`"
    description: Counters are stored on a Redis server and shared across nodes.
    pros: Accurate, less performance impact than a `cluster` policy.
    cons: Needs a Redis installation. Bigger performance impact than a `local` policy.
{% endtable %}
{% else %}

The {{include.name}} plugin supports three rate limiting strategies: `local`, `cluster`, and `redis`. 
{% if include.name == "Rate Limiting Advanced" %}
This is controlled by the [`config.strategy`](/plugins/rate-limiting-advanced/reference/#schema--config-strategy) parameter.
{% elsif include.name == "Rate Limiting" %}
This is controlled by the [`config.policy`](/plugins/rate-limiting/reference/#schema--config-policy) parameter.
{% endif %}

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
    cons: Less accurate. Unless there's a consistent-hashing load balancer in front of {{site.base_gateway}}, it diverges when scaling the number of nodes.
  - strategy: "`cluster`" 
    description: Counters are stored in the {{site.base_gateway}} data store and shared across nodes.
    pros: Accurate<sup>1</sup>, no extra components to support.
    cons: Each request forces a read and a write on the data store. Therefore, relatively, the biggest performance impact. <br>Not supported in hybrid mode or {{site.konnect_short_name}} deployments.
  - strategy: "`redis`"
    description: Counters are stored on a Redis server and shared across nodes.
    pros: Accurate<sup>1</sup>, less performance impact than a `cluster` policy.
    cons: Needs a Redis installation. Bigger performance impact than a `local` policy.
{% endtable %}

{:.info}
> **\[1\]**: Only when [`config.sync_rate`](./reference/#schema--config-sync-rate) option is set to `0` (synchronous behavior). 

Two common use cases for rate limiting are:

1. [_Every transaction counts_](#every-transaction-counts): The highest level of accuracy is needed. An example is a transaction with financial consequences.
2. [_Backend protection_](#backend-protection): Accuracy is not as relevant.
The requirement is only to protect backend services from overloading that's caused either by specific users or by attacks.

### Every transaction counts

In this scenario, because accuracy is important, the `local` policy is not an option. 
Consider the support effort you might need for Redis, and then choose either `cluster` or `redis`.

You could start with the `cluster` policy, and move to `redis` if performance reduces drastically.

If using a very high sync frequency, use `redis`. Very high sync frequencies with `cluster` mode are **not scalable and not recommended**. 
The sync frequency becomes higher when the `sync_rate` setting is a lower number - for example, a `sync_rate` of 0.1 is a much higher sync frequency (10 counter syncs per second) than a `sync_rate` of 1 (1 counter sync per second).

You can calculate what is considered a very high sync rate in your environment based on your topology, number of plugins, their sync rates, and tolerance for loose rate limits.

{% if include.name contains "Rate Limiting Advanced" %}
Together, the interaction between sync rate and window size affects how accurately the plugin can determine cluster-wide traffic.
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
  - property: "Max potential lag in cluster count for a given node/s"
    formula_or_config: "Estimated load balanced RPS * Sync rate"
    value: "20 * 0.5 = 10"
  - property: "Cluster-wide max potential overage/s"
    formula_or_config: "Max potential lag * Number of nodes"
    value: "10 * 10 = 100"
  - property: "Cluster-wide max potential overage/s as a percentage"
    formula_or_config: "Cluster-wide max potential overage / Limit"
    value: "100 / 1000 = 10%"
  - property: "Effective worst case cluster-wide requests allowed at window size"
    formula_or_config: "Limit * Cluster-wide max potential overage"
    value: "1000 + 100 = 1100"
{% endtable %}
<!--vale on-->

{% endif %}

If you choose to switch strategies, note that you can't port the existing usage metrics from the {{site.base_gateway}} data store to Redis.
This might not be a problem with short-lived metrics (for example, seconds or minutes)
but if you use metrics with a longer time frame (for example, months), plan your switch carefully.

### Backend protection

If accuracy is less important, choose the `local` policy. 
You might need to experiment a little before you get a setting that works for your scenario. 
As the cluster scales to more nodes, more user requests are handled.
When the cluster scales down, the probability of false negatives increases. 
Make sure to adjust your rate limits when scaling.

For example, if a user can make 100 requests every second, and you have an equally balanced 5-node {{site.base_gateway}} cluster, you can set the `local` limit to 30 requests every second. 
If you see too many false negatives, increase the limit.

To minimize inaccuracies, consider using a [consistent-hashing load balancer](/gateway/entities/upstream/#consistent-hashing) in front of {{site.base_gateway}}. 
The load balancer ensures that a user is always directed to the same {{site.base_gateway}} node, which reduces inaccuracies and prevents scaling problems.

{% endif %}