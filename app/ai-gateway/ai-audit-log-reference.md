---
title: "AI Gateway audit log reference"
content_type: reference
layout: reference

products:
  - ai-gateway
  - gateway

tags:
  - ai
  - logging

min_version:
  gateway: '3.6'
breadcrumbs:
  - /ai-gateway/
description: "Kong AI Gateway provides a standardized logging format for AI plugins, enabling the emission of analytics events and facilitating the aggregation of AI usage analytics across various providers."

related_resources:
  - text: Kong AI Gateway
    url: /ai-gateway/
  - text: Kong AI Gateway plugins
    url: /plugins/?category=ai
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/

works_on:
  - on-prem
  - konnect
---

Kong AI Gateway emits structured analytics logs for [AI plugins](/plugins/?category=ai) through the standard [Kong Gateway logging infrastructure](/gateway/logging/). This means AI-specific logs are written to [the same locations](gateway/logs/#where-are-kong-gateway-logs-located) as other Kong logs, such as `/usr/local/kong/logs/error.log`, or to Docker container logs if you're running in a containerized environment.

Like other Kong logs, AI Gateway logs are subject to the [global log level](/gateway/logs/#configure-log-levels) configured via the [`kong.conf`](/gateway/configuration/) file or the Admin API. You can control log verbosity by adjusting the `log_level` setting (e.g., `info`, `notice`, `warn`, `error`, `crit`) to determine which log entries are captured.

You can also use [logging plugins](/plugins/?category=logging) to route these logs to external systems, such as file systems, log aggregators, or monitoring tools.

## Log details

Each AI plugin returns a set of tokens. Log entries include the following details:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.$PLUGIN_NAME.payload.request`"
    description: The request payload.
  - property: "`ai.$PLUGIN_NAME.payload.response`"
    description: The response payload.
  - property: "`ai.$PLUGIN_NAME.usage.prompt_token`"
    description: The number of tokens used for prompting.
  - property: "`ai.$PLUGIN_NAME.usage.completion_token`"
    description: The number of tokens used for completion.
  - property: "`ai.$PLUGIN_NAME.usage.total_tokens`"
    description: The total number of tokens used.
  - property: "`ai.$PLUGIN_NAME.usage.cost`"
    description: The total cost of the request (input and output cost).
  - property: "`ai.$PLUGIN_NAME.usage.time_per_token`"
    description: |
      {% new_in 3.8 %} The average time to generate an output token, in milliseconds.
  - property: "`ai.$PLUGIN_NAME.meta.request_model`"
    description:  The model used for the AI request.
  - property: "`ai.$PLUGIN_NAME.meta.provider_name`"
    description:  The name of the AI service provider.
  - property: "`ai.$PLUGIN_NAME.meta.response_model`"
    description:  The model used for the AI response.
  - property: "`ai.$PLUGIN_NAME.meta.plugin_id`"
    description:  The unique identifier of the plugin.
  - property: "`ai.$PLUGIN_NAME.meta.llm_latency`"
    description: |
      {% new_in 3.8 %} The time, in milliseconds, it took the LLM provider to generate the full response.
  - property: "`ai.$PLUGIN_NAME.cache.cache_status`"
    description: |
      {% new_in 3.8 %} The cache status. This can be `Hit`, `Miss`, `Bypass` or `Refresh`.
  - property: "`ai.$PLUGIN_NAME.cache.fetch_latency`"
    description: |
      {% new_in 3.8 %} The time, in milliseconds, it took to return a cache response.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_provider`"
    description: |
      {% new_in 3.8 %} For semantic caching, the provider used to generate the embeddings.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_model`"
    description: |
      {% new_in 3.8 %} For semantic caching, the model used to generate the embeddings.
  - property: "`ai.$PLUGIN_NAME.cache.embeddings_latency`"
    description: |
      {% new_in 3.8 %} For semantic caching, the time taken to generate the embeddings.{% endtable %}
<!--vale on-->

The following example shows a structured AI Gateway log entry:

```json
"ai": {
    "payload": { "request": "$OPTIONAL_PAYLOAD_REQUEST" },
    "$PLUGIN_NAME_1": {
      "payload": { "response": "$OPTIONAL_PAYLOAD_RESPONSE" },
      "usage": {
        "prompt_token": 28,
        "total_tokens": 48,
        "completion_token": 20,
        "cost": 0.0038,
        "time_per_token": 133
      },
      "meta": {
        "request_model": "command",
        "provider_name": "cohere",
        "response_model": "command",
        "plugin_id": "546c3856-24b3-469a-bd6c-f6083babd2cd",
        "llm_latency": 2670
      }
    },
    "$PLUGIN_NAME_2": {
      "payload": { "response": "$OPTIONAL_PAYLOAD_RESPONSE" },
      "usage": {
        "prompt_token": 89,
        "total_tokens": 145,
        "completion_token": 56,
        "cost": 0.0012,
        "time_per_token": 87
      },
      "meta": {
        "request_model": "gpt-35-turbo",
        "provider_name": "azure",
        "response_model": "gpt-35-turbo",
        "plugin_id": "5df193be-47a3-4f1b-8c37-37e31af0568b",
        "llm_latency": 4927
      }
    }
  }
```

## Cache logging {% new_in 3.8 %}

If you're using the [AI Semantic Cache plugin](/plugins/ai-semantic-cache), AI Gateway logs include additional fields under the cache object for each plugin entry. These fields provide insight into cache behavior—such as whether a response was served from cache, how long it took to fetch, and which embedding provider and model were used if applicable.

The following example shows how cache-related metadata appears alongside usage and model details in a structured AI log entry:

```json
"ai": {
    "payload": { "request": "$OPTIONAL_PAYLOAD_REQUEST_" },
    "$PLUGIN_NAME_1": {
      "payload": { "response": "$OPTIONAL_PAYLOAD_RESPONSE" },
      "usage": {
        "prompt_token": 28,
        "total_tokens": 48,
        "completion_token": 20,
        "cost": 0.0038,
        "time_per_token": 133
      },
      "meta": {
        "request_model": "command",
        "provider_name": "cohere",
        "response_model": "command",
        "plugin_id": "546c3856-24b3-469a-bd6c-f6083babd2cd",
        "llm_latency": 2670
      },
      "cache": {
        "cache_status": "Hit",
        "fetch_latency": 21
      }
    },
    "$PLUGIN_NAME_2": {
      "payload": { "response": "$OPTIONAL_PAYLOAD_RESPONSE" },
      "usage": {
        "prompt_token": 89,
        "total_tokens": 145,
        "completion_token": 56,
        "cost": 0.0012
      },
      "meta": {
        "request_model": "gpt-35-turbo",
        "provider_name": "azure",
        "response_model": "gpt-35-turbo",
        "plugin_id": "5df193be-47a3-4f1b-8c37-37e31af0568b"
      },
      "cache": {
        "cache_status": "Hit",
        "fetch_latency": 444,
        "embeddings_provider": "openai",
        "embeddings_model": "text-embedding-3-small",
        "embeddings_latency": 424
      }
    }
  }
```

{:.info}
> **Note:**
> When returning a cache response, `time_per_token` and `llm_latency` are omitted.
> The cache response can be returned either as a semantic cache or an exact cache. If it's returned as a semantic cache, it will include additional details such as the embeddings provider, embeddings model, and embeddings latency.
