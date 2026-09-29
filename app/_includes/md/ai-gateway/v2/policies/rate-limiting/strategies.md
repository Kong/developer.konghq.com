The Rate Limiting Policy supports two rate limiting strategies: `local` and `redis`.
This is controlled by the [`config.policy`](./reference/#schema--config-policy) parameter.

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
    pros: Accurate<sup>1</sup>, shared across all nodes.
    cons: Needs a Redis installation. Bigger performance impact than a `local` strategy.
{% endtable %}

{:.info}
> **\[1\]**: Only when the [`config.sync_rate`](./reference/#schema--config-sync-rate) option is set to `-1` (synchronous behavior).

Two common use cases for rate limiting are:

1. [_Every transaction counts_](#every-transaction-counts): The highest level of accuracy is needed. An example is a transaction with financial consequences.
2. [_Backend protection_](#backend-protection): Accuracy is not as relevant.
The requirement is only to protect backend services from overloading that's caused either by specific users or by attacks.

### Every transaction counts

In this scenario, because accuracy is important, the `local` strategy is not an option. Use `redis`.

If you use a very high sync frequency, `redis` is the only workable choice.
The sync frequency becomes higher when the `sync_rate` setting is a lower number. For example, a `sync_rate` of 0.1 is a much higher sync frequency (10 counter syncs per second) than a `sync_rate` of 1 (1 counter sync per second).

You can calculate what is considered a very high sync rate in your environment based on your topology, number of AI Policies, their sync rates, and tolerance for loose rate limits.

### Backend protection

If accuracy is less important, choose the `local` strategy.
You might need to experiment a little before you get a setting that works for your scenario.
As {{site.ai_gateway}} scales to more nodes, more user requests are handled.
When the number of nodes scales down, the probability of false negatives increases.
Make sure to adjust your rate limits when scaling.

For example, if a user can make 100 requests every second, and you have an equally balanced 5-node {{site.ai_gateway}} deployment, you can set the `local` limit to 30 requests every second.
If you see too many false negatives, increase the limit.

To minimize inaccuracies, consider using a consistent-hashing load balancer in front of {{site.ai_gateway}}.
The load balancer ensures that a user is always directed to the same {{site.ai_gateway}} node, which reduces inaccuracies and prevents scaling problems.
