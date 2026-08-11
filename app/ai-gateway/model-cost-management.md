---
title: "Model cost management in {{site.ai_gateway_name}}"
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

breadcrumbs:
  - /ai-gateway/

tags:
  - ai
  - governance
  - metering
  - rate-limiting

min_version:
  ai-gateway: '2.0'

description: "How {{site.ai_gateway}} prices models and calculates the cost of a request."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Rate Limiting Advanced policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
---

Cost is one of the primary signals AI governance acts on: budget enforcement, per-consumer spend limits, and chargeback all depend on an accurate cost figure for each request. {{site.ai_gateway}} calculates that figure for every request to a large language model (LLM) provider, matching what the provider actually bills. It feeds cost reporting and any policy that enforces spend against it, such as [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/).

This page explains how that cost figure feeds governance and reporting, and the pricing configuration behind it, so you can confirm your governance policies are enforcing against a number that reflects real provider spend.

## Model pricing dimensions

{{site.ai_gateway}} prices a request starting from a base two-rate calculation (an input rate times input tokens, plus an output rate times output tokens), then layers in the following dimensions to match how LLM providers actually bill:

<!--vale off-->
{% table %}
columns:
  - title: Pricing dimension
    key: dimension
  - title: Description
    key: description
rows:
  - dimension: "Cache reads and writes"
    description: |
      Priced separately from input. A cache read (a hit) is typically discounted to around one tenth of the input rate. A cache write can cost more than a normal input token.
  - dimension: "Cache lifetime (TTL)"
    description: |
      Determines the cache-write price on providers that offer more than one cache TTL tier. For example, Anthropic prices a 5-minute TTL at 1.25x of input and a 1-hour TTL at 2x.
  - dimension: "Context-size threshold"
    description: |
      Re-prices the entire request at a higher rate once input tokens cross a threshold. For example, GPT-5.6 above 272K input tokens doubles the input rate and raises the output rate by 50%.
  - dimension: "Service tier"
    description: |
      Multiplies input and output rates together. A priority or fast tier raises the rate for lower latency; a flex tier lowers it. Because cache is priced from base input, the multiplier flows through to cache as well.
{% endtable %}
<!--vale on-->

## Model cost configuration

Pricing is configured per target on the [AI Model entity](/ai-gateway/entities/ai-model/)'s [targets](/ai-gateway/entities/ai-model/#targets), using the [`input_cost`](/ai-gateway/entities/ai-model/#schema-aigateway-target-config-input-cost) and [`output_cost`](/ai-gateway/entities/ai-model/#schema-aigateway-target-config-output-cost) fields. Three optional fields extend those scalars to cover the dimensions in [Model pricing dimensions](#model-pricing-dimensions): `cache_write_cost_list`, `context_window_factor`, and `service_tier_factor`. If one of these fields is absent, the calculation falls back to the corresponding scalar. If the field is present but no entry matches a request, the calculation also falls back to the scalar.

{:.info}
> `cache_write_cost_list`, `context_window_factor`, and `service_tier_factor` extend the AI Model target schema beyond `input_cost` and `output_cost`. Check the [AI Model entity](/ai-gateway/entities/ai-model/) reference for more details.

### Scalar fields

`input_cost` and `output_cost` price every target. Add `cache_read_cost` and `cache_write_cost` when the provider discounts cache reads or charges more for cache writes:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "[`input_cost`](/ai-gateway/entities/ai-model/#schema-aigateway-target-config-input-cost)"
    description: Price per one million input tokens.
  - field: "[`output_cost`](/ai-gateway/entities/ai-model/#schema-aigateway-target-config-output-cost)"
    description: Price per one million output tokens.
  - field: "`cache_read_cost`"
    description: Price per one million cache-read (cache-hit) tokens.
  - field: "`cache_write_cost`"
    description: |
      Price per one million cache-write tokens. For a model with a single cache TTL tier, this scalar is the cache-write price and no `cache_write_cost_list` is needed.
{% endtable %}
<!--vale on-->

### `cache_write_cost_list`

Use `cache_write_cost_list` when a provider prices cache writes differently depending on how long the entry is kept, for example Anthropic's 5-minute and 1-hour TTL tiers. Set a `ttl` and its `cost` per entry:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`ttl`"
    description: |
      The cache lifetime, given as a number plus a time unit (`h` for hours, `m` for minutes), for example `1h` or `5m`.
  - field: "`cost`"
    description: The price per one million cache-write tokens at that TTL.
{% endtable %}
<!--vale on-->

If a request's TTL doesn't match any entry, the model falls back to `cache_write_cost`.

### `context_window_factor`

Use `context_window_factor` when a provider re-prices an entire request once it crosses a context-size threshold, for example GPT-5.6's rate change above 272K input tokens. Each entry pairs a token threshold with its input and output multipliers:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`above`"
    description: |
      The input-token threshold, given as a number plus a size unit (`k` or `m`), for example `200k` or `1m`. The threshold is measured on input tokens and gates both factors below.
  - field: "`input_factor`"
    description: The multiplier applied to input-side pricing when the threshold is exceeded.
  - field: "`output_factor`"
    description: The multiplier applied to output-side pricing when the threshold is exceeded.
{% endtable %}
<!--vale on-->

