---
title: "{{site.ai_gateway}} audit log reference"
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
description: "{{site.ai_gateway}} provides a standardized logging format for AI plugins, enabling the emission of analytics events and facilitating the aggregation of AI usage analytics across various providers."

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} plugins"
    url: /plugins/?category=ai
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/

works_on:
  - on-prem
  - konnect
---

{{site.ai_gateway}} emits structured analytics logs for [AI plugins](/plugins/?category=ai) through the standard [{{site.base_gateway}} logging infrastructure](/gateway/logs/). This means AI-specific logs are written to [the same locations](/gateway/logs/#where-are-kong-gateway-logs-located) as other Kong logs, such as `/usr/local/kong/logs/error.log`, or to Docker container logs if you're running in a containerized environment.

Like other Kong logs, {{site.ai_gateway}} logs are subject to the [global log level](/gateway/logs/#configure-log-levels) configured via the [`kong.conf`](/gateway/configuration/) file or the Admin API. You can control log verbosity by adjusting the `log_level` setting (for example, `info`, `notice`, `warn`, `error`, `crit`) to determine which log entries are captured.

You can also use [logging plugins](/plugins/?category=logging) to route these logs to external systems, such as file systems, log aggregators, or monitoring tools.

## Log details

Each AI plugin returns a set of tokens. Log entries include the following details:


### AI Proxy core logs

The [AI Proxy](/plugins/ai-proxy/) and [AI Proxy Advanced](/plugins/ai-proxy/) plugins act as the main gateway for forwarding requests to AI providers. Logs here capture detailed information about the request and response payloads, token usage, model details, latency, and cost metrics. They provide a comprehensive view of each AI interaction.

{:.warning}
> Logs and metrics for cost and token usage via the [OpenAI Files API](https://developers.openai.com/api/reference/resources/files/methods/list) are not currently supported.

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.proxy.payload.request`"
    description: The request payload sent to the upstream AI provider.
  - property: "`ai.proxy.payload.response`"
    description: The response payload received from the upstream AI provider.
  - property: "`ai.proxy.usage.prompt_tokens`"
    description: |
      The number of tokens used for prompting.
      Used for text-based requests (chat, completions, embeddings).
  - property: "`ai.proxy.usage.prompt_tokens_details`"
    description: |
      {% new_in 3.11 %} A breakdown of prompt tokens (`cached_tokens`, `audio_tokens`).
  - property: "`ai.proxy.usage.completion_tokens`"
    description: |
      The number of tokens used for completion.
      Used for text-based responses (chat, completions).
  - property: "`ai.proxy.usage.completion_tokens_details`"
    description: |
      {% new_in 3.11 %} A breakdown of completion tokens (`rejected_prediction_tokens`, `reasoning_tokens`, `accepted_prediction_tokens`, `audio_tokens`).
  - property: "`ai.proxy.usage.total_tokens`"
    description: |
      The total number of tokens used (input + output).
      Includes prompt/completion tokens for text, and input/output tokens for non-text modalities.
  - property: "`ai.proxy.usage.input_tokens`"
    description: |
      {% new_in 3.11 %} The total number of input tokens (text + image + audio).
      Used for non-text requests (e.g., image or audio generation).
  - property: "`ai.proxy.usage.input_tokens_details`"
    description: |
      {% new_in 3.11 %} A breakdown of input tokens by modality (`text_tokens`, `image_tokens`, `audio_tokens_count`).
  - property: "`ai.proxy.usage.output_tokens`"
    description: |
      {% new_in 3.11 %} The total number of output tokens (text + audio).
      Used for non-text responses (e.g., image or audio generation).
  - property: "`ai.proxy.usage.output_tokens_details`"
    description: |
      {% new_in 3.11 %} A breakdown of output tokens by modality (`text_tokens`, `audio_tokens`).
  - property: "`ai.proxy.usage.cost`"
    description: The total cost of the request.
  - property: "`ai.proxy.usage.time_per_token`"
    description: |
      {% new_in 3.8 %} Average time to generate an output token (ms).
  - property: "`ai.proxy.usage.time_to_first_token`"
    description: |
      {% new_in 3.12 %} Time to receive the first output token (ms).
  - property: "`ai.proxy.meta.request_model`"
    description: The model used for the AI request.
  - property: "`ai.proxy.meta.response_model`"
    description: The model used to generate the AI response.
  - property: "`ai.proxy.meta.provider_name`"
    description: The name of the AI service provider.
  - property: "`ai.proxy.meta.plugin_id`"
    description: Unique identifier of the plugin instance.
  - property: "`ai.proxy.meta.llm_latency`"
    description: |
      {% new_in 3.8 %} Time taken by the LLM provider to generate the full response (ms).
  - property: "`ai.proxy.meta.request_mode`"
    description: |
      {% new_in 3.12 %} The request mode. Can be `oneshot`, `stream`, or `realtime`.
{% endtable %}

### AI AWS Guardrails logs {% new_in 3.11 %}

For users using the [AI AWS Guardrails plugin](/plugins/ai-aws-guardrails/), logs capture processing times and configuration metadata related to content guardrails applied to inputs and outputs.

The following fields appear in structured AI logs when the AI AWS Guardrails plugin is enabled:

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.proxy.aws-guardrails.guardrails_id`"
    description: The unique identifier of the guardrails configuration applied.
  - property: "`ai.proxy.aws-guardrails.output_processing_latency`"
    description: The time (in milliseconds) taken to process the output through guardrails.
  - property: "`ai.proxy.aws-guardrails.input_processing_latency`"
    description: The time (in milliseconds) taken to process the input through guardrails.
  - property: "`ai.proxy.aws-guardrails.guardrails_version`"
    description: The version or state of the guardrails configuration (for example, `DRAFT`, `RELEASE`).
  - property: "`ai.proxy.aws-guardrails.aws_region`"
    description: The AWS region where the guardrails are deployed or executed.
{% endtable %}

### AI Azure Content Safety logs

If the [AI Azure Content Safety plugin](/plugins/ai-azure-content-safety/) is enabled, each corresponding log entry records a detected feature level for a user-defined content safety category (for example, `Hate`, `Violence`, `SexualContent`). The category is a user-defined name, and the feature level indicates the detected severity for that category, as seen here. Multiple entries can appear per request depending on the configuration and detected content.

For detailed information on categories and severity levels, see [Harm categories in Azure AI Content Safety - Azure AI services](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concept-harm-categories).

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.audit.azure_content_safety.<CATEGORY>`"
    description: Detected feature level for a user-defined category (for example, `Hate`, `Violence`). There can be multiple entries per request depending on configuration and detected content.
{% endtable %}

### AI Lakera Guard logs {% new_in 3.13 %}

If you're using the [AI Lakera Guard plugin](/plugins/ai-lakera-guard/), {{site.ai_gateway}} logs include additional fields under the lakera-guard object for each plugin entry. These fields provide insight into inspection behavior. For example, processing latency, request UUIDs, and violation details when requests or responses are blocked.

The following fields appear in AI logs when the AI Lakera Guard plugin is enabled:

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.proxy.lakera-guard.input_processing_latency`"
    description: |
      The time, in milliseconds, that Lakera took to process the inspected request.
  - property: "`ai.proxy.lakera-guard.lakera_service_url`"
    description: |
      The Lakera API endpoint used for inspection, such as `https://api.lakera.ai/v2/guard`.
  - property: "`ai.proxy.lakera-guard.input_request_uuid`"
    description: |
      The unique identifier assigned by Lakera for the inspected request.
  - property: "`ai.proxy.lakera-guard.lakera_project_id`"
    description: |
      The Lakera project identifier used for the inspection.
  - property: "`ai.proxy.lakera-guard.input_block_detail`"
    description: |
      An array of violation objects present when Lakera blocks a request.
      Each object includes `policy_id`, `detector_id`, `project_id`, `message_id`,
      `detected` (boolean), and `detector_type`, such as `moderated_content/hate`.
  - property: "`ai.proxy.lakera-guard.input_block_reason`"
    description: |
      The detector type that caused Lakera to block the request.
  - property: "`ai.proxy.lakera-guard.output_processing_latency`"
    description: |
      The time, in milliseconds, that Lakera took to process the inspected response.
  - property: "`ai.proxy.lakera-guard.output_request_uuid`"
    description: |
      The unique identifier assigned by Lakera for the inspected response.
  - property: "`ai.proxy.lakera-guard.output_block_detail`"
    description: |
      An array of violation objects present when Lakera blocks a response.
      The structure matches `input_block_detail`.
  - property: "`ai.proxy.lakera-guard.output_block_reason`"
    description: |
      The detector type that caused Lakera to block the response.
{% endtable %}


### AI PII Sanitizer logs {% new_in 3.10 %}

If you're using the [AI PII Sanitizer plugin](/plugins/ai-sanitizer/), {{site.ai_gateway}} logs include additional fields that provide insight into the detection and redaction of personally identifiable information (PII). These fields track the number of entities identified and sanitized, the time taken to process the payload, and detailed metadata about each sanitized item—including the original value, redacted value, and detected entity type.

The following fields appear in structured AI logs when the AI PII Sanitizer plugin is enabled:

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.sanitizer.pii_identified`"
    description: The number of PII entities detected in the input payload.
  - property: "`ai.sanitizer.pii_sanitized`"
    description: The number of PII entities that were anonymized or redacted.
  - property: "`ai.sanitizer.duration`"
    description: The time taken (in milliseconds) by the `ai-pii-service` container to process the payload.
  - property: "`ai.sanitizer.sanitized_items`"
    description: A list of sanitized PII entities, each including the original text, redacted text, and the entity type.
{% endtable %}

### AI Prompt Compressor logs {% new_in 3.11 %}

When the [AI Prompt Compressor plugin](/plugins/ai-prompt-compressor/) is enabled, additional logs record token counts before and after compression, compression ratios, and metadata about the compression method and model used.

The following fields appear in structured AI logs when the AI Prompt Compressor plugin is enabled:

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.compressor.original_token_count`"
    description: The original number of tokens before compression.
  - property: "`ai.compressor.compress_token_count`"
    description: The number of tokens after compression.
  - property: "`ai.compressor.save_token_count`"
    description: The number of tokens saved by compression (original minus compressed).
  - property: "`ai.compressor.compress_value`"
    description: The compression ratio applied.
  - property: "`ai.compressor.compress_type`"
    description: The type or method of compression used.
  - property: "`ai.compressor.compressor_model`"
    description: The model used to perform the compression.
  - property: "`ai.compressor.msg_id`"
    description: The identifier of the message that was compressed.
  - property: "`ai.compressor.information`"
    description: A summary or message describing the result of compression.
{% endtable %}

### AI RAG Injector logs {% new_in 3.10 %}

If you're using the [AI RAG Injector plugin](/plugins/ai-rag-injector/), {{site.ai_gateway}} logs include additional fields that provide detailed information about the retrieval-augmented generation process. These fields track the vector database used, whether relevant context was injected into the prompt, the latency of data fetching, and embedding metadata such as tokens used and the provider/model details.

The following fields appear in structured AI logs when the AI RAG Injector plugin is enabled:

{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.proxy.rag-inject.vector_db`"
    description: The vector database used (for example, `pgvector`).
  - property: "`ai.proxy.rag-inject.injected`"
    description: Boolean indicating if RAG injection occurred.
  - property: "`ai.proxy.rag-inject.fetch_latency`"
    description: The fetch latency in milliseconds.
  - property: "`ai.proxy.rag-inject.chunk_ids`"
    description: List of chunk IDs retrieved.
  - property: "`ai.proxy.rag-inject.embeddings_latency`"
    description: Time taken to generate embeddings, in milliseconds.
  - property: "`ai.proxy.rag-inject.embeddings_tokens`"
    description: Number of tokens used for embeddings.
  - property: "`ai.proxy.rag-inject.embeddings_provider`"
    description: Provider used to generate embeddings.
  - property: "`ai.proxy.rag-inject.embeddings_model`"
    description: Model used to generate embeddings.
{% endtable %}

### AI Semantic Cache logs {% new_in 3.8 %}

If you're using the [AI Semantic Cache plugin](/plugins/ai-semantic-cache), {{site.ai_gateway}} logs include additional fields under the cache object for each plugin entry. These fields provide insight into cache behavior—such as whether a response was served from cache, how long it took to fetch, and which embedding provider and model were used if applicable.

The following fields appear in AI logs when semantic caching is enabled:

{% table %}
columns:
- title: Property
  key: property
- title: Description
  key: description
rows:
- property: "`ai.proxy.cache.cache_status`"
  description: |
    {% new_in 3.8 %} The cache status. This can be `Hit`, `Miss`, `Bypass`, or `Refresh`.
- property: "`ai.proxy.cache.fetch_latency`"
  description: |
    The time, in milliseconds, it took to return a cached response.
- property: "`ai.proxy.cache.embeddings_provider`"
  description: |
    The provider used to generate the embeddings.
- property: "`ai.proxy.cache.embeddings_model`"
  description: |
    The model used to generate the embeddings.
- property: "`ai.proxy.cache.embeddings_latency`"
  description: |
    The time taken to generate the embeddings.
{% endtable %}

{:.info}
> **Note:**
> When returning a cached response, `time_per_token` and `llm_latency` are omitted.
> The cache response can be returned either as a semantic cache or an exact cache. If it's returned as a semantic cache, it will include additional details such as the embeddings provider, embeddings model, and embeddings latency.

### AI LLM as Judge logs {% new_in 3.12 %}

If you're using the [AI LLM as Judge plugin](/plugins/ai-llm-as-judge), {{site.ai_gateway}} logs include additional fields under the `ai-llm-as-judge` object. These fields provide insight into evaluation behavior—such as which models were scored, latency, and the numeric accuracy assigned by the judge.

The following fields appear in AI logs when the LLM as Judge plugin is enabled:

{% table %}
columns:
- title: Property
  key: property
- title: Description
  key: description
rows:
- property: "`ai.proxy.ai-llm-as-judge.meta.llm_latency`"
  description: |
    The time, in milliseconds, that the judge model took to return a score.
- property: "`ai.proxy.ai-llm-as-judge.meta.request_model`"
  description: |
    The candidate model being evaluated by the judge.
- property: "`ai.proxy.ai-llm-as-judge.meta.response_model`"
  description: |
    The model used as the judge (for example, `gpt-4o`).
- property: "`ai.proxy.ai-llm-as-judge.meta.provider_name`"
  description: |
    The provider of the judge model (for example, `openai`).
- property: "`ai.proxy.ai-llm-as-judge.meta.request_mode`"
  description: |
    The mode used for evaluation (for example, `oneshot`).
- property: "`ai.proxy.ai-llm-as-judge.usage.llm_accuracy`"
  description: |
    The numeric accuracy score (1–100) returned by the judge model.
{% endtable %}


### AI MCP logs {% new_in 3.12 %}

If you're using the [AI MCP plugin](/plugins/ai-mcp-proxy/), {{site.ai_gateway}} logs include additional fields under the `ai.mcp` object. These fields are exposed when the AI MCP plugin is enabled and provide insight into Model Context Protocol (MCP) traffic, including session IDs, JSON-RPC request/response payloads, latency, tool usage and {% new_in 3.13 %} access control audit entries.

{:.info}
> **Note:** Unlike other available AI plugins, the AI MCP plugin is not invoked as part of an AI request.
> Instead, it is registered and executed as a regular plugin, allowing it to capture MCP traffic independently of AI request flow.
> Do not configure the AI MCP plugin together with other `ai-*` plugins on the same service or route.

The MCP log structure groups traffic by **MCP session ID**, with each session containing zero or more recorded JSON-RPC requests:

<!-- vale off -->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: description
rows:
  - property: "`ai.mcp.mcp_session_id`"
    description: The ID of the MCP session. A session can contain multiple requests.
  - property: "`ai.mcp.rpc`"
    description: An array of recorded JSON-RPC requests. Only JSON-RPC traffic is logged.
  - property: "`ai.mcp.rpc[].id`"
    description: The ID of the JSON-RPC request. Not all JSON-RPC requests have an ID.
  - property: "`ai.mcp.rpc[].latency`"
    description: The latency of the JSON-RPC request, in milliseconds.
  - property: "`ai.mcp.rpc[].payload.request`"
    description: The request payload of the JSON-RPC request, serialized as a JSON string.
  - property: "`ai.mcp.rpc[].payload.response`"
    description: The response payload of the JSON-RPC request, serialized as a JSON string.
  - property: "`ai.mcp.rpc[].method`"
    description: The JSON-RPC method name.
  - property: "`ai.mcp.rpc[].tool_name`"
    description: If the method is a tool call, the name of the tool being invoked.
  - property: "`ai.mcp.rpc[].error`"
    description: The error message if an error occurred during the request.
  - property: "`ai.mcp.rpc[].response_body_size`"
    description: The size of the JSON-RPC response body, in bytes.
  - property: "`ai.mcp.audit`"
    description: |
      {% new_in 3.13 %} An array of access control audit entries. Each entry records whether access was allowed or denied for a specific MCP primitive or globally.
  - property: "`ai.mcp.audit[].primitive_name`"
    description: |
      {% new_in 3.13 %} The name of the MCP primitive (for example, `list_users`).
  - property: "`ai.mcp.audit[].primitive`"
    description: |
      {% new_in 3.13 %} The type of MCP primitive (for example, `tool`, `resource`, or `prompt`).
  - property: "`ai.mcp.audit[].action`"
    description: |
      {% new_in 3.13 %} The access control decision: `allow` or `deny`.
  - property: "`ai.mcp.audit[].consumer.name`"
    description: |
      {% new_in 3.13 %} The name of the consumer making the request.
  - property: "`ai.mcp.audit[].consumer.id`"
    description: |
      {% new_in 3.13 %} The UUID of the consumer.
  - property: "`ai.mcp.audit[].consumer.identifier`"
    description: |
      {% new_in 3.13 %} The type of consumer identifier (for example, `consumer_group`).
  - property: "`ai.mcp.audit[].scope`"
    description: |
      {% new_in 3.13 %} The scope of the access control check.
{% endtable %}
<!-- vale on -->

## Example log entries

### LLM traffic entry

The following example shows a structured {{site.ai_gateway}} log entry:

```json
{
  "ai": {
    "payload": {
      "request": "$OPTIONAL_PAYLOAD_REQUEST"
    },
    "proxy": {
      "payload": {
        "response": "$OPTIONAL_PAYLOAD_RESPONSE"
      },
      "usage": {
      "time_per_token": 30.142857142857,
      "time_to_first_token": 631,
      "completion_tokens": 21,
      "completion_tokens_details": {
        "rejected_prediction_tokens": 0,
        "reasoning_tokens": 0,
        "accepted_prediction_tokens": 0,
        "audio_tokens": 0
      },
      "prompt_tokens_details": {
        "cached_tokens": 0,
        "audio_tokens": 0
      },
      "prompt_tokens": 14,
      "total_tokens": 35,
      "cost": 0
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
        "fetch_latency": 12,
        "embeddings_provider": "openai",
        "embeddings_model": "text-embedding-ada-002",
        "embeddings_latency": 42
      },
      "aws-guardrails": {
        "guardrails_id": "gr-1234abcd",
        "guardrails_version": "RELEASE",
        "aws_region": "us-west-2",
        "inputput_processing_latency": 134,
        "output_processing_latency": 278
      },
      "rag-inject": {
        "vector_db": "pgvector",
        "injected": true,
        "fetch_latency": 154,
        "chunk_ids": ["chunk-1", "chunk-2"],
        "embeddings_latency": 37,
        "embeddings_tokens": 62,
        "embeddings_provider": "openai",
        "embeddings_model": "text-embedding-ada-002"
      }
    },
    "compressor": {
      "original_token_count": 845,
      "compress_token_count": 485,
      "save_token_count": 360,
      "compress_value": 0.5,
      "compress_type": "rate",
      "compressor_model": "microsoft/llmlingua-2-bert-base-multilingual-cased-meetingbank",
      "msg_id": 1,
      "information": "Compression was performed and saved 360 tokens"
    },
    "sanitizer": {
      "pii_identified": 3,
      "pii_sanitized": 3,
      "duration": 65,
      "sanitized_items": [
        {
          "entity_type": "EMAIL",
          "original": "jane.doe@example.com",
          "sanitized": "[REDACTED]"
        },
        {
          "entity_type": "PHONE_NUMBER",
          "original": "555-123-4567",
          "sanitized": "[REDACTED]"
        }
      ]
    },
    "audit": {
      "azure_content_safety": {
        "Hate": "High",
        "Violence": "Medium"
      }
    }
  }
}
```

### MCP traffic entry

The following example shows an MCP log entry:

```json
{
  "ai": {
    "mcp": {
      "rpc": [
        {
          "method": "tools/call",
          "latency": 6,
          "id": "2",
          "response_body_size": 5030,
          "tool_name": "list_orders"
        }
      ],
      "audit": [
        {
          "primitive_name": "list_orders",
          "consumer": {
            "id": "6c95a611-9991-407b-b1c3-bc608d3bccc3",
            "name": "admin",
            "identifier": "consumer_group"
          },
          "scope": "primitive",
          "primitive": "tool",
          "action": "allow"
        }
      ]
    }
  },
      "rpc": [
        {
          "method": "tools/call",
          "id": "1",
          "latency": 3,
          "tool_name": "list_orders",
          "response_body_size": 5030
        }
      ]
    }
  }
}
```
