---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI Rate Limiting Advanced Policy provides rate limiting for any AI Policies. The
AI Rate Limiting Advanced Policy extends the
[Rate Limiting Advanced](/ai-gateway/policies/rate-limiting-advanced/) Policy.

This Policy uses the token data returned by the LLM provider to calculate the costs of queries.
The same HTTP request can vary greatly in cost depending on the calculation of the
LLM providers.

A common pattern to protect your AI API is to analyze and assign costs to incoming queries, then rate limit the consumer's
cost for a given time window and provider or policy.
You can also create a generic prompt rate limit using the [request prompt provider](#request-prompt-function).

Kong also provides multiple specialized rate limiting Policies, including rate limiting for service protection and on GraphQL queries.
See [Rate Limiting in {{site.base_gateway}}](/gateway/rate-limiting/) to choose the AI Policy that is most useful in your use case.

## Strategies

{% include md/ai-gateway/v2/rate-limiting-strategies.md name="AI Rate Limiting Advanced" %}

### Using cloud authentication with Redis

{% include md/ai-gateway/v2/redis-cloud-auth.md %}

{% include md/ai-gateway/v2/redis-cloud-auth-tabs.md %}

### Fallback from Redis

{% include md/ai-gateway/v2/redis-fallback.md %}

## Policy-based rate limiting

The [`config.policies`](./reference/#schema--config-policies) field allows you to define rate limiting at the [AI Consumer](./examples/consumer-rate-limiting), [AI Consumer Group](./examples/consumer-group-rate-limiting), [IP address](./examples/ip-rate-limiting), [header](./examples/header-rate-limiting), [path](./examples/path-rate-limiting), [model](./examples/llm-model-rate-limiting), and [provider](./examples/llm-provider-policy-based-rate-limiting) level. The match conditions under [`config.policies.match`](./reference/#schema--config-policies-match) use an `AND` logic, so you can combine these to set up [multi-dimensional rate limiting](./examples/rate-limiting-multiple-conditions). For example, you can set different rate limiting policies for a specific Consumer and model:

{% entity_example %}
type: policy
data:
  name: ai-rate-limiting-advanced
  config:
    policies:
    - match:
      - type: consumer
        key: id
        values:
          - $CONSUMER_ID
      - type: model
        partition_by: true
        values:
        - gpt-4o
      limits:
        - limit: 100
          window_size: 60
        - limit: 1000
          window_size: 3600
formats:
  - konnect-api
{% endentity_example %}

In this example, the limits will apply only to requests made by the specified AI Consumer to the `gpt-4o` model.

Policies without match conditions act as fallback and match all requests.

{:.warning}
> When defining rate limits for a specific model, these limits apply to the **requested** model. If a request is redirected to a different model after a failover, the request may succeed even if the final model has reached its limit.

### Known issues

* When defining a policy matching a model and/or a provider, you must set the [`config.policies.match.partition_by`](./reference/#schema--config-policies-match-partition-by) field to `true`, otherwise the policy is not enforced.


## Headers sent to the client

When the AI Rate Limiting Advanced Policy is enabled, {{site.ai_gateway}} sends some additional headers back to the client,
indicating the allowed limits, how many requests are available, and how long it will take
until the quota is restored. It also sends the limits in the time frame and the number
of remaining minutes for each provider or policy.

For example:

```plaintext
X-AI-RateLimit-Reset: 51
X-AI-RateLimit-Retry-After: 51
X-AI-RateLimit-Limit-90-policy-1: 20
X-AI-RateLimit-Remaining-90-policy-1: 0
```

You can optionally hide the limit and remaining headers with the [`config.hide_client_headers`](./reference/#schema--config-hide-client-headers) option.

If more than one limit is set, the AI Rate Limiting Advanced Policy returns multiple time limit headers.
For example:

```plaintext
X-AI-RateLimit-Limit-30-azure: 1000
X-AI-RateLimit-Remaining-30-azure: 950
X-AI-RateLimit-Limit-40-cohere: 2000
X-AI-RateLimit-Remaining-40-cohere: 1150
```

If any of the limits are reached, the AI Rate Limiting Advanced Policy returns an `HTTP/1.1 429` status
code to the client with the following JSON body:

```json
{ "message": "API rate limit exceeded for provider azure, cohere" }
```

For each provider or policy, the AI Rate Limiting Advanced Policy also indicates how long it will take until the quota is restored:

```plaintext
X-AI-RateLimit-Retry-After-30-azure: 1500
X-AI-RateLimit-Reset-30-azure: 1500
```

If using the request prompt provider, the AI Rate Limiting Advanced Policy will send the query cost:

```plaintext
X-AI-RateLimit-Query-Cost: 100
```

The `Retry-After` headers will be present on `429` errors to indicate how long the service is
expected to be unavailable to the client. When using `window_type=sliding` and `RateLimit-Reset`, `Retry-After`
may increase due to the rate calculation for the sliding window.

{:.warning}
> The headers `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` are based on the Internet-Draft [RateLimit Header Fields for HTTP](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers) and may change in the future to respect specification updates.

## Token count strategies

The AI Rate Limiting Advanced Policy supports three strategies to calculate the number of tokens. Configure the strategy with [`tokens_count_strategy`](./reference/#schema--config-tokens-count-strategy).

{% table %}
columns:
  - title: Strategy
    key: strategy
  - title: Description
    key: description
rows:
  - strategy: "`total_tokens`"
    description: The total number of tokens in the request, including both prompt and completion tokens.
  - strategy: "`prompt_tokens`"
    description: The tokens provided as input to the LLM.
  - strategy: "`completion_tokens`"
    description: The tokens generated by the LLM in response to the prompt.
  - strategy: "`cost`"
    description: |
      The financial or computational cost incurred based on token usage. This strategy lets you limit API usage based on actual processing costs rather than raw token counts.
      <br><br>
      The AI Rate Limiting Advanced Policy calculates cost as the sum of prompt tokens multiplied by input cost and completion tokens multiplied by output cost, divided by 1 million: `cost = (prompt_tokens × input_cost + completion_tokens × output_cost) / 1,000,000`.
      <br><br>
      You define `input_cost` and `output_cost` per 1 million tokens in whatever unit suits your use case, whether US dollars, cents, or internal billing credits. The rate limit threshold must use the same unit.
      <br><br>

      {:.warning}
      > This strategy requires `input_cost` and `output_cost` values in the [AI Model](/ai-gateway/entities/ai-model/) target configuration, under `config`.
{% endtable %}

### Request prompt function

You can decide to use a custom function to count the tokens for a requests.
To configure it, specify the function in [`config.request_prompt_count_function`](./reference/#schema--config-request-prompt-count-function).

When using the request prompt provider, it will call the function to get the token count at the request level and implement a limit.

See the following [example configuration](./examples/request-prompt-count-function/) for more detail.

## Known limitations of AI Rate Limiting Advanced

The cost is only reflected during the next request.

For example, if a request is made and returns a token cost of `100` for the `OpenAI` provider:
* The request is made to the OpenAI provider and the response is returned to the user
* If the rate limit is reached, the next request will be blocked

Additionally, [`config.disable_penalty`](./reference/#schema--config-disable-penalty) only works for the `requestPrompt` function.
