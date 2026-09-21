---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
related_resources:
  - text: OAS Validation Policy
    url: /ai-gateway/policies/oas-validation/
  - text: WebSocket Validator Policy
    url: /ai-gateway/policies/websocket-validator/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
---

The Request Validator Policy validates incoming requests against a schema you define, and rejects any request that doesn't conform with a `400 Bad Request` response before it reaches the upstream service. Use it to enforce a request shape at the {{site.ai_gateway}} layer instead of relying on the upstream service to reject malformed input itself.

You can validate:

* The request body, using [`config.body_schema`](./reference/#schema--config-body-schema).
* Path, query, and header parameters, using [`config.parameter_schema`](./reference/#schema--config-parameter-schema).

At least one of `body_schema` or `parameter_schema` must be set.

## How it works

[`config.version`](./reference/#schema--config-version) selects which validator evaluates your schema:

* `kong` (the default): Kong's own schema format. See [Schema format](#schema-format).
* `draft4`, `draft6`, `draft7`, `draft201909`, or `draft202012`: the matching JSON Schema Draft-compliant validator.

By default, a failed validation returns a generic `400 Bad Request`. Enable [`config.verbose_response`](./reference/#schema--config-verbose-response) to have the response name the specific field that failed instead.

The Policy also restricts which `Content-Type` values it accepts, using [`config.allowed_content_types`](./reference/#schema--config-allowed-content-types) (default `application/json`). A request with a `Content-Type` that isn't in this list is rejected with `400 Bad Request` and `{"message":"specified Content-Type is not allowed"}`, regardless of whether the body itself would otherwise have passed schema validation. Use [`config.content_type_parameter_validation`](./reference/#schema--config-content-type-parameter-validation) to control whether `Content-Type` parameters (like `; charset=UTF-8`) are also validated.

### Schema format

When `config.version` is `kong` (the default), `config.body_schema` is a JSON-encoded array of single-key field definitions, using Kong's own schema types rather than plain JSON Schema:

* `array` requires an `elements` sub-schema describing each item's type.
* `record` requires a `fields` array of single-key `{field_name: {type: ...}}` objects, describing an object's shape.
* `map` requires `keys` and `values` sub-schemas.

See [Validate an LLM chat request body](#validate-an-llm-chat-request-body) for an example that combines `array` and `record`.

## Example: Validate an LLM chat request body

A common use for this Policy in {{site.ai_gateway}} is enforcing that a chat completion request has the shape an AI Model expects before {{site.ai_gateway}} forwards it upstream. This rejects a malformed request at the gateway instead of letting it fail against the AI Model Provider:

{% entity_example %}
type: policy
data:
  display_name: my-request-validator
  name: my-request-validator
  type: request-validator
  enabled: true
  global: false
  config:
    version: kong
    body_schema: '[{"model":{"type":"string","required":true}},{"messages":{"type":"array","required":true,"elements":{"type":"record","fields":[{"role":{"type":"string","required":true}},{"content":{"type":"string","required":true}}]}}}]'
formats:
  - kongctl
{% endentity_example %}

This requires the request body to contain both a `model` field (a string) and a `messages` field (an array of `{role, content}` records): the two fields every OpenAI-format chat completion request needs. A request missing either field is rejected with `400 Bad Request` before it ever reaches the AI Model's upstream target. A request with both fields passes through unchanged.
