---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
tags:
  - security

related_resources:
  - text: AI Prompt Guard
    url: /ai-gateway/policies/ai-prompt-guard/
  - text: AI Rate Limiting Advanced
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
  - text: Security Policies
    url: /ai-gateway/policies/?category=security
---

The JSON Threat Protection Policy validates and protects against malicious or overly complex JSON payloads on {{site.ai_gateway}} traffic. This includes JSON-based injection attacks, oversized payload attacks, and malformed JSON leading to application crashes.

Enabling this Policy is recommended for any [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) that accepts JSON-RPC input from MCP clients, especially ones exposing tools with attacker-controllable parameters or handling untrusted upstream responses.

{:.info}
> This Policy validates generic JSON structure rather than any LLM-specific format. That's why it applies to [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) traffic, which is JSON-RPC over HTTP, essentially API traffic. It doesn't currently apply to [AI Model](/ai-gateway/entities/ai-model/) traffic, which is processed through a separate LLM-specific pipeline.

## Use cases

The following are examples of common configurations for the JSON Threat Protection Policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: Block invalid requests
    description: |
      Define a JSON threat protection policy and block any invalid requests.
      If a request doesn't conform to the configured policy, the AI Policy blocks it from being proxied and returns an error.
  - usecase: Log invalid requests without blocking
    description: |
      Run the Policy in tap mode, which logs non-conforming requests while still letting them pass through the proxy.
  - usecase: Allow non-JSON requests
    description: Block invalid JSON requests and let non-JSON requests pass through.
{% endtable %}
<!--vale on-->

## How it works

The JSON Threat Protection Policy validates incoming requests with a JSON body against policy limits that you've configured, regardless of whether the `Content-Type` header exists or is set to `application/json`. If a request violates the policy limits, you can configure it to either block the request (block mode) or monitor and log it (tap mode).

The Policy validates the JSON body of incoming `POST`, `PUT`, and `PATCH` requests. Other HTTP methods aren't validated.

The Policy checks the following limits:

- Maximum container depth of the entire JSON object.
- Maximum number of array elements.
- Maximum number of object entries.
- Maximum length of object keys.
- Maximum length of strings.

Additionally, you can set a policy that restricts the JSON body size ([`config.max_body_size`](./reference/#schema--config-max-body-size)). When this is configured, the Policy compares the `Content-Length` header with `max_body_size`. In block mode, if the `Content-Length` header is missing or its value exceeds `max_body_size`, the request is terminated. In tap mode, only the body size is checked and logs are recorded.

{:.info}
> **Notes**:
> * Length calculation for JSON strings and object entry names is based on UTF-8 characters, not bytes.
> * `max_body_size` and `nginx_http_client_max_body_size` are independent of each other. Therefore, if `nginx_http_client_max_body_size` is set to a larger value while `max_body_size` is smaller and block mode is enabled, any request with a body size greater than `max_body_size` but less than `nginx_http_client_max_body_size` is terminated.
> * This Policy doesn't support chunked encoding.

### Example JSON body violation

Consider an AI MCP Server that exposes a `draw-cards` tool, where `deck_id` is expected to be a short identifier returned by an earlier `shuffle-cards` call, such as `t8952axdsfat`. A well-behaved `tools/call` request looks like this:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "draw-cards",
    "arguments": {
      "path_deck_id": "t8952axdsfat",
      "query_count": 1
    }
  }
}
```

A client attempting to abuse the `path_deck_id` argument, for example to probe for buffer or parsing issues in an upstream integration, might substitute an oversized value instead:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "draw-cards",
    "arguments": {
      "path_deck_id": "deck-id-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "query_count": 1
    }
  }
}
```

With [`config.max_string_value_length`](./reference/#schema--config-max-string-value-length) set to 40, the Policy rejects the second request with a 400 response, and logs an entry similar to:

```text
[json-threat-protection] JSON validate failed: at [$.params.arguments.path_deck_id]: The maximum length allowed for a string value is exceeded.
```

The Policy checks every string, array, and object in the request body this way, regardless of which tool or argument name it appears under.

{:.warning}
> The MCP handshake itself has a fixed shape you don't control. The `initialize` request's `params` object always includes a `protocolVersion` key, which is 15 characters long. If [`config.max_object_entry_name_length`](./reference/#schema--config-max-object-entry-name-length) is set below 16, the Policy rejects every `initialize` request and no client can complete the handshake.

## Log JSON request body violations

In tap mode, if the Policy detects violations in the JSON request body, it logs a warning and proxies the request to the upstream service instead of blocking the request. In other words, in tap mode, the Policy only monitors the traffic.

To enable tap mode, set [`config.enforcement_mode`](./reference/#schema--config-enforcement-mode) to `log_only`.
