---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: AI AWS Guardrails Policy
    url: /ai-gateway/policies/ai-aws-guardrails/
  - text: AI Azure Content Safety Policy
    url: /ai-gateway/policies/ai-azure-content-safety/
  - text: AI Custom Guardrail Policy
    url: /ai-gateway/policies/ai-custom-guardrail/
    
faqs:
  - q: What do I do if I see the error `Blocked by Model Armor Floor Setting`?
    a: |
      If you see the following error:

      ```json
      {
        "reason": "MODEL_ARMOR",
        "message": "Blocked by Model Armor Floor Setting: The prompt violated X, Y, and Z filters.",
        "error": true
      }
      ```
      This means the AI GCP Model Armor Policy is conflicting with settings configured in a Gemini AI Model Provider configured for GCP Vertex. We recommend disabling the GCP Model Armor Floor in GCP, as this setting fails in some modes (for example, streaming response mode), and blocks all analytics.
---

The GCP Model Armor Policy integrates {{site.ai_gateway}} with [{{ site.google_cloud }}’s Model Armor](https://cloud.google.com/security-command-center/docs/model-armor-overview) service to enforce content safety guardrails on AI requests and responses.

It leverages GCP SaaS APIs to inspect prompts and model outputs, preventing unsafe content from being processed or returned to users.

## Features

The AI GCP Model Armor Policy provides the following content safety capabilities:

<!-- vale off -->
{% table %}
columns:
  - title: Feature
    key: feature
  - title: Description
    key: description
rows:
  - feature: Request and response guardrails
    description: Checks chat requests and chat responses to prevent unsafe content. Controlled by `guarding_mode` (`INPUT`, `OUTPUT`, or `BOTH`).
  - feature: Single template enforcement
    description: Applies one GCP Model Armor template for all inspections, ensuring consistent filtering. Set with `template_id`.
  - feature: Reveal blocked categories
    description: Optionally show the categories that triggered blocking (for example, `"hate speech"`). Controlled by `reveal_failure_categories`.
  - feature: Streaming response inspection
    description: Buffers streaming responses and terminates if unsafe content is detected. Configurable via `response_buffer_size`.
  - feature: Custom failure messages
    description: Configure user-facing messages with `request_failure_message` and `response_failure_message` when content is blocked.
{% endtable %}
<!-- vale on -->

## How it works

The AI GCP Model Armor Policy inspects requests and responses using GCP Model Armor:

* **Request inspection**: Chat prompts are intercepted, and the relevant content (by default, the last chat message) is sent to the [sanitizeUserPrompt](https://cloud.google.com/security-command-center/docs/sanitize-prompts-responses#text-prompts) API.
* **Response inspection:** Chat responses are buffered (supporting gzip and streaming) and sent to the [sanitizeModelResponse](https://cloud.google.com/security-command-center/docs/sanitize-prompts-responses#sanitize-model) API. SSE streaming is supported with chunk buffering.

### Request guarding flow

1. An incoming request to an LLM (for example, a chat completion) is intercepted by the AI GCP Model Armor Policy.
2. The AI GCP Model Armor Policy extracts the relevant content, usually the last user message in the conversation.
3. The content is submitted to GCP Model Armor’s `sanitizeUserPrompt` endpoint for analysis.

### Response guarding flow

1. The AI GCP Model Armor Policy buffers the upstream response body (including gzipped responses).
2. It extracts the model’s response content.
3. The content is sent to GCP Model Armor’s `sanitizeModelResponse` endpoint for validation.

### Sanitization and action

1. GCP Model Armor evaluates the provided content against the configured `template_id`.
2. The AI GCP Model Armor Policy interprets the `sanitizationResult` from GCP.
3. If a violation is detected (for example, hatred, sexually explicit content, harassment, or jailbreak attempts), the request or response is blocked.
4. Blocked traffic returns the response for the configured [rejection mode](#rejection-modes). By default, the response is a `400 Bad Request` with the configured `request_failure_message` or `response_failure_message`.
5. If `reveal_failure_categories` is enabled, the response also lists the categories that triggered blocking.

{:.info}
> When configuring `template_id` in the AI GCP Model Armor Policy, ensure that it aligns with the content safety policies and categories defined in your GCP Model Armor service.
>
> Review whether your organization requires custom categories or additional policy definitions, and integrate them into the selected template to match compliance and safety requirements.

## Rejection modes

The {{page.name}} Policy responds to a blocked request or response according to its rejection mode.

{% include_cached md/ai-gateway/v2/guardrail-rejection-modes.md name=page.name checks_responses=true %}

In `none` mode, the response body is the plain message set in [`config.request_failure_message`](/ai-gateway/policies/ai-gcp-model-armor/reference/#schema--config-request-failure-message) for requests or [`config.response_failure_message`](/ai-gateway/policies/ai-gcp-model-armor/reference/#schema--config-response-failure-message) for responses.
The following response is the body for a request blocked in `none` mode:

```json
{
  "message": "Request was filtered by GCP Model Armor",
  "error": true
}
```

In `verbose` mode, `reason` is the type of the Model Armor filter that matched, and `detail` lists the filter results that GCP Model Armor returned.
For example, a prompt injection attempt returns the following response:

```json
{
  "error": {
    "type": "guardrail_rejected",
    "plugin": "ai-gcp-model-armor",
    "reason": "pi_and_jailbreak.piAndJailbreakFilterResult",
    "code": "GUARDRAIL_BLOCKED",
    "detail": [
      {
        "checkType": "pi_and_jailbreak.piAndJailbreakFilterResult",
        "confidenceLevel": "MEDIUM_AND_ABOVE"
      }
    ]
  }
}
```

To return this response, set [`config.rejection_mode`](/ai-gateway/policies/ai-gcp-model-armor/reference/#schema--config-rejection-mode) to `verbose`:

{% entity_example %}
type: policy
data:
  display_name: AI GCP Model Armor - Verbose Rejection
  name: ai-gcp-model-armor
  type: ai-gcp-model-armor
  config:
    project_id: YOUR_PROJECT_ID
    location_id: us-central1
    template_id: YOUR_TEMPLATE_ID
    gcp_use_service_account: true
    gcp_service_account_json: ${gcp_service_account_json}
    rejection_mode: verbose
variables:
  gcp_service_account_json:
    value: $GCP_SERVICE_ACCOUNT_JSON
    description: The JSON key of a GCP service account with access to the Model Armor template.
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

## Detect without blocking

{% include_cached md/ai-gateway/v2/guardrail-continue-on-detection.md name=page.name logs_detection=true %}

## Best practices

The following configuration guidance helps ensure effective content safety enforcement:

{% table %}
columns:
  - title: Setting
    key: field
  - title: Description
    key: description
rows:
  - field: |
      `guarding_mode`
    description: Set to `INPUT` for request-only inspection, `OUTPUT` for response-only, or `BOTH` to guard both directions.
  - field: |
      `request_failure_message` / `response_failure_message`
    description: Provide user-friendly error messages when prompts or responses are blocked.
  - field: |
      `reveal_failure_categories`
    description: Enable to return details on why content was blocked.
  - field: |
      `response_buffer_size`
    description: Tune how much of the upstream response is buffered before inspection; smaller values reduce latency.
  - field: Default last message inspection with `text_source`
    description: Keep the default behavior of checking only the last user prompt message for highest accuracy.
{% endtable %}

{:.warning}
> **Caution**: Do **not** set the Model Armor Floor Setting directly in GCP, as it will cause conflicts with the AI GCP Model Armor Policy.
See the [FAQ entry for this error](#what-do-i-do-if-i-see-the-error-blocked-by-model-armor-floor-setting) for more information.

## Unrecognized filters

The AI GCP Model Armor Policy blocks requests when GCP Model Armor returns a filter result with an unrecognized or new filter type. To avoid blocked requests, review your Model Armor template and ensure it only includes filter types that the AI Policy supports.

## Logging

The AI GCP Model Armor Policy emits structured log data for every inspected request and response. For the full list of log fields, see the [{{site.ai_gateway}} audit log reference](/ai-gateway/ai-audit-log-reference/#ai-gcp-model-armor-logs).

To log the raw content of blocked requests and responses, enable [`config.log_blocked_content`](/ai-gateway/policies/ai-gcp-model-armor/reference/#schema--config-log-blocked-content). When enabled, the blocked prompt or response body appears under `ai.proxy.gcp-model-armor.input_faulty_prompt` and `ai.proxy.gcp-model-armor.output_faulty_response` in the log entry.

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}

## Limitations

* Only chat prompts and chat responses are inspected; embeddings and other modalities are not checked.
* Inspects one chat message or one response body at a time. Combining multiple messages reduces accuracy.
* For SSE streaming, the Policy inspects the response in segments, so unsafe content can reach the client before the Policy blocks the stream. A violation that only appears across several segments might not be blocked.
* Only one `template_id` can be configured per AI Policy.