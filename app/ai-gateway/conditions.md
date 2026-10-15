---
title: AI Policy conditions
content_type: reference
layout: reference
description: Reference for the `condition` field, which lets an AI Policy run only when a CEL expression matches the request.
products:
  - ai-gateway
min_version:
  ai-gateway: '2.1'
related_resources:
  - text: AI Policies
    url: /ai-gateway/entities/ai-policy/
  - text: AI Policy priority
    url: /ai-gateway/entities/ai-policy/#ai-policy-priority
  - text: Plugin conditions in {{site.base_gateway}}
    url: /gateway/plugins/conditions/
  - text: CEL expressions for plugins
    url: /gateway/plugins/expressions/
---

AI Policy conditions let you attach an optional `condition` expression to any AI Policy.
When a request comes in, {{site.ai_gateway}} evaluates the expression before the AI Policy runs.
If the expression evaluates to `true`, the AI Policy runs normally.
If it evaluates to `false`, {{site.ai_gateway}} skips the AI Policy for that request and processes the request as if the AI Policy weren't attached.
If you don't set a condition, the AI Policy always runs.

Conditions use [Common Expression Language (CEL)](https://cel.dev/), a lightweight expression language.

Common use cases for conditions include:

* Apply an AI Policy to only part of your traffic, such as callers who send a specific header or query parameter.
* Skip a global AI Policy for specific paths or hosts without removing it or duplicating it on individual entities.
* Enforce an AI Policy only for specific HTTP methods.
* Make one AI Policy's execution depend on a value that a higher-priority [Pre-Function Policy](/ai-gateway/policies/pre-function/) sets in `kong.ctx.shared`.

## Write a condition

The following condition runs an AI Policy only when the request includes the header `x-tier: premium`:

```yaml
condition: 'http.headers.x_tier == "premium"'
```

In the {{site.konnect_short_name}} UI, enter the expression in the **Execution condition** field, in the **General information** step of the AI Policy form:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.ai_gateway}}**.
1. Click the **Policies** tab.
1. Click **New policy**.
1. In the **Execution condition** field, enter `http.headers.x_tier == "premium"`.

For the condition `http.headers.x_tier == "premium"`:
* A request with the header `x-tier: premium` matches, so the AI Policy runs.
* A request with `x-tier: free`, any other value, or no `x-tier` header doesn't match, so {{site.ai_gateway}} skips the AI Policy.

In the expression, write header names in lowercase with underscores in place of hyphens, so `x-tier` becomes `x_tier`.
{{site.ai_gateway}} rejects an expression that uses a hyphen, such as `http.headers.x-tier`, when you save the AI Policy.

## How it works

When {{site.ai_gateway}} receives a request, it determines which AI Policies apply according to [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).
For each AI Policy that has a `condition` set, {{site.ai_gateway}} evaluates the expression before that AI Policy runs.

Unlike scopes, which determine which AI Policies can apply to a request, conditions are evaluated per request, per AI Policy.

When a condition evaluates to `false`, {{site.ai_gateway}} skips the AI Policy in every phase of the request.

{{site.ai_gateway}} evaluates a condition after it applies scope precedence.
When AI Policies of the same type apply at more than one scope, only the most specific one is considered, and its condition then decides whether it runs.
If that condition is `false`, {{site.ai_gateway}} skips the AI Policy and doesn't fall back to a less specific AI Policy of the same type.

## Performance considerations

{{site.ai_gateway}} evaluates a condition on every request for each conditioned AI Policy.
Scopes need only a configuration lookup, so conditions add more work to each request.
Where possible, use scopes to control which AI Policies apply, and use conditions for request-level decisions.

When you use conditions, keep the following in mind:

* {{site.ai_gateway}} loads an AI Policy's configuration, including its secret references, even when its condition evaluates to `false`.
* Complex compound expressions with many fields are more expensive to evaluate than simple expressions with a single field.

## Limitations

* Conditions apply to HTTP, HTTPS, and WebSocket (`ws` and `wss`) traffic. They aren't supported on stream (TCP, TLS, and UDP) traffic.
* A condition must evaluate to a boolean. {{site.ai_gateway}} rejects any other result when you save the AI Policy.
* A condition can be up to 1024 characters long. {{site.ai_gateway}} rejects longer expressions when you save the AI Policy with `maximum string length is 1024`.
* Conditions require {{site.ai_gateway}} 2.1 or later.

## Condition expressions reference

