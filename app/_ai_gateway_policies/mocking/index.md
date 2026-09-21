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

The Mocking Policy answers requests from an OpenAPI Specification (OAS) instead of proxying them, and supports both Swagger 2.0 and OpenAPI 3.0. When it matches an incoming request against a path and method in the spec you give it, it returns one of that operation's response examples and {{site.ai_gateway}} never contacts the upstream [AI Provider](/ai-gateway/entities/ai-provider/).

In an {{site.ai_gateway}} context, this lets you exercise a gateway's configuration against realistic responses without spending tokens. Attach the Policy to an [AI Model](/ai-gateway/entities/ai-model/) and give it a spec describing that AI Model's own route, for example `POST /v1/chat/completions` with a provider-shaped response example. Every call to the AI Model then returns your example, so you can drive rate limits, metering, logging, and other AI Policies without a real AI Provider behind them.

Mocked responses carry an `X-Kong-Mocking-Plugin: true` response header, so a client can tell a mock from a real completion.

{:.warning}
> The Mocking Policy intercepts the request a client sends to {{site.ai_gateway}}, not the call {{site.ai_gateway}} makes upstream. It can't stand in for the REST API that an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) fronts: attached to an AI MCP Server, it short-circuits the JSON-RPC endpoint itself, and MCP clients fail on `tools/list` because a JSON-RPC `POST` doesn't match any path in the spec.

<!-- TODO: link a how-to here once one exists. Nothing under app/_how-tos/ai-gateway/ covers
     mocking yet. -->

## Use cases

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: Exercise gateway config without spending tokens
    description: |
      Return canned completions in place of real AI Provider calls while you test
      rate limiting, metering, logging, and guardrail AI Policies.
  - usecase: Unblock client development
    description: |
      Give application teams a working endpoint with provider-shaped responses before
      AI Provider credentials or model access are in place.
  - usecase: Simulate a slow AI Provider
    description: |
      Add a fixed or random delay to mocked responses to see how a client behaves
      when inference takes seconds rather than milliseconds.
{% endtable %}
<!--vale on-->

## Supported status codes

The Mocking Policy can return `200`, `201`, and `204`.

<!-- TODO: VERIFY the 200/201/204 limit. Carried over from the v1 plugin page; only 200 was
     exercised in testing, and the schema doesn't state the restriction anywhere.
     "lowest status code by default" is schema-backed (see config.random_status_code) but also
     untested. Notes: .idea/mocking-notes.md -->

By default it returns the lowest status code defined for the matched operation. You can restrict the set it's allowed to pick from with [`config.included_status_codes`](./reference/#schema--config-included-status-codes), or have it choose at random from the operation's responses with [`config.random_status_code`](./reference/#schema--config-random-status-code).

## Load an API specification

{{site.ai_gateway}} 2.0 runs in hybrid mode, so pass the contents of the spec inline in [`config.api_specification`](./reference/#schema--config-api-specification):

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

Attach this Policy to an [AI Model](/ai-gateway/entities/ai-model/)'s `policies` array. A request to that AI Model's route then returns the example verbatim:

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

Because the example is returned verbatim, whatever you put in it is what downstream AI Policies see. Including a `usage` block gives metering and logging realistic token counts to work with.

{:.warning}
> Use `config.api_specification`, not `config.api_specification_filename`. The `api_specification_filename` option loads a spec from a database, and {{site.ai_gateway}} has none, so the control plane accepts the configuration but every request to it fails with a `500` and the message `The api_specification_filename is not supported in dbless mode, use api_specification instead`.

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

