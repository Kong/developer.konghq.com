---
title: Conditional expressions for plugins

description: Use ATC expressions to conditionally control whether a plugin executes on a given request.
content_type: reference
layout: reference

products:
  - gateway

beta: true

min_version:
  gateway: '3.14'

breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/plugin/

faqs:
  - q: Do conditionals work with global plugins?
    a: Yes, conditions can be used in global plugins that are not scoped to a Route, Service, Consumer, or Consumer Group.
  - q: When should I use plugin conditionals instead of Routes?
    a: |
      Routes with expression router conditions should be used instead of per-plugin conditionals wherever practical,
      since Route expressions will be more performant than plugin conditions.
      This is because:
       * The `init` phase of plugins on excluded Routes won't execute.
       * The plugin conditional won't need to be evaluated.
  - q: Can I match a plugin condition based on the request content type (for example, JSON or XML)?
    a: |
      While the conditional expression language doesn't support this explicitly, you could use a plugin such as Datakit or Pre-Function to parse the body, extract the value required, and put the value in a variable in the request context. 
      The conditional expression for the plugin can then be set based on that variable.

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Get started with conditional plugin execution
    url: /how-to/get-started-with-conditional-plugin-execution/
  - text: Plugin entity
    url: /gateway/entities/plugin/
  - text: Plugin contexts
    url: /gateway/entities/plugin/#plugin-contexts
  - text: Plugin scopes
    url: /gateway/entities/plugin/#scoping-plugins
  - text: Plugin priority
    url: /gateway/entities/plugin/#plugin-priority

---

Plugin conditions allow you to attach an optional `condition` expression to any plugin.
When a request comes in, {{site.base_gateway}} evaluates the expression immediately before the plugin's `access` phase.
If the expression evaluates to `true`, the plugin runs normally. If it evaluates to `false`, the plugin is skipped for that request.

Here are some common use cases for setting a condition on a plugin:

* Skip a global plugin for specific Routes, hosts, or request paths without removing the plugin or duplicating it across individual Routes.
* Enforce a plugin only for specific HTTP methods, headers, or query parameters.
* Make one plugin's execution depend on context set by a higher-priority plugin.
* Condition plugin behavior on the authenticated Consumer, matched Route, or target Gateway Service.

{:.info}
> Plugin conditions are only supported in the HTTP subsystem. They can't be used with stream (TCP, TLS, UDP) Routes.

## How it works

