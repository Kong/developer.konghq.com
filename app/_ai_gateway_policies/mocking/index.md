---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Return responses from an OpenAPI spec instead of calling an AI Model Provider, so you can exercise {{site.ai_gateway}} without spending tokens'
tags:
  - mock-servers
search_aliases:
  - API mocking
related_resources:
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Semantic Cache Policy
    url: /ai-gateway/policies/ai-semantic-cache/
  - text: AI Rate Limiting Advanced Policy
    url: /ai-gateway/policies/ai-rate-limiting-advanced/
faqs:
  - q: Does a mocked response still count against my AI Model Provider bill?
    a: No. {{site.ai_gateway}} answers from your API specification and never contacts the AI Model Provider, so there are no tokens to bill.
  - q: Can I mock a streaming response?
    a: |
      No. Even if the client sets `stream: true`, the Mocking Policy returns the whole example from your API specification in a single response instead of streaming it in pieces.

      If the client sends `Accept: text/event-stream` and the spec only defines `application/json`, no media type matches and the Policy returns a `404` with the message `No examples exist in API specification for this resource matching Accept Header (text/event-stream)`.
---

The Mocking Policy allows you to provide mock endpoints to test APIs in development against your existing services. You provide an [`api_specification`](/ai-gateway/policies/mocking/reference/#schema--config-api-specification) with either Swagger 2.0 or OpenAPI 3.0. When the Mocking Policy matches an incoming request against a path and method defined in the spec, it returns response examples. When using the Mocking Policy, {{site.ai_gateway}} never contacts the upstream [AI Model Provider](/ai-gateway/entities/ai-model-provider/).

The Policy lets you test an {{site.ai_gateway}}'s configuration against realistic responses without spending tokens. You can attach the Policy to an [AI Model](/ai-gateway/entities/ai-model/) and give it an API specification describing that AI Model's route, for example `POST /v1/chat/completions` with a provider-shaped response example. The Policy matches the full request path, so the spec path must include the AI Model's route path. You can also attach the Policy to an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), an [AI Agent](/ai-gateway/entities/ai-agent/), or an [AI Consumer](/ai-gateway/entities/ai-consumer/), or apply it globally.

Mocked responses carry an `X-Kong-Mocking-Plugin: true` response header, so a client can tell a mock from a real completion.

## Supported status codes

The Policy can return any status code defined for the matched operation in the API specification, including error codes such as `429` or `500`. Mocking error responses is a useful way to test how a client handles AI Model Provider failures. By default, the Policy returns the lowest status code defined for the operation.

You can restrict the allowed status codes with [`config.included_status_codes`](./reference/#schema--config-included-status-codes), or select them randomly with [`config.random_status_code`](./reference/#schema--config-random-status-code).

## Load an API specification

You can pass a specification inline using [`config.api_specification`](./reference/#schema--config-api-specification):

{% entity_example %}
type: policy
data:
  display_name: Mock chat completions
  name: mock-chat-completions
  type: mocking
  enabled: true
  global: false
  config:
    api_specification: |
      openapi: 3.0.0
      info:
        title: Mock chat completions
        version: 1.0.0
      paths:
        /v1/chat/completions:
          post:
            responses:
              '200':
                description: A chat completion.
                content:
                  application/json:
                    examples:
                      Hello:
                        value:
                          id: chatcmpl-mock-1
                          object: chat.completion
                          model: my-gpt-4o
                          choices:
                            - index: 0
                              finish_reason: stop
                              message:
                                role: assistant
                                content: "This is a mocked response."
                          usage:
                            prompt_tokens: 9
                            completion_tokens: 6
                            total_tokens: 15
formats:
  - kongctl
{% endentity_example %}

## Mock responses

If you attach a Mocking Policy to an [AI Model](/ai-gateway/entities/ai-model/)'s `policies` array, a request to that AI Model's route returns the example verbatim.

For the example in [Load an API specification](#load-an-api-specification), the response looks similar to the following:

```json
{
  "choices": [
    {
      "finish_reason": "stop",
      "index": 0,
      "message": { "content": "This is a mocked response.", "role": "assistant" }
    }
  ],
  "usage": { "prompt_tokens": 9, "completion_tokens": 6, "total_tokens": 15 },
  "model": "my-gpt-4o",
  "id": "chatcmpl-mock-1",
  "object": "chat.completion"
}
```

### Interaction with other AI Policies

The Mocking Policy runs last in the request phase and returns the response itself, so the request never reaches the AI Model Provider. Policies that act on the request run first and still apply. For example:

* Authentication and ACLs can reject the request before it reaches the mock.
* Request guardrails can block a prompt.
* AI Rate Limiting Advanced can reject a request that's over its limit.
* An AI Semantic Cache hit returns the cached response instead of the mock.

{{site.ai_gateway}} only processes responses that come from the AI Model Provider, so it skips mocked responses. As a result:

* Token usage isn't recorded, even if the example includes a `usage` block. Token-based rate limits and metering don't count mocked requests.
* Response guardrails and response transformations don't run on the mocked response.
* AI Semantic Cache doesn't store the mocked response.

### Path matching

By default the Policy matches against the full request path and ignores any base path in the API specification's `servers` entry. A specification with `servers: [{url: https://api.example.com/v1}]` and a path of `/chat/completions` therefore doesn't match a request to `/v1/chat/completions`, and the Policy returns a `404`:

```json
{"message":"Corresponding path and method spec does not exist in API Specification"}
```

Optionally, you can set [`config.include_base_path`](./reference/#schema--config-include-base-path) to `true` so the Policy prepends the base path before matching. To match against a base path other than the one provided in the API specification, set [`config.custom_base_path`](./reference/#schema--config-custom-base-path). The Policy ignores `custom_base_path` unless `include_base_path` is `true`.

## Behavioral headers

Behavioral headers change the Mocking Policy's behavior for a single request without changing its configuration.

### X-Kong-Mocking-Delay

`X-Kong-Mocking-Delay` sets how many milliseconds the AI Policy waits before responding. The value must be a number between `0` and `10000`, inclusive. Any other value returns a `400`.

This header takes precedence over [`config.random_delay`](./reference/#schema--config-random-delay).

### X-Kong-Mocking-Example-Id

`X-Kong-Mocking-Example-Id` selects which response example to return by its key in the OpenAPI 3.0 `examples` map. If no example has that key, the AI Policy returns a `400`.

The header only applies to `examples`. The Policy ignores it when the response defines a single `example`, or when the API specification uses Swagger 2.0.

{:.info}
> When an operation defines several examples with the same status code and the request doesn't name one, the AI Policy's choice isn't deterministic. Identical requests can return different examples even if [`config.random_examples`](./reference/#schema--config-random-examples) is `false`. Send `X-Kong-Mocking-Example-Id` whenever a caller needs a specific example, such as in an automated test.

### X-Kong-Mocking-Status-Code

`X-Kong-Mocking-Status-Code` overrides the default status code selection. The status code you ask for must be defined for the matched operation, otherwise the AI Policy returns a `400`.

## Simulate a slow AI Model Provider

Set [`config.random_delay`](./reference/#schema--config-random-delay) to `true` to delay every mocked response by a random amount, then bound it with [`config.min_delay_time`](./reference/#schema--config-min-delay-time) and [`config.max_delay_time`](./reference/#schema--config-max-delay-time). This is a useful stand-in for inference latency when you're testing client timeouts.

{:.info}
> `min_delay_time` and `max_delay_time` are in **seconds**, while the `X-Kong-Mocking-Delay` header is in **milliseconds**. A `max_delay_time` of `4` is a four second delay, not four milliseconds.