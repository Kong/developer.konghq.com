---
title: 'AI NVIDIA NeMo Guardrail'
name: 'AI NVIDIA NeMo Guardrail'
publisher: kong-inc
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Check LLM requests and responses against NVIDIA NeMo Guardrails and block content that violates your safety rails.'
categories:
  - ai
tags:
  - ai
  - safety
search_aliases:
  - ai-nvidia-nemo-guardrail
  - nemo
  - nvidia
related_resources:
  - text: AI Custom Guardrail Policy
    url: /ai-gateway/policies/ai-custom-guardrail/
  - text: AI AWS Guardrails Policy
    url: /ai-gateway/policies/ai-aws-guardrails/
  - text: AI GCP Model Armor Policy
    url: /ai-gateway/policies/ai-gcp-model-armor/
  - text: AI Lakera Guard Policy
    url: /ai-gateway/policies/ai-lakera-guard/
  - text: AI Azure Content Safety Policy
    url: /ai-gateway/policies/ai-azure-content-safety/
  - text: "{{site.ai_gateway}} audit log reference"
    url: /ai-gateway/ai-audit-log-reference/
---

The AI NVIDIA NeMo Guardrail Policy inspects requests and responses handled by the [AI Model](/ai-gateway/entities/ai-model/) entity and checks them against [NVIDIA NeMo Guardrails](https://docs.nvidia.com/nemo/guardrails/). {{site.ai_gateway}} sends the content it extracts to the NeMo Guardrails microservice, and blocks any request or response that violates the safety rails you configure.

The Policy doesn't evaluate content itself. It delegates every decision to NeMo Guardrails, so the rails you define in NeMo (content safety, topic control, jailbreak detection, or your own Colang flows) determine what {{site.ai_gateway}} allows through.

## Prerequisites

Before using the AI NVIDIA NeMo Guardrail Policy, you need a running [NeMo Guardrails microservice](https://docs.nvidia.com/nemo/microservices/latest/guardrails/index.html) that {{site.ai_gateway}} can reach. The microservice listens on port `7331` by default, and the Policy calls its `/v1/guardrail/checks` endpoint.

You also need at least one guardrail configuration. You can store configurations on the NeMo server and reference them by ID, or send a configuration inline with every check. For more information, see [Manage guardrail configurations](https://docs.nvidia.com/nemo/microservices/latest/guardrails/manage-guardrail-configs/) in the NVIDIA documentation.

## How it works

The AI NVIDIA NeMo Guardrail Policy intercepts traffic, extracts the text to evaluate, and calls the NeMo Guardrails `/v1/guardrail/checks` endpoint. NeMo returns a status for every rail it ran. If any rail reports a violation, {{site.ai_gateway}} blocks the request or response and returns a failure message to the client instead of the model output.

1. The Policy intercepts the request and sends the extracted text to the NeMo Guardrails microservice.
   - NeMo runs the configured input rails and returns a pass or block status.
1. If NeMo allows the content, {{site.ai_gateway}} forwards the request to the upstream model.
1. On the way back, the Policy intercepts the response and sends the extracted text to NeMo Guardrails.
   - NeMo runs the configured output rails and returns a pass or block status.
1. If NeMo allows the content, {{site.ai_gateway}} forwards the response to the client.

### Guarding mode

By default, the Policy checks requests only. Use [`config.guarding_mode`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-guarding-mode) to change which phases it inspects:

{% table %}
columns:
  - title: Value
    key: value
  - title: Description
    key: description
rows:
  - value: "`INPUT`"
    description: "Checks requests only. This is the default."
  - value: "`OUTPUT`"
    description: "Checks responses only."
  - value: "`BOTH`"
    description: "Checks both requests and responses."
{% endtable %}

To control which parts of the conversation the Policy sends for evaluation, use [`config.text_source`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-text-source). Set it to `concatenate_user_content` to check only `user` input, or `concatenate_all_content` to include the full exchange, including system and assistant messages.

{:.info}
> Match the rails defined in your NeMo guardrail configuration to the phases named in `config.guarding_mode`. A configuration used with `guarding_mode: INPUT` should define only an input rail; a configuration used with `guarding_mode: OUTPUT` should define only an output rail. NeMo evaluates whichever rails a configuration defines every time it's called, regardless of `guarding_mode`, so an output rail included in an input-only check runs against an empty response.

### Response buffering

[`config.response_buffer_size`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-response-buffer-size) controls how many bytes of a streamed upstream response {{site.ai_gateway}} buffers before sending them to NeMo Guardrails. The default is `100` bytes.

{:.info}
> A smaller buffer evaluates content sooner and rejects unsafe responses faster, but it increases the number of calls to the NeMo service. A larger buffer reduces calls at the cost of slower enforcement.

## Guardrail configuration modes

The [`config.guardrails`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-guardrails) field selects which NeMo guardrail configuration to apply. It supports three mutually exclusive modes, and you must provide exactly one of them.

### Reference a single stored configuration

Use `config_id` to reference a configuration that's already stored on the NeMo server:

{% entity_example %}
type: policy
data:
  display_name: AI NVIDIA NeMo Guardrail - Stored Configuration
  name: ai-nvidia-nemo-guardrail
  type: ai-nvidia-nemo-guardrail
  config:
    nemo_endpoint: http://nemo:7331/v1/guardrail/checks
    model: gpt-4o
    guarding_mode: INPUT
    timeout: 30000
    auth:
      api_key: ${api_key}
      header: X-Model-Authorization
      prefix: ""
    guardrails:
      config_id: content_safety
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

### Combine multiple stored configurations

Use `config_ids` to combine several stored configurations. NeMo applies them in the order you list them:

{% entity_example %}
type: policy
data:
  display_name: AI NVIDIA NeMo Guardrail - Combined Stored Configurations
  name: ai-nvidia-nemo-guardrail
  type: ai-nvidia-nemo-guardrail
  config:
    nemo_endpoint: http://nemo:7331/v1/guardrail/checks
    model: gpt-4o
    guarding_mode: BOTH
    timeout: 30000
    auth:
      api_key: ${api_key}
      header: X-Model-Authorization
      prefix: ""
    guardrails:
      config_ids:
        - content_safety
        - jailbreak_detection
        - topic_control
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

{:.info}
> Each configuration referenced in `config_ids` must define its own complete `models` list. NeMo does not merge model definitions across the configurations it combines, so a configuration that depends on a model defined only in a different, separately stored configuration won't resolve it when used this way.

### Send an inline configuration

Use `config` to send a complete NeMo guardrail configuration with every check, without storing anything on the NeMo server:

{% entity_example %}
type: policy
data:
  display_name: AI NVIDIA NeMo Guardrail - Inline Configuration
  name: ai-nvidia-nemo-guardrail
  type: ai-nvidia-nemo-guardrail
  config:
    nemo_endpoint: http://nemo:7331/v1/guardrail/checks
    model: gpt-5.1
    guarding_mode: INPUT
    timeout: 30000
    auth:
      api_key: ${api_key}
      header: X-Model-Authorization
      prefix: ""
    guardrails:
      config:
        models:
          - type: content_safety
            engine: openai
            model: gpt-5.1
        rails:
          input:
            flows:
              - content safety check input $model=content_safety
        prompts:
          - task: "content_safety_check_input $model=content_safety"
            models:
              - openai/gpt-5.1
            content: |
              Task: Check if there is unsafe content in the user message.
            output_parser: nemoguard_parse_prompt_safety
            max_tokens: 50
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

{:.warning}
> {{site.ai_gateway}} forwards the contents of `config.guardrails.config` to NeMo as-is and performs no validation on it. This keeps the Policy compatible with future NeMo releases, but it also means configuration errors surface only when NeMo rejects the check. NeMo returns the error message, and {{site.ai_gateway}} passes it to the client.

For the full set of supported keys, see the [NeMo Guardrails configuration reference](https://docs.nvidia.com/nemo/guardrails/configure-guardrails/configuration-reference) in the NVIDIA documentation.

{:.info}
> When you use an inline configuration, make sure the model you name in `guardrails.config.models` is available to the NeMo microservice. Depending on how you deploy NeMo, you might need to register it first with the `POST /v1/guardrail/models` endpoint. For more information, see [Manage models](https://docs.nvidia.com/nemo/microservices/latest/guardrails/manage-models.html) in the NVIDIA documentation.

## Authentication

The NeMo Guardrails microservice needs credentials for the LLM that evaluates your rails. Set the key in [`config.auth.api_key`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-auth-api-key), and {{site.ai_gateway}} forwards it to NeMo on every check.

Two fields control how {{site.ai_gateway}} builds the header:

* [`config.auth.header`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-auth-header): The header name. Defaults to `X-Model-Authorization`.
* [`config.auth.prefix`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-auth-prefix): The string prepended to the key. Defaults to `Bearer `.

{:.warning}
> **Do not** change `config.auth.header` unless your NeMo deployment expects a different header. The NeMo microservice reads `X-Model-Authorization` to resolve which LLM provider to use for the guardrail check. If the header is missing, NeMo falls back to its configured default provider, and your rails may run against a model you did not intend.

{:.warning}
> For a NeMo model configured with `engine: openai`, set `config.auth.prefix` to an empty string (`""`). NeMo passes the `X-Model-Authorization` header value straight to its OpenAI client as the API key, without stripping a `Bearer ` scheme from it first, so the default prefix becomes part of the credential and the check fails to authenticate.

`config.auth.api_key` is a [referenceable](/gateway/entities/vault/) and encrypted field, so you can store the value in a Vault instead of in your configuration.

## Blocking behavior

When NeMo reports a violation, {{site.ai_gateway}} blocks the content and returns a failure message. You can customize the messages for each phase:

* [`config.request_failure_message`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-request-failure-message): Returned when a request is blocked.
* [`config.response_failure_message`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-response-failure-message): Returned when a response is blocked.

Two other fields change how the Policy reacts:

* [`config.allow_masking`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-allow-masking): Masks violating content instead of blocking the request or response. Enabling this field disables streaming, because the Policy needs the complete payload to mask it.
* [`config.stop_on_error`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-stop-on-error): Controls what happens when the check itself fails, for example when the NeMo service is unreachable or [`config.timeout`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-timeout) expires. When enabled, which is the default, {{site.ai_gateway}} stops processing the request. Disable it to fail open and let traffic through unchecked.

{:.warning}
> Setting `stop_on_error: false` means an outage in the NeMo Guardrails service silently disables your safety rails. Only disable it when availability matters more than enforcement.

## TLS verification

[`config.ssl_verify`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-ssl-verify) is enabled by default, so the Policy verifies the TLS certificate of the NeMo Guardrails endpoint. To skip verification, for example when you run NeMo with a self-signed certificate in a development environment, set `ssl_verify: false`.

## Logging

The AI NVIDIA NeMo Guardrail Policy emits structured log data for every check it runs, under `ai.proxy.nvidia-nemo-guardrail` in the request log. For the full list of shared AI log fields, see the [{{site.ai_gateway}} audit log reference](/ai-gateway/ai-audit-log-reference/).

Fields available under `ai.proxy.nvidia-nemo-guardrail`:

* `mode`: The `config.guarding_mode` value in effect for the request (`INPUT`, `OUTPUT`, or `BOTH`).
* `input_block_reason` / `output_block_reason`: The name of the rail that blocked the content, for example `self check input`.
* `input_block_source` / `output_block_source`: The Policy that produced the block, for example `ai-nvidia-nemo-guardrail`.
* `input_block_consumer_id` / `output_block_consumer_id`: The consumer associated with the blocked request, or `unknown` if none is identified.
* `input_processing_latency` / `output_processing_latency`: Time in milliseconds spent on the NeMo check for that phase.
* `input_faulty_prompt` / `output_faulty_response`: The raw blocked content, populated only when `config.log_blocked_content` is enabled.

A blocked request or response also populates the shared `ai.proxy.guardrail_triggered` object, common across AI guardrail policies:

* `blocked_content`: The content that triggered the block.
* `block_source`: The Policy that produced the block.
* `block_direction`: `AI_GUARDRAIL_BLOCK_INPUT` or `AI_GUARDRAIL_BLOCK_OUTPUT`.

To log the raw content of blocked requests and responses, enable [`config.log_blocked_content`](/ai-gateway/policies/ai-nvidia-nemo-guardrail/reference/#schema--config-log-blocked-content). This field is disabled by default.

{:.warning}
> Blocked prompts and responses can contain sensitive or unsafe content. Enable `config.log_blocked_content` only when your logging pipeline is authorized to store that data.

## Forward proxy support

{% include md/ai-gateway/v2/forward-proxy.md %}
