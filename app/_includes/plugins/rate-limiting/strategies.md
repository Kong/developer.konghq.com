{% if include.name == "Response Rate Limiting" %}
The {{include.name}} plugin supports three rate limiting strategies: `local`, `cluster`, and `redis`. 
This is controlled by the [`config.policy`](/plugins/rate-limiting/reference/#schema--config-policy) parameter.

| Strategy  | Description | Pros | Cons   |
| --------- |-------------| ---- | ------ |
| `local`   | Counters are stored in-memory on the node. | Minimal performance impact. | Less accurate. Unless there's a consistent-hashing load balancer in front of Kong, it diverges when scaling the number of nodes.
| `cluster` | Counters are stored in the {{site.base_gateway}} data store and shared across nodes. | Accurate, no extra components to support. | Each request forces a read and a write on the data store. Therefore, relatively, the biggest performance impact. <br>Not supported in hybrid mode or {{site.konnect_short_name}} deployments. |
| `redis`   | Counters are stored on a Redis server and shared across nodes. | Accurate, less performance impact than a `cluster` policy. | Needs a Redis installation. Bigger performance impact than a `local` policy. |

{% else %}

The {{include.name}} plugin supports three rate limiting strategies: `local`, `cluster`, and `redis`. 
{% if include.name == "Rate Limiting Advanced" %}
This is controlled by the [`config.strategy`](/plugins/rate-limiting-advanced/reference/#schema--config-strategy) parameter.
{% elsif include.name == "Rate Limiting" %}
This is controlled by the [`config.policy`](/plugins/rate-limiting/reference/#schema--config-policy) parameter.
{% endif %}

| Strategy  | Description | Pros | Cons   |
| --------- |-------------| ---- | ------ |
| `local`   | Counters are stored in-memory on the node. | Minimal performance impact. | Less accurate. Unless there's a consistent-hashing load balancer in front of Kong, it diverges when scaling the number of nodes.
| `cluster` | Counters are stored in the {{site.base_gateway}} data store and shared across nodes. | Accurate<sup>1</sup>, no extra components to support. | Each request forces a read and a write on the data store. Therefore, relatively, the biggest performance impact. <br>Not supported in hybrid mode or {{site.konnect_short_name}} deployments. |
| `redis`   | Counters are stored on a Redis server and shared across nodes. | Accurate<sup>1</sup>, less performance impact than a `cluster` policy. | Needs a Redis installation. Bigger performance impact than a `local` policy. |

{:.info}
> **\[1\]**: Only when [`config.sync_rate`](./reference/#schema--config-sync_rate) option is set to `0` (synchronous behavior). 

Two common use cases for rate limiting are:

1. [_Every transaction counts_](#every-transaction-counts): The highest level of accuracy is needed. An example is a transaction with financial consequences.
2. [_Backend protection_](#backend-protection): Accuracy is not as relevant.
The requirement is only to protect backend services from overloading that's caused either by specific users or by attacks.

### Every transaction counts

In this scenario, because accuracy is important, the `local` policy is not an option. 
Consider the support effort you might need for Redis, and then choose either `cluster` or `redis`.

You could start with the `cluster` policy, and move to `redis` if performance reduces drastically.

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
The load balancer ensures that a user is always directed to the same  {{site.base_gateway}} node, which reduces inaccuracies and prevents scaling problems.

{% endif %}