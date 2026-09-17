---
title: 'AI Prompt Compressor v2'
name: 'AI Prompt Compressor v2'
publisher: kong-inc
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Compress LLM request content through a single configurable compression provider, including a Headroom sidecar, to cut token costs and reduce latency.'
categories:
  - ai
tags:
  - ai
  - performance
search_aliases:
  - ai-prompt-compressor-v2
  - headroom

related_resources:
  - text: AI Prompt Compressor Policy (v1)
    url: /ai-gateway/policies/ai-prompt-compressor/
  - text: AI RAG Injector Policy
    url: /ai-gateway/policies/ai-rag-injector/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: Forward proxy support
    url: /ai-gateway/forward-proxy/
---

The AI Prompt Compressor v2 Policy compresses LLM request content through a single
compression provider you choose before the request reaches the upstream LLM. It's a separate Policy from
[AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/), not a replacement or an
in-place upgrade: the two install side by side, and configuration doesn't migrate
automatically between them.

The Policy ships with two providers, configured under `config.providers[]`:

* **`kong`**: the same Kong compressor service backend that [AI Prompt Compressor
  Policy](/ai-gateway/policies/ai-prompt-compressor/) uses, with the same fields, now nested
  under `config.providers[].kong`.
* **`headroom`**: a call to a [Headroom](https://github.com/headroomlabs-ai/headroom)
  sidecar's `/v1/compress` endpoint.

Only one provider entry is accepted per Policy instance today. Configuring more than one under
`config.providers[]` fails validation.

## The `kong` provider

The `kong` provider uses the same [AI Prompt Compression
Service](/ai-gateway/policies/ai-prompt-compressor/#ai-prompt-compression-service) and
[LLMLingua 2](https://github.com/microsoft/LLMLingua)-based compression as the v1 Policy. See
that page for the Docker image, its environment variables, and its REST/JSON-RPC endpoints.
The following fields configure it here, nested under `config.providers[].kong`:

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`compressor_url`"
    description: |
      The URL of the compressor service.
  - field: "`compressor_type`"
    description: |
      What compression type to use: `rate` (compress to a percentage of the original length) or `target_token` (compress to a fixed token count).
  - field: "`compression_ranges`"
    description: |
      An array of `{min_tokens, max_tokens, value}` records. `value` is interpreted as a rate or a target token count depending on `compressor_type`.
  - field: "`message_type`"
    description: |
      Which message roles to compress: `system`, `assistant`, `user`. Defaults to `user`.
  - field: "`timeout`"
    description: |
      Connection timeout with the compressor service, in milliseconds.
  - field: "`keepalive_timeout`"
    description: |
      Keepalive timeout for the established HTTP connection to the compressor service, in milliseconds.
  - field: "`stop_on_error`"
    description: |
      Whether to stop processing the request if the compressor service call fails. Defaults to `true`.
  - field: "`log_text_data`"
    description: |
      Whether to log the original and compressed text in analytics. Defaults to `false`.
{% endtable %}
<!-- vale on -->

## The `headroom` provider

[Headroom](https://github.com/headroomlabs-ai/headroom) is a local-first compression sidecar.
The Policy calls its direct `POST /v1/compress` API with the request's `messages` array and
replaces the content with what Headroom returns.

### Deployment and trust model

Headroom is loopback-trust by default: it answers unauthenticated calls on `127.0.0.1`, and
returns `404` to non-loopback callers unless it's started with
`HEADROOM_COMPRESS_ALLOW_REMOTE=1`. Run Headroom as a co-located sidecar reachable only from
the {{site.ai_gateway}} data plane (the recommended, default topology), or point the Policy at
a remote instance and set `config.providers[].headroom.proxy_token`, sent as both the
`X-Headroom-Proxy-Token` and `Authorization: Bearer` headers.

Headroom sessions are held in memory on a single Headroom process. Point every data plane node
at its own sidecar, or all of them at one shared instance. Never point them at a load-balanced
set of Headroom instances, since a session's turns must all reach the same process.

### Session-based cache replay

The Policy derives one session id per conversation from `session_id_headers` (or, if none of
those headers are present on the request, from the model name, the leading system prompt, and
the first user message) and sends it to Headroom as `config.session_id`. Headroom uses this to
replay an already-compressed prefix byte-for-byte on later turns, which keeps the upstream
LLM provider's own prompt cache hitting through the compressor. This requires **Headroom
v0.37.0 or newer**: older images silently ignore `session_id` and run stateless.

### Request format support

The Policy compresses an OpenAI-shaped `messages` array, and also compresses a **native
Anthropic** request body directly (not just an OpenAI-compatible one), which is what makes it
useful in front of a coding agent that speaks Anthropic's API natively. A request with no
`messages` array (for example a completions-style `prompt` body, or a Responses API `input`
list) isn't supported and is forwarded unchanged.

### Failure behavior

`stop_on_error` **defaults to `true`**: if the call to Headroom fails, times out, or returns an
error, the Policy returns an HTTP `500` to the client rather than forwarding the request
uncompressed. Set `stop_on_error` to `false` to fail open instead: the original, uncompressed
request is forwarded and the failure is logged.

A `503` response with `compression_timeout` is retried automatically before the Policy gives
up; every other non-`200` response (for example a `400` from a bad config, or a `401` from a
missing or incorrect `proxy_token`) fails immediately.

### Fields

<!-- vale off -->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`endpoint`"
    description: |
      The Headroom `/v1/compress` endpoint. Defaults to `http://127.0.0.1:8787/v1/compress`.
  - field: "`proxy_token`"
    description: |
      Optional bearer token, required only when `endpoint` is not a loopback address. Referenceable as a secret.
  - field: "`timeout`"
    description: |
      Request timeout to Headroom, in milliseconds. Defaults to `60000`.
  - field: "`stop_on_error`"
    description: |
      Whether a failed Headroom call fails the request (`true`, the default) or forwards the original content unchanged (`false`).
  - field: "`ssl_verify`"
    description: |
      Whether to verify the TLS certificate of the Headroom endpoint, for `https` endpoints. Defaults to `true`.
  - field: "`use_forward_proxy`"
    description: |
      Whether outbound calls to Headroom use the Policy's `proxy_config` forward proxy: `auto` (the default, only for a non-loopback endpoint), `always`, or `never`.
  - field: "`session_id_headers`"
    description: |
      Request header names used to derive the conversation's session id, concatenated in order. Defaults to a set of common coding-agent session headers.
{% endtable %}
<!-- vale on -->

### What this doesn't do yet

* No content-retrieval mechanism: Headroom's compress-cache-retrieve (CCR) hashes aren't
  stored or resolved by this Policy.
* No `target_ratio` or `protect_recent` tuning fields: Headroom's own defaults apply.
* No MCP tool-response compression: only the LLM request path is supported.

## Forward proxy

`config.proxy_config` configures a forward proxy for outbound calls to either provider (the
compressor service for the `kong` provider, or Headroom for the `headroom` provider): flat
fields (`http_proxy_host`, `http_proxy_port`, `https_proxy_host`, `https_proxy_port`,
`proxy_scheme` (`http` only), `auth_username`, `auth_password`, and `no_proxy`) rather than the
unified `proxy` record used by AI Model and MCP Server entities. For the `headroom` provider,
`use_forward_proxy` controls when this proxy is actually used, since a loopback sidecar should
usually bypass it. See [Forward proxy support](/ai-gateway/forward-proxy/) for the broader
{{site.ai_gateway}} forward-proxy model.
