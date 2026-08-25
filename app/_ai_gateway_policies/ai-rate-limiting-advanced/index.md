---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: Model cost management
    url: /ai-gateway/model-cost-management/
---

The AI Rate Limiting Advanced Policy provides rate limiting for all [AI Policies](/ai-gateway/policies/). The
AI Rate Limiting Advanced Policy extends the
[Rate Limiting Advanced](/ai-gateway/policies/rate-limiting-advanced/) Policy.

This Policy uses the token data returned by the LLM provider to calculate the costs of queries.
The same HTTP request can vary greatly in cost depending on the calculation of the
LLM providers. See [Model cost management](/ai-gateway/model-cost-management/) for how {{site.ai_gateway}} prices a request.

A common pattern to protect your AI API is to analyze and assign costs to incoming queries, then rate limit the consumer's
cost for a given time window and provider or policy.
You can also create a generic prompt rate limit using the [request prompt provider](#request-prompt-function).

## Strategies

{% include md/ai-gateway/v2/rate-limiting-strategies.md name="AI Rate Limiting Advanced" %}

### Using cloud authentication with Redis

{% include_cached md/ai-gateway/v2/redis-cloud-auth.md tier=page.tier %}

{% include_cached md/ai-gateway/v2/redis-cloud-providers.md name=page.name heading_level=3 %}

### Fallback from Redis

{% include md/ai-gateway/v2/redis-fallback.md %}

## Policy-based rate limiting

The [`config.policies`](./reference/#schema--config-policies) field allows you to define rate limiting at the AI Consumer, AI Consumer Group, IP address, header, path, model, and provider level. The match conditions under [`config.policies.match`](./reference/#schema--config-policies-match) use an `AND` logic, so you can combine these to set up multi-dimensional rate limiting. For example, you can set different rate limiting policies for a specific Consumer and model:

{% entity_example %}
type: policy
data:
  display_name: AI Rate Limiting Advanced - Consumer and Model
  type: ai-rate-limiting-advanced
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
  - kongctl
  - konnect-api
{% endentity_example %}

In this example, the limits will apply only to requests made by the specified AI Consumer to the `gpt-4o` model.

Policies without match conditions act as fallback and match all requests.

{:.warning}
> When defining rate limits for a specific model, these limits apply to the **requested** model. If a request is redirected to a different model after a failover, the request may succeed even if the final model has reached its limit.

### Window types

Each policy sets a [`window_type`](./reference/#schema--config-policies-window-type): `fixed`, `sliding`, or `calendar`.

* `sliding` (default): Weighs the current window against the previous one to produce a dynamically calculated rate.
* `fixed`: Assigns each request to a single time bucket based on its timestamp.
* `calendar`: Aligns the window to a real calendar boundary in a specific time zone, instead of a rolling `window_size`.

#### Calendar windows

Calendar windows budget tokens against the same period your billing already uses, such as a monthly allowance that resets on the 1st, instead of a rolling window that drifts from the billing cycle.

Set `window_type: calendar` on the policy and [`timezone`](./reference/#schema--config-policies-timezone) to an IANA time zone, such as `America/New_York`. Each limit then sets a [`period`](./reference/#schema--config-policies-limits-period) instead of `window_size`:


{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`period`"
    description: "`month` or `week`."
  - field: "`month_day`"
    description: Required when `period` is `month`. This is the day of the month (1-31) that a monthly window starts.
  - field: "`week_start_day`"
    description: Day of the week a weekly window starts, such as `monday`. Only applies when `period` is `week`.
{% endtable %}

{% entity_example %}
type: policy
data:
  display_name: AI Rate Limiting Advanced - Calendar Window
  name: ai-rate-limiting-advanced
  type: ai-rate-limiting-advanced
  config:
    policies:
    - window_type: calendar
      timezone: America/New_York
      match:
      - type: consumer_group
        values:
        - premium
      limits:
        - limit: 2000000
          period: month
          month_day: 1
          tokens_count_strategy: total_tokens
formats:
  - kongctl
  - konnect-api
{% endentity_example %}

This policy grants the `premium` AI Consumer Group 2,000,000 tokens per calendar month, resetting at local midnight on the 1st in `America/New_York`.

{:.info}
> For calendar windows, `X-AI-RateLimit-Reset` and `X-AI-RateLimit-Retry-After` point to the next calendar boundary (the start of the next week or month in the configured time zone), not `now + window_size`.

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
      The AI Rate Limiting Advanced Policy limits against the same cost figure {{site.ai_gateway}} calculates for reporting. See [Model cost calculation](/ai-gateway/model-cost-management/#model-cost-calculation) for the full formula, including how cache pricing, context-window thresholds, and service tiers factor in.
      <br><br>
      You define pricing per 1 million tokens in whatever unit suits your use case, whether US dollars, cents, or internal billing credits. The rate limit threshold must use the same unit.
      <br><br>

      {:.warning}
      > This strategy requires `input_cost` and `output_cost` configured on the [AI Model](/ai-gateway/entities/ai-model/) target's `config`. See [Model cost configuration](/ai-gateway/model-cost-management/#model-cost-configuration) for these and the optional cache, context-window, and service-tier fields.
{% endtable %}

### Request prompt function

You can decide to use a custom function to count the tokens for a requests.
To configure it, specify the function in [`config.request_prompt_count_function`](./reference/#schema--config-request-prompt-count-function).

When using the request prompt provider, it will call the function to get the token count at the request level and implement a limit.

## Known limitations of AI Rate Limiting Advanced

The cost is only reflected during the next request.

For example, if a request is made and returns a token cost of `100` for the `OpenAI` provider:
* The request is made to the OpenAI provider and the response is returned to the user
* If the rate limit is reached, the next request will be blocked

Additionally, [`config.disable_penalty`](./reference/#schema--config-disable-penalty) only works for the `requestPrompt` function.
