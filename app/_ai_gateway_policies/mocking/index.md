---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Return responses from an OpenAPI spec instead of calling an AI Provider, so you can exercise an AI Gateway without spending tokens'
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
  - q: Does a mocked response still count against my AI Provider bill?
    a: No. The Mocking Policy answers the request before {{site.ai_gateway}} calls the AI Provider, so no upstream request is made and no tokens are spent.
  - q: Can I mock a streaming response?
    a: "No. A request with `stream: true` still receives the single non-streaming JSON response from the spec, sent with a `Content-Type` of `application/json` rather than as server-sent events."
---

The Mocking Policy allows you to provide mock endpoints to test APIs in development against your existing services and supports both Swagger 2.0 and OpenAPI 3.0. When it matches an incoming request against a path and method in the provided [`api_specification`](/ai-gateway/policies/mocking/reference/#schema--config-api-specification), it returns response examples and {{site.ai_gateway}} never contacts the upstream [AI Provider](/ai-gateway/entities/ai-provider/).

This lets you test an {{site.ai_gateway}}'s configuration against realistic responses without spending tokens. Attach the Policy to an [AI Model](/ai-gateway/entities/ai-model/) and give it an API specification describing that AI Model's route, for example `POST /v1/chat/completions` with a provider-shaped response example. This allows you to test rate limits, metering, logging, and other AI Policies without a real AI Provider behind them.

Mocked responses carry an `X-Kong-Mocking-Plugin: true` response header, so a client can tell a mock from a real completion.

## Supported status codes

The Mocking Policy can return `200`, `201`, and `204`.

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

### Mock responses

If you attach a Mocking Policy to an [AI Model](/ai-gateway/entities/ai-model/)'s `policies` array, a request to that AI Model's route returns the example verbatim. 

For the example above:

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

Downstream AI Policies see the mocked response. Including a `usage` block gives metering and logging realistic token counts to work with.

### Path matching

By default the Policy matches spec paths against the full request path and ignores any base path in the spec's `servers` entry. A spec with `servers: [{url: https://api.example.com/v1}]` and a path of `/chat/completions` therefore doesn't match a request to `/v1/chat/completions`, and the Policy returns a `404`:

```json
{"message":"Corresponding path and method spec does not exist in API Specification"}
```

Either write the spec paths out in full, or set [`config.include_base_path`](./reference/#schema--config-include-base-path) to `true` so the Policy prepends the base path before matching. To match against a base path other than the spec's own, set [`config.custom_base_path`](./reference/#schema--config-custom-base-path) as well.

## Behavioral headers

Behavioral headers change the Mocking Policy's behavior for a single request without changing its configuration.

### X-Kong-Mocking-Delay

`X-Kong-Mocking-Delay` sets how many milliseconds the Policy waits before responding. The value must be a number between `0` and `10000`, inclusive. Anything else returns a `400`:

```json
{"message":"Invalid value for X-Kong-Mocking-Delay. The delay value should be a number between 0 and 10000"}
```

This header takes precedence over [`config.random_delay`](./reference/#schema--config-random-delay).

### X-Kong-Mocking-Example-Id

`X-Kong-Mocking-Example-Id` selects which response example to return when the matched status code has more than one. OpenAPI 3.0 lets you define multiple examples under a single MIME type, so the following fragment offers two candidates, `User1` and `User2`:

```yaml
paths:
  /query_user:
    get:
      responses:
        '200':
          description: A user object.
          content:
            application/json:
              examples:
                User1:
                  value:
                    id: 10
                    name: User1
                User2:
                  value:
                    id: 20
                    name: User2
```

Sending `X-Kong-Mocking-Example-Id: User2` returns the second example. An ID that isn't in the spec, such as `User3`, returns a `400`:

```json
{"message":"could not find the example id 'User3'"}
```

{:.info}
> When an operation defines several examples for the same status code and the request doesn't name one, the Policy's choice isn't deterministic: identical requests can return different examples even with [`config.random_examples`](./reference/#schema--config-random-examples) left at its `false` default. Send `X-Kong-Mocking-Example-Id` whenever a caller needs a specific example, such as in an automated test.

### X-Kong-Mocking-Status-Code

`X-Kong-Mocking-Status-Code` overrides the default status code selection. The status code you ask for has to be defined for the matched operation, otherwise the Policy returns a `400`:

```json
{"message":"could not find the status code '201'"}
```

## Simulate a slow AI Provider

Set [`config.random_delay`](./reference/#schema--config-random-delay) to `true` to delay every mocked response by a random amount, then bound it with [`config.min_delay_time`](./reference/#schema--config-min-delay-time) and [`config.max_delay_time`](./reference/#schema--config-max-delay-time). This is a useful stand-in for inference latency when you're testing client timeouts.

{:.info}
> `min_delay_time` and `max_delay_time` are in **seconds**, while the `X-Kong-Mocking-Delay` header is in **milliseconds**. A `max_delay_time` of `4` is a four second delay, not four milliseconds.

<!-- TODO: add an entity_example combining random_delay with random_status_code and
     random_examples once this page carries a spec with several status codes to pick from.
     All three are verified working; notes in .idea/mocking-notes.md. -->