A condition expression is a string assigned to the `condition` field of an AI Policy.
The language is CEL, with the same fields and operators as {{site.base_gateway}} plugin conditions, except for the differences listed in [Differences from {{site.base_gateway}} plugin conditions](#differences-from-kong-gateway-plugin-conditions).
{{site.ai_gateway}} validates the expression when you save the AI Policy.

### Expression syntax

A predicate is the basic unit of an expression and compares a field against a value:

```sh
http.method == "GET"
```

<!--vale off-->
{% table %}
columns:
  - title: Object
    key: object
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - object: Field
    description: |
      A value extracted from the incoming request or the {{site.ai_gateway}} context.
      An absent field may return `null` or cause a runtime error depending on the field type. See [Null handling](#null-handling).
    example: "`http.method`"
  - object: Value
    description: |
      The value the field is compared against. Can be a constant (`string`, `int`, `bool`, `null`) or another field.
      The value can appear on either side of the predicate.
    example: '`"GET"`'
  - object: Operator
    description: "Defines the comparison to perform between the field and the value."
    example: "`==`"
  - object: Predicate
    description: "Compares a field against a value using the given operator. Returns `true` if the comparison passes, `false` if it doesn't."
    example: '`http.method == "GET"`'
{% endtable %}
<!--vale on-->

### Combining predicates

<!--vale off-->
{% table %}
columns:
  - title: Operator
    key: operator
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - operator: "`&&`"
    description: "Logical AND. True if both sides are true."
    example: '`http.method == "POST" && http.headers.x_tier == "premium"`'
  - operator: "`||`"
    description: "Logical OR. True if either side is true."
    example: '`http.method == "GET" || http.method == "POST"`'
  - operator: "`!`"
    description: "Logical NOT. Inverts the result."
    example: '`!(http.method == "DELETE")`'
  - operator: "`()`"
    description: "Parentheses. Control evaluation order."
    example: '`(http.method == "GET" || http.method == "POST") && http.headers.x_tier == "premium"`'
{% endtable %}
<!--vale on-->

### Available fields

AI Policy conditions support HTTP request fields and context fields.
For fields that you shouldn't use in AI Policy conditions, see [Fields to avoid](#fields-to-avoid).

#### HTTP request fields

These fields reflect the state of the incoming HTTP request at the time the expression is evaluated.
Higher-priority AI Policies can modify these values before {{site.ai_gateway}} evaluates the expression.

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - field: "`http.method`"
    type: "`string`"
    description: 'The HTTP method of the incoming request, for example `"GET"` or `"POST"`.'
    example: '`http.method == "POST"`'
  - field: "`http.host`"
    type: "`string`"
    description: "The `Host` header of the incoming request."
    example: '`http.host == "internal.example.com"`'
  - field: "`http.path`"
    type: "`string`"
    description: "The normalized request path, without query parameters."
    example: '`http.path.startsWith("/api/v2")`'
  - field: "`http.path_segments`"
    type: "`list<string>`"
    description: |
      The path split on `/`, with empty segments excluded.
      For example, `/a/b/c` yields `["a", "b", "c"]`.
      Test membership with `in`. Indexing, such as `http.path_segments[0]`, isn't supported.
    example: '`"admin" in http.path_segments`'
  - field: "`http.headers.<header_name>`"
    type: "`string`"
    description: |
      The value of the specified request header.
      Header names are always normalized to lowercase with underscores, so `X-My-Header` becomes `http.headers.x_my_header`.
      Returns the first value if the header has multiple values.
      Returns `null` if the header is absent.
    example: '`http.headers.x_tier == "premium"`'
  - field: "`http.queries.<param_name>`"
    type: "`string`"
    description: |
      The value of the specified query parameter.
      Returns the first value if the parameter appears multiple times.
      Returns `null` if the parameter is absent.
    example: '`http.queries.plan == "pro"`'
  - field: "`http.headers_list.<header_name>`"
    type: "`list<string>`"
    description: "All values of the specified request header as a list. Returns `null` if the header is absent."
    example: '`http.headers_list.x_roles != null && "editor" in http.headers_list.x_roles`'
  - field: "`http.queries_list.<param_name>`"
    type: "`list<string>`"
    description: "All values of the specified query parameter as a list. Returns `null` if the parameter is absent."
    example: '`http.queries_list.tag != null && "featured" in http.queries_list.tag`'
  - field: "`net.protocol`"
    type: "`string`"
    description: 'The protocol of the request, for example `"http"` or `"https"`.'
    example: '`net.protocol == "https"`'
  - field: "`net.tls.sni`"
    type: "`string`"
    description: "The server name from the TLS ClientHello packet. Returns `null` for non-TLS connections."
    example: '`net.tls.sni == "api.example.com"`'
  - field: "`net.src.ip`"
    type: "`string`"
    description: "The IP address of the client."
    example: '`net.src.ip == "10.0.0.1"`'
  - field: "`net.src.port`"
    type: "`int`"
    description: "The port the client used to connect."
    example: '`net.src.port > 1024`'
  - field: "`net.dst.ip`"
    type: "`string`"
    description: "The listening IP address where the data plane accepted the connection."
    example: '`net.dst.ip == "192.168.1.1"`'
  - field: "`net.dst.port`"
    type: "`int`"
    description: "The listening port where the data plane accepted the connection."
    example: '`net.dst.port == 443`'
{% endtable %}
<!--vale on-->

#### Context fields

The following fields describe the {{site.ai_gateway}} context.

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Behavior for an AI Policy
    key: behavior
rows:
  - field: "`consumer.id`, `consumer.username`, `consumer.custom_id`, `consumer.tags`"
    behavior: |
      Return `null` when the request isn't authenticated.
      For an authenticated AI Consumer, `consumer.id` is the AI Consumer's ID, `consumer.username` is its `name`, and `consumer.custom_id` is its custom ID.
      `consumer.tags` contains the AI Consumer's labels as `key:value` strings, and is `null` when the AI Consumer has no labels.
  - field: "`consumer_group.names`, `consumer_group.ids`"
    behavior: |
      Return `null` when the request isn't authenticated.
      For an authenticated AI Consumer that belongs to AI Consumer Groups, return the names and IDs of those groups.
  - field: "`principal.id`, `principal.metadata`"
    behavior: |
      When the request is authenticated through an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) with {{site.identity}} [Principal](/identity/principals/) mapping (`config.principals`), `principal.id` is the Principal's ID and `principal.metadata` is its metadata map.
      In all other cases, both fields are `null`.

  - field: "`kong.ctx.shared`"
    behavior: |
      Always a map. Accessing a missing key causes a runtime error.
      Check for the key with `has()` first. See [Null handling](#null-handling).
      A [Pre-Function Policy](/ai-gateway/policies/pre-function/) can set keys in this map for the conditions of lower-priority AI Policies to read.
{% endtable %}
<!--vale on-->

{:.info}
> The `consumer.*`, `consumer_group.*`, and `principal.*` fields are populated only after an authentication step has identified the caller.

#### Fields to avoid

Don't use `route.*`, `service.*`, or `plugins.*` fields in AI Policy conditions.
{{site.ai_gateway}} [generates](/ai-gateway/configure-on-prem/#how-entities-translate-to-kong-gateway-configuration) a Route, a Service, and plugins from your AI entities and AI Policies.
These fields describe the generated resources.
Their names and IDs differ from your AI entity names and aren't part of the {{site.ai_gateway}} interface.
The `plugins.<name>.is_matched`, `plugins.<name>.priority`, and `plugins.<name>.access_has_executed` fields describe {{site.base_gateway}} plugins.

### Null handling

How null values behave depends on the field type.

The following fields return `null` when a value isn't set:
* `http.headers.*`
* `http.queries.*`
* `http.headers_list.*`
* `http.queries_list.*`
* `net.tls.sni`
* `consumer.*`, `consumer_group.*`, `principal.*`

Compare these fields directly with `null`:

```sh
consumer.id != null
http.headers.x_tier != null && http.headers.x_tier.startsWith("prem")
```

A comparison such as `http.headers.x_tier == "premium"` evaluates to `false`, not an error, when the header is absent.

The `kong.ctx.shared` and `principal.metadata` fields are maps whose inner keys aren't pre-populated.
Accessing a missing key in these maps causes a runtime error.
Before you access a key, use `has()` to check that it exists:

```sh
has(kong.ctx.shared.my_flag) && kong.ctx.shared.my_flag == "enabled"
```

{:.warning}
> {{site.ai_gateway}} doesn't support `default()` in AI Policy conditions. The `default()` function that {{site.base_gateway}} plugin conditions use to catch runtime errors is rejected when you save the AI Policy. Use `has()` instead.

### Operators and functions

<!--vale off-->
{% table %}
columns:
  - title: Operator or function
    key: type
  - title: Description
    key: description
rows:
  - type: "`&&`, `||`, `!`"
    description: "Logical AND, OR, NOT."
  - type: "`()`"
    description: "Group expressions to control evaluation order."
  - type: "`==`, `!=`, `<`, `<=`, `>`, `>=`"
    description: "Standard value comparison."
  - type: "`+`"
    description: "String concatenation."
  - type: "`in`"
    description: "Tests whether a value is a member of a list."
  - type: "`contains()`"
    description: "Returns `true` if the string contains the given substring."
  - type: "`startsWith()`"
    description: "Returns `true` if the string starts with the given prefix."
  - type: "`endsWith()`"
    description: "Returns `true` if the string ends with the given suffix."
  - type: "`matches()`"
    description: |
      Tests the string against a regular expression.
  - type: "`has()`"
    description: "Returns `true` if the key exists in the map. Required before you access inner keys of `kong.ctx.shared` or `principal.metadata`."
  - type: "`cond ? a : b`"
    description: "Conditional expression."
{% endtable %}
<!--vale on-->

{:.info}
> Regular expression matches succeed if they match a substring of the argument.
> Use explicit anchors (`^` and `$`) to force full-string matching.
> For example, `http.path.matches("^/api/v[0-9]+$")` matches `/api/v1` but not `/other/api/v1`.

### Types

<!--vale off-->
{% table %}
columns:
  - title: Type
    key: type
  - title: Description
    key: description
  - title: Example literal
    key: example
rows:
  - type: "`bool`"
    description: "Boolean value."
    example: "`true`, `false`"
  - type: "`int`"
    description: "64-bit signed integer."
    example: "`42`, `-1`"
  - type: "`string`"
    description: "UTF-8 string."
    example: '`"hello"`'
  - type: "`list<string>`"
    description: "Ordered list of string values."
    example: '`["foo", "bar"]`'
  - type: "`map<string, _type>`"
    description: "Map with string keys and values of any type. Used for `kong.ctx.shared` and `principal.metadata`."
    example: "See the `kong.ctx.shared` field."
  - type: "`null`"
    description: "Null value, returned when an optional field has no value."
    example: "`null`"
{% endtable %}
<!--vale on-->

## Validation

{{site.ai_gateway}} validates the condition when you save the AI Policy and rejects it with a `400` error in these cases:

* **Syntax error:** The expression isn't valid CEL, for example `http.headers.x_tier ====`.
* **Unsupported variable:** The expression uses a variable that isn't in the supported list, for example `http.request.headers.x_tier`.
* **Unsupported function or operation:** The expression uses a function or operation that isn't available, for example `default()`, `size()`, or indexing a list with `[0]`.
* **Non-boolean result:** The expression doesn't evaluate to `true` or `false`, for example `http.path` on its own.

## Debugging

### Runtime errors

If an expression fails while {{site.ai_gateway}} is processing a request, the data plane returns a `500` error to the client with the message `An unexpected error occurred while evaluating a plugin condition`.
The message names the generated {{site.base_gateway}} plugin and its ID, not the originating AI Policy name.
For example, `kong.ctx.shared.foo == "x"` fails when the `foo` key isn't set.
To avoid the error, check that the key exists first:

```yaml
condition: 'has(kong.ctx.shared.foo) && kong.ctx.shared.foo == "x"'
```

### Debug logs

When the data plane log level is `debug`, {{site.ai_gateway}} logs the result of each condition evaluation:

```text
[debug] plugins_iterator.lua:717 plugin condition matched for plugin 'mocking' (ID: 64249cb7-9a2f-554c-ba57-23a68583e8bc)
[debug] plugins_iterator.lua:712 plugin condition not matched for plugin 'mocking' (ID: dae2e503-2d0d-5b2f-8790-2c899f50ecc6): skipped
[error] plugins_iterator.lua:702 error evaluating plugin condition for plugin 'mocking' (ID: a888c3dc-1e54-59e7-b828-aee297268be6): Key not found in map : "foo"
```
{:.no-copy-code}

The plugin name and ID refer to the plugin that {{site.ai_gateway}} generates from the AI Policy, not to the AI Policy itself.
The error line is logged at `error` level, so it appears at any log level.
The matched and not matched lines appear only at `debug`.

## Differences from {{site.base_gateway}} plugin conditions

If you already use [plugin conditions](/gateway/plugins/conditions/) in {{site.base_gateway}}, the following differences apply to AI Policies:

* `default()` and `size()` aren't available.
* You can't index lists or call `exists()` and `all()` on fields.
* `route.*` and `service.*` refer to generated resources, not your AI entities.
* Don't use `plugins.*` fields. They reference plugins by name, and {{site.ai_gateway}} generates those plugins with names you don't control.