If multiple entries exist, the model selects the tier closest to the actual context-window size.

{:.info}
> With a 2M-token request and tiers at `above: 200k` and `above: 1m`, the `above: 1m` tier applies.

### `service_tier_factor`

Use `service_tier_factor` when a provider offers a priority tier for lower latency or a flex tier for lower cost, and you want that price difference reflected in the calculated cost. The standard (default) tier is `1` and needs no configuration. Pair each tier name with its multiplier:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`tier`"
    description: The service tier this factor applies to, for example `priority` or `flex`.
  - field: "`factor`"
    description: |
      The multiplier applied across the whole request (input and output, and therefore cache) when this tier is in effect.
{% endtable %}
<!--vale on-->

### Example configuration

This model bills:

- $4 per million input tokens and $24 per million output tokens, on the standard service tier.
- $0.4 per million cache-read tokens, a tenth of the input rate.
- $5 per million cache-write tokens by default, or $8 per million tokens for entries with a 1-hour TTL.
- Double the input rate and 1.5x the output rate, once a request's input crosses 200K tokens.
- Double the resulting rate on the `priority` tier, or half on the `flex` tier.

```yaml
# Scalar fields (always present)
input_cost: 4          # $ per 1M input tokens
output_cost: 24         # $ per 1M output tokens
cache_read_cost: 0.4    # $ per 1M cache-read tokens
cache_write_cost: 5     # $ per 1M cache-write tokens (fallback)

# Cache-write pricing by TTL
cache_write_cost_list:
  - ttl: 5m
    cost: 5
  - ttl: 1h
    cost: 8

# Context-window pricing
context_window_factor:
  - above: 200k         # threshold measured on input tokens
    input_factor: 2
    output_factor: 1.5

# Service-tier pricing (standard = 1, omitted)
service_tier_factor:
  - tier: priority
    factor: 2
  - tier: flex
    factor: 0.5
```

## Model cost calculation

For a single request, {{site.ai_gateway}} calculates cost from the configured fields as follows:

```
cost = service_tier_factor * (
    context_window_factor_for_input * (
        input
        + cache_read
        + cache_write priced per its TTL tier
    )
    + context_window_factor_for_output * output
)
```
{:.no-copy-code}

The calculation proceeds in four steps:

1. **Price the input side:**<br> Sum normal input, cache reads, and cache writes. Normal input tokens are priced at `input_cost` and cache reads at `cache_read_cost`. Cache writes are priced by matching the request's TTL against `cache_write_cost_list`. If no entry matches, `cache_write_cost` applies. Because cache pricing derives from the base input side, any discount or premium on input flows through to cache automatically.
1. **Apply the context-window factor:**<br> If the request's input-token count crosses a threshold in `context_window_factor`, the input side is multiplied by that tier's `input_factor` and the output side by its `output_factor`. If no threshold is crossed, both factors are effectively `1`. The threshold is always measured on input tokens and gates both factors together.
1. **Price the output side:**<br> Output tokens are priced at `output_cost` and multiplied by the applicable `output_factor`. Reasoning or thinking tokens, where a provider produces them, are billed at the output rate.
1. **Apply the service-tier multiplier:**<br> The `factor` for the request's service tier scales the entire composed cost, input side and output side together. Because the input side already includes cache, the service-tier factor flows through to cache pricing as well. The standard tier uses a factor of `1`.

{:.success}
> Per-token rates are expressed per one million tokens, so the final figure divides accordingly. The result is the cost of the request.

## Relationship to AI Rate Limiting Advanced

{{site.ai_gateway}} prices a request entirely within the [AI Model entity](/ai-gateway/entities/ai-model/): every field in [Model cost configuration](#model-cost-configuration) lives on a [target](/ai-gateway/entities/ai-model/#targets), not on any policy. [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) doesn't define any pricing fields of its own. It consumes the cost figure the AI Model already calculated for the request, and enforces a limit against it when a limit's strategy is set to `cost`.

<!--vale off-->
{% table %}
columns:
  - title: Concern
    key: concern
  - title: Configured on
    key: configured_on
rows:
  - concern: "How much a request costs (pricing)"
    configured_on: "[AI Model entity](/ai-gateway/entities/ai-model/) target config: `input_cost`, `output_cost`, and the fields in [Model cost configuration](#model-cost-configuration)"
  - concern: "Whether a request is allowed to proceed based on cost"
    configured_on: "[AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) policy, using a limit's `cost` strategy"
{% endtable %}
<!--vale on-->

This split means changing a model's pricing (for example, updating `input_cost` after a provider rate change) never requires touching the AI Rate Limiting Advanced configuration, and changing a rate limit never requires touching the AI Model. The cost figure produced by the calculation in this page is reported by {{site.ai_gateway}} regardless of whether any rate-limiting policy is attached.
