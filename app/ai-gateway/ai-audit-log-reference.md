---
title: "AI Gateway audit log reference"
content_type: reference
layout: reference

products:
  - gateway

tags:
  - ai-gateway
  - logging

min_version:
  gateway: '3.6'

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

Kong AI Gateway provides a standardized logging format for [AI plugins](/plugins/?category=ai), enabling the emission of analytics events and facilitating the aggregation of AI usage analytics across various providers.


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
  - property: "`ai.payload.request`"
    description: The request payload.
  - property: "`ai.[$plugin_name].payload.response`"
    description: The response payload.
  - property: "`ai.[$plugin_name].usage.prompt_token`"
    description: The number of tokens used for prompting.
  - property: "`ai.[$plugin_name].usage.completion_token`"
    description: The number of tokens used for completion.
  - property: "`ai.[$plugin_name].usage.total_tokens`"
    description: The total number of tokens used.
  - property: "`ai.[$plugin_name].usage.cost`"
    description: The total cost of the request (input and output cost).
  - property: "`ai.[$plugin_name].usage.time_per_token`"
    description: |
      {% new_in 3.8 %} The average time to generate an output token, in milliseconds.
  - property: "`ai.[$plugin_name].meta.request_model`"
    description:  The model used for the AI request.
  - property: "`ai.[$plugin_name].meta.provider_name`"
    description:  The name of the AI service provider.
  - property: "`ai.[$plugin_name].meta.response_model`"
    description:  The model used for the AI response.
  - property: "`ai.[$plugin_name].meta.plugin_id`"
    description:  The unique identifier of the plugin.
  - property: "`ai.[$plugin_name].meta.llm_latency`"
    description: |
      {% new_in 3.8 %} The time, in milliseconds, it took the LLM provider to generate the full response.
  - property: "`ai.[$plugin_name].cache.cache_status`"
    description: |
      {% new_in 3.8 %} The cache status. This can be `Hit`, `Miss`, `Bypass` or `Refresh`.
  - property: "`ai.[$plugin_name].cache.fetch_latency`"
    description: |
      {% new_in 3.8 %} The time, in milliseconds, it took to return a cache response.
  - property: "`ai.[$plugin_name].cache.embeddings_provider`"
    description: |
      {% new_in 3.8 %} For semantic caching, the provider used to generate the embeddings.
  - property: "`ai.[$plugin_name].cache.embeddings_model`"
    description: |
      {% new_in 3.8 %} For semantic caching, the model used to generate the embeddings.
  - property: "`ai.[$plugin_name].cache.embeddings_latency`"
    description: |
      {% new_in 3.8 %} For semantic caching, the time taken to generate the embeddings.
{% endtable %}
<!--vale on-->

See the following AI plugin log format example:
```json
"ai": {
    "payload": { "request": "[$optional_payload_request_]" },
    "[$plugin_name_1]": {
      "payload": { "response": "[$optional_payload_response]" },
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
    "[$plugin_name_2]": {
      "payload": { "response": "[$optional_payload_response]" },
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

If you're using the [AI Semantic Cache plugin](/plugins/ai-semantic-cache), logging will include some additional details about caching:

```json
"ai": {
    "payload": { "request": "[$optional_payload_request_]" },
    "[$plugin_name_1]": {
      "payload": { "response": "[$optional_payload_response]" },
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
    "[$plugin_name_2]": {
      "payload": { "response": "[$optional_payload_response]" },
      "usage": {
        "prompt_token": 89,
        "total_tokens": 145,
        "completion_token": 56,
        "cost": 0.0012,
      },
      "meta": {
        "request_model": "gpt-35-turbo",
        "provider_name": "azure",
        "response_model": "gpt-35-turbo",
        "plugin_id": "5df193be-47a3-4f1b-8c37-37e31af0568b",
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