When {{site.base_gateway}} receives a request, it matches the request to a Route and determines which plugins are in scope according to the [plugin scoping rules](/gateway/entities/plugin/#scoping-plugins).
For each in-scope plugin that has a `condition` set, {{site.base_gateway}} evaluates the expression before that plugin's `access` phase runs.

The following [plugin contexts](/gateway/entities/plugin/#plugin-contexts) always execute, regardless of the condition: `init_worker`, `configure`, `certificate`, and `rewrite`.
If the condition evaluates to `false`, the plugin's `access` phase and later phases are skipped.
Because of this, values set during or after the response phase (for example, `kong.ctx.shared` values written in `header_filter` or `body_filter`) aren't available to condition expressions.

Unlike plugin scopes, which are evaluated once at router time before any plugins run, conditions are evaluated per request, per plugin, immediately before each plugin executes.
This means a higher-priority plugin can set values in `kong.ctx.shared` that a lower-priority plugin's condition can then read.

If no condition is set, the plugin always executes.

## Performance considerations

[Plugin scopes](/gateway/entities/plugin/#scoping-plugins) are evaluated once at router time and are more efficient than conditions, which are evaluated per-request for each conditioned plugin.
Where possible, use plugin scopes to control plugin execution rather than conditions.

When conditions are necessary, keep the following in mind:

* A plugin's configuration is always loaded into memory, even if its condition evaluates to `false`.
* Complex compound expressions with many fields are more expensive to evaluate than simple single-field expressions.
* Conditions that reference `kong.ctx.shared` fields require a higher-priority plugin to set those values on every request, which adds its own overhead.

## Plugin conditions reference

This reference describes the expression syntax and available fields for plugin conditions.

### Expression formatting

A condition expression is a string value assigned to the `condition` field of a plugin object.
It follows the same ATC (Abstract Tree Classifier) expression syntax used by {{site.base_gateway}}'s [expressions router](/gateway/routing/expressions/).

A predicate is the basic unit of an expression and takes the following form:

```
http.method == "GET"
```

This predicate has the following structure:

* `http.method`: Field
* `==`: Operator
* `"GET"`: Constant value

Predicates are made up of smaller units that you can configure:

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
      A value extracted from the current request or {{site.base_gateway}} context. An absent field value always causes the predicate to evaluate to `false`. The field always appears on the left side of the predicate.
    example: "`http.method`"
  - object: Constant value
    description: "The value that the field is compared against. Always appears on the right side of the predicate."
    example: |
      `"GET"`
  - object: Operator
    description: "Defines the comparison to perform between the field and the constant value. Always appears between the field and the constant value."
    example: "`==`"
  - object: Predicate
    description: "Compares a field against a constant value using the given operator. Returns `true` if the comparison passes, `false` if it does not."
    example: |
      `http.method == "GET"`
{% endtable %}
<!--vale on-->

### Field and constant value types

{% include /gateway/expressions/field-types.md %}

### Available fields

Plugin conditions support all standard HTTP fields from the expressions router, plus additional context fields that are only available during plugin execution.

#### HTTP request fields

These fields reflect the state of the incoming HTTP request at the time the condition is evaluated.
These values may have been modified by higher-priority plugins before the condition is evaluated (for example, a plugin that rewrites a header or query parameter).

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - field: "`http.method`"
    type: String
    description: |
      The HTTP method of the incoming request, for example `"GET"` or `"POST"`.
  - field: "`http.host`"
    type: String
    description: "The `Host` header of the incoming request."
  - field: "`http.path`"
    type: String
    description: "The normalized request path. Does not include query parameters."
  - field: "`http.path.segments.<index>`"
    type: String
    description: |
      A single path segment extracted from the normalized path, using a zero-based index. For example, for `/a/b/c`, `http.path.segments.1` returns `"b"`.
  - field: "`http.path.segments.<index>_<index>`"
    type: String
    description: |
      A range of path segments joined by `/`. For example, for `/a/b/c`, `http.path.segments.0_1` returns `"a/b"`.
  - field: "`http.path.segments.len`"
    type: Int
    description: "The number of segments in the normalized path. For example, `/a/b/c` returns `3`."
  - field: "`http.headers.<header_name>`"
    type: "String[]"
    description: "The value(s) of the specified request header. Header names are always normalized to lowercase with underscores, so `X-My-Header` becomes `http.headers.x_my_header`."
  - field: "`http.queries.<param_name>`"
    type: "String[]"
    description: "The value(s) of the specified query parameter."
  - field: "`net.src.ip`"
    type: IpAddr
    description: "The IP address of the client."
  - field: "`net.src.port`"
    type: Int
    description: "The port used by the client to connect."
  - field: "`net.dst.ip`"
    type: IpAddr
    description: "The listening IP address where {{site.base_gateway}} accepted the connection."
  - field: "`net.dst.port`"
    type: Int
    description: "The listening port where {{site.base_gateway}} accepted the connection."
{% endtable %}
<!--vale on-->

{:.info}
> Hyphens (`-`) in header names must be replaced with underscores (`_`) in ATC expressions. 
> For example, `x-my-header` becomes `http.headers.x_my_header`.

#### Plugin condition-specific fields

The following fields are populated during plugin execution and reflect the Gateway context at the time the condition is evaluated.

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
  - field: "`consumer.id`"
    type: String
    description: "The UUID of the authenticated consumer, if one has been identified by an earlier plugin."
  - field: "`consumer.username`"
    type: String
    description: "The username of the authenticated consumer."
  - field: "`consumer.custom_id`"
    type: String
    description: "The custom ID of the authenticated consumer."
  - field: "`route.id`"
    type: String
    description: "The UUID of the matched route."
  - field: "`route.name`"
    type: String
    description: "The name of the matched route."
  - field: "`service.id`"
    type: String
    description: "The UUID of the target service."
  - field: "`service.name`"
    type: String
    description: "The name of the target service."
  - field: "`kong.ctx.shared.KEY_NAME`"
    type: String
    description: |
      A value from the `kong.ctx.shared` table, set by a higher-priority plugin earlier in the same request.
{% endtable %}
<!--vale on-->

{:.info}
> **Notes**: 
> * `consumer.*` fields are only populated after an authentication plugin (such as Key Auth or Basic Auth) has run. 
> Conditions referencing consumer fields must be on a plugin with a lower priority than the authentication plugin.
> * `kong.ctx.shared.KEY_NAME` fields are only populated if a higher-priority plugin has set them during the `access` phase. 
> Values set during the response phase are not available.

### Operators

{% include /gateway/expressions/operators.md %}

### Allowed type and operator combinations

{% include /gateway/expressions/type-and-operator-combinations.md %}

{:.info}
> The `~` regex operator does not automatically anchor to the start of the string.
> `http.path ~ r#"/foo/\d"#` would match `/foo/1` and `/other/foo/1`.
> To anchor from the start, use the `^` character: `http.path ~ r#"^/foo/\d"#`.

## Example expressions

The following tables contain examples of different types of expressions.

### HTTP request fields

The following expressions can be used to match HTTP requests.

<!--vale off-->
{% table %}
columns:
  - title: Name
    key: name
  - title: Example
    key: example
  - title: Description
    key: description
rows:
  - name: Match by HTTP method
    example: |
      `http.method == "POST"`
    description: "Matches requests using the POST method."
  - name: Match by path prefix
    example: |
      `http.path ^= "/api/v2"`
    description: "Matches requests with paths starting with `/api/v2`."
  - name: Match by regex path
    example: |
      `http.path ~ r#"^/api/v[0-9]+"#`
    description: "Matches versioned API paths such as `/api/v1` or `/api/v2`."
  - name: Match by host
    example: |
      `http.host == "internal.example.com"`
    description: "Matches requests sent to a specific host."
  - name: Match by header value
    example: |
      `http.headers.x_version == "2"`
    description: "Matches requests with the header `x-version: 2`."
  - name: Match by header prefix
    example: |
      `http.headers.authorization ^= "Bearer"`
    description: "Matches requests with a Bearer token in the Authorization header."
  - name: Match by query parameter
    example: |
      `http.queries.auth == "required"`
    description: "Matches requests with the query parameter `auth=required`."
  - name: Exclude a path prefix
    example: |
      `!(http.path ^= "/health")`
    description: "Skips the plugin for any path starting with `/health`."
  - name: "Compound: method and header"
    example: |
      `http.method == "POST" && http.headers.x_version == "2"`
    description: "Matches only POST requests that also include the `x-version: 2` header."
  - name: "Compound: method or path"
    example: |
      `http.method == "DELETE" || http.path ^= "/admin"`
    description: "Matches DELETE requests or any request to an `/admin` path."
{% endtable %}
<!--vale on-->

### Consumer fields

The following expressions can be used to match Consumer metadata.

<!--vale off-->
{% table %}
columns:
  - title: Name
    key: name
  - title: Example
    key: example
  - title: Description
    key: description
rows:
  - name: Match by Consumer username
    example: |
      `consumer.username == "alice"`
    description: "Matches requests authenticated as the Consumer `alice`."
  - name: Match by Consumer UUID
    example: |
      `consumer.id == "a1b2c3d4-..."`
    description: "Matches requests from a specific Consumer by UUID."
  - name: Match by Consumer custom ID
    example: |
      `consumer.custom_id == "ext-user-123"`
    description: "Matches requests from a Consumer with a specific external identifier."
{% endtable %}
<!--vale on-->

### Route and Service fields

The following expressions can be used to match Route and Service metadata.

<!--vale off-->
{% table %}
columns:
  - title: Name
    key: name
  - title: Example
    key: example
  - title: Description
    key: description
rows:
  - name: Match by Route name
    example: |
      `route.name == "payments-route"`
    description: "Matches requests routed through a specific Route."
  - name: Exclude a Route by name
    example: |
      `route.name != "health-check-route"`
    description: "Skips the plugin for a specific Route."
  - name: Match by Service name
    example: |
      `service.name == "payments-service"`
    description: "Matches requests targeting a specific Gateway Service."
{% endtable %}

### kong.ctx.shared fields

The following expressions can be used to match `kong.ctx.shared` fields.

{% table %}
columns:
  - title: Name
    key: name
  - title: Example
    key: example
  - title: Description
    key: description
rows:
  - name: Match on a shared context value
    example: |
      `kong.ctx.shared.my_flag == "enabled"`
    description: |
      Matches requests where a higher-priority plugin set `kong.ctx.shared.my_flag` to `"enabled"`.
  - name: Exclude based on shared context
    example: |
      `!(kong.ctx.shared.bypass == "true")`
    description: "Skips the plugin unless a higher-priority plugin has set the bypass flag."
{% endtable %}
<!--vale on-->

## Debugging

When {{site.base_gateway}} is running with debug logging enabled, a log line is emitted for each
condition evaluation, showing the plugin name, plugin ID, the expression, and the result:

```
[kong] plugin_condition.lua:234 plugin condition evaluated for plugin
'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6):
expression="http.headers.x_block == "true"", result=false
```
{:.no-copy-code}

When `result=false`, the plugin was skipped for that request. When `result=true`, the plugin executed normally.
