---
title: Conditional expressions for plugins

description: Reference for the CEL expression language used in {{site.base_gateway}} plugin conditions.
content_type: reference
layout: reference

products:
  - gateway

min_version:
  gateway: '3.15'

breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/plugin/

faqs:
  - q: Do conditions work with global plugins?
    a: Yes, conditions can be used on global plugins that are not scoped to a Route, Service, Consumer, or Consumer Group.
  - q: When should I use plugin conditions instead of Routes?
    a: |
      Routes with expression router conditions should be used instead of per-plugin conditions, since Route expressions are more performant than plugin conditions.
      This is because:
       * The `init` phase of plugins on excluded Routes won't execute.
       * The plugin condition won't need to be evaluated.
  - q: Can I match a plugin condition based on request content type (for example, JSON or XML)?
    a: |
      No, the condition expression language doesn't support this explicitly.
     As an alternative, you can use a plugin such as [Datakit](/plugins/datakit/) or [Pre-Function](/plugins/pre-function/) to parse the body, extract the required value, and store it in [`kong.ctx.shared`](/gateway/plugins/expressions/#kong-ctx-shared-fields).
      The plugin condition can then reference that `kong.ctx.shared` key.
  - q: What happens if my condition expression has a runtime error?
    a: |
      If a condition expression fails at runtime, {{site.base_gateway}} logs the error at the ERROR level and returns a 500 status code to the client.
      To prevent this, wrap your expression in a `default()` call: `default(<expression>, false)`.
      This returns `false` (and skips the plugin) instead of a 500 if the expression errors.
  - q: |
      I was using ATC for plugin conditions in {{site.base_gateway}} 3.14. What do I need to change for 3.15?
    a: |
      The expression language changed between 3.14 and 3.15.
      In {{site.base_gateway}} 3.14, the feature was in beta and used ATC (Abstract Tree Classifier) syntax for plugin conditions. 
      For the 3.14 reference, see [Conditional expressions for plugins in 3.14](/gateway/plugins/expressions-314/).
      {{site.base_gateway}} 3.15 uses CEL (Common Expression Language), which isn't backwards-compatible.

      Any conditional expression that worked in 3.14 will need to be rewritten for 3.15.
      The main syntax changes are:

      * Prefix matching: `^=` → `starts_with()`. For example, `http.path ^= "/api"` becomes `http.path.starts_with("/api")`.
      * Suffix matching: `=^` → `ends_with()`. For example, `http.path =^ ".json"` becomes `http.path.ends_with(".json")`.
      * Regex matching: `~` → `matches()`. For example, `http.path ~ r#"^/api/v[0-9]+"#` becomes `http.path.matches("^/api/v[0-9]+")`.
      * The `http.path.segments.<index>` fields are replaced by `http.path_segments` (a list).
      * Header and query fields now return `null` when absent (instead of an empty string), so null checks may be needed.

      See this reference for the full field and operator list.

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Configure conditional plugin execution
    url: /gateway/configure-conditional-plugin-execution/
  - text: Plugin entity
    url: /gateway/entities/plugin/
  - text: Plugin contexts
    url: /gateway/entities/plugin/#plugin-contexts
  - text: Plugin scopes
    url: /gateway/entities/plugin/#scoping-plugins
  - text: Plugin priority
    url: /gateway/entities/plugin/#plugin-priority
  - text: Conditional expressions for plugins in 3.14
    url: /gateway/plugins/expressions-314/

---

Plugin conditions let you attach an optional `condition` expression to any plugin.
When a request comes in, {{site.base_gateway}} evaluates the expression immediately before the plugin's `access` phase.
If the expression evaluates to `true`, the plugin runs normally.
If it evaluates to `false`, the plugin is skipped for that request.

Conditions use [Common Expression Language (CEL)](https://cel.dev/), a lightweight expression language.

Here are some common use cases for setting a condition on a plugin:

* Skip a global plugin for specific Routes, hosts, or request paths without removing the plugin or duplicating it across individual Routes.
* Enforce a plugin only for specific HTTP methods, headers, or query parameters.
* Make one plugin's execution depend on context set by a higher-priority plugin.
* Condition plugin behavior on the authenticated Consumer, matched Route, or target Gateway Service.

## How it works

When {{site.base_gateway}} receives a request, it matches the request to a Route and determines which plugins are in scope according to the [plugin scoping rules](/gateway/entities/plugin/#scoping-plugins).
For each in-scope plugin that has a `condition` set, {{site.base_gateway}} evaluates the expression before that plugin's `access` phase runs.

The following [plugin contexts](/gateway/entities/plugin/#plugin-contexts) always execute, regardless of the condition: `init_worker`, `configure`, `certificate`, and `rewrite`.
If the condition evaluates to `false`, the plugin's `access` phase and all later phases are skipped.
Because of this, values set during or after the response phase (for example, `kong.ctx.shared` values written in `header_filter` or `body_filter`) aren't available to condition expressions.

Unlike plugin scopes, which are evaluated once at router time before any plugins run, conditions are evaluated per request, per plugin, immediately before each plugin executes.
This means a higher-priority plugin can set values in `kong.ctx.shared` that a lower-priority plugin's condition can then read.

If no condition is set, the plugin always executes.

## Performance considerations

[Plugin scopes](/gateway/entities/plugin/#scoping-plugins) are evaluated once at router time and are more efficient than conditions, which are evaluated per request for each conditioned plugin.
Where possible, use plugin scopes to control plugin execution rather than conditions.

When conditions are necessary, keep the following in mind:

* A plugin's configuration is always loaded into memory, even if its condition evaluates to `false`.
* Complex compound expressions with many fields are more expensive to evaluate than simple single-field expressions.
* Conditions that reference `kong.ctx.shared` fields require a higher-priority plugin to set those values on every request, which adds its own overhead.

## Limitations

Plugin conditions are only supported in the HTTP subsystem.
They can't be used with stream (TCP, TLS, UDP) Routes.

The following plugins **do not** support conditions:
* Pre-Function
* Post-Function
* WebSocket Size Limit
* WebSocket Validator

All other [{{site.base_gateway}} plugins](/plugins/) support conditions.

Condition expressions have a maximum length of 1024 characters.

## Plugin conditions reference

This reference describes the CEL expression syntax and available fields for plugin conditions.

### Expression syntax

A condition expression is a string value assigned to the `condition` field of a plugin object.
A predicate is the basic unit of an expression and compares a field against a value:

```sh
http.method == "GET"
```

This predicate has the following structure:

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
      A value extracted from the incoming request or {{site.base_gateway}} context.
      An absent field may return `null` or cause a runtime error depending on the field type. See [Null handling](#null-handling).
    example: "`http.method`"
  - object: Value
    description: |
      The value the field is compared against. Can be a constant (`string`, `int`, `bool`, `null`) or another field.
      The value can appear on either side of the predicate.
    example: |
      `"GET"`
  - object: Operator
    description: "Defines the comparison to perform between the field and the value."
    example: "`==`"
  - object: Predicate
    description: "Compares a field against a value using the given operator. Returns `true` if the comparison passes, `false` if it does not."
    example: |
      `http.method == "GET"`
{% endtable %}
<!--vale on-->

### Combining predicates

Multiple predicates can be combined using logical operators:

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
    description: "Logical AND — true if both sides are true."
    example: '`http.method == "GET" && net.dst.port == 443`'
  - operator: "`||`"
    description: "Logical OR — true if either side is true."
    example: '`http.method == "GET" || http.method == "POST"`'
  - operator: "`!`"
    description: "Logical NOT — inverts the result."
    example: '`!(http.method == "DELETE")`'
  - operator: "`()`"
    description: "Parentheses — control evaluation order."
    example: '`(http.method == "GET" || http.method == "POST") && net.dst.port == 443`'
{% endtable %}
<!--vale on-->

### Available fields

Plugin conditions support HTTP request fields, {{site.base_gateway}} context fields, and plugin state fields.

#### HTTP request fields

These fields reflect the state of the incoming HTTP request at the time the condition is evaluated.
Higher-priority plugins may have already modified these values (for example, by rewriting a header or query parameter) before the condition is evaluated.

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
    description: |
      The HTTP method of the incoming request, for example `"GET"` or `"POST"`.
    example: |
      `http.method == "POST"`
  - field: "`http.host`"
    type: "`string`"
    description: "The `Host` header of the incoming request."
    example: |
      `http.host == "internal.example.com"`
  - field: "`http.path`"
    type: "`string`"
    description: "The normalized request path, without query parameters."
    example: |
      `http.path.starts_with("/api/v2")`
  - field: "`http.path_segments`"
    type: "`list<string>`"
    description: |
      The path split on `/`, with empty segments excluded.
      For example, `/a/b/c` yields `["a", "b", "c"]`.
      Individual segments can be accessed by index: `http.path_segments[0]` returns `"a"`.
      Membership can be tested with `in`.
    example: |
      `"admin" in http.path_segments`
  - field: "`http.headers.<header_name>`"
    type: "`string`"
    description: |
      The value of the specified request header.
      Header names are always normalized to lowercase with underscores, so `X-My-Header` becomes `http.headers.x_my_header`.
      Returns the first value if the header has multiple values.
      Returns `null` if the header is absent.
    example: |
      `http.headers.x_version == "2"`
  - field: "`http.queries.<param_name>`"
    type: "`string`"
    description: |
      The value of the specified query parameter.
      Returns the first value if the parameter appears multiple times.
      Returns `null` if the parameter is absent.
    example: |
      `http.queries.auth == "required"`
  - field: "`http.headers_list.<header_name>`"
    type: "`list<string>`"
    description: "All values of the specified request header as a list. Returns `null` if the header is absent."
    example: |
      `http.headers_list.x_roles != null && "editor" in http.headers_list.x_roles`
  - field: "`http.queries_list.<param_name>`"
    type: "`list<string>`"
    description: "All values of the specified query parameter as a list. Returns `null` if the parameter is absent."
    example: |
      `http.queries_list.tag != null && "featured" in http.queries_list.tag`
  - field: "`net.protocol`"
    type: "`string`"
    description: |
      The protocol of the Route, for example `"http"` or `"https"`.
    example: |
      `net.protocol == "https"`
  - field: "`net.tls.sni`"
    type: "`string`"
    description: "The server name from the TLS ClientHello packet, if the connection is over TLS. Returns `null` for non-TLS connections."
    example: |
      `net.tls.sni == "api.example.com"`
  - field: "`net.src.ip`"
    type: "`string`"
    description: "The IP address of the client."
    example: |
      `net.src.ip == "10.0.0.1"`
  - field: "`net.src.port`"
    type: "`int`"
    description: "The port used by the client to connect."
    example: |
      `net.src.port > 1024`
  - field: "`net.dst.ip`"
    type: "`string`"
    description: "The listening IP address where {{site.base_gateway}} accepted the connection."
    example: |
      `net.dst.ip == "192.168.1.1"`
  - field: "`net.dst.port`"
    type: "`int`"
    description: "The listening port where {{site.base_gateway}} accepted the connection."
    example: |
      `net.dst.port == 443`
{% endtable %}
<!--vale on-->

#### Gateway context fields

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
  - title: Example
    key: example
rows:
  - field: "`route.id`"
    type: "`string`"
    description: "The UUID of the matched Route. `null` for global plugins or Service-scoped plugins when no Route is matched."
    example: |
      `route.id == "a1b2c3d4-..."`
  - field: "`route.name`"
    type: "`string`"
    description: "The name of the matched Route. `null` when no Route is matched."
    example: |
      `route.name == "payments-route"`
  - field: "`route.tags`"
    type: "`list<string>`"
    description: "Tags assigned to the matched Route. `null` if no Route is matched or the Route has no tags."
    example: |
      `route.tags != null && "internal" in route.tags`
  - field: "`service.id`"
    type: "`string`"
    description: "The UUID of the matched Service. `null` for global plugins when no Service is matched."
    example: |
      `service.id == "a1b2c3d4-..."`
  - field: "`service.name`"
    type: "`string`"
    description: "The name of the matched Service. `null` when no Service is matched."
    example: |
      `service.name == "payments-service"`
  - field: "`service.tags`"
    type: "`list<string>`"
    description: "Tags assigned to the matched Service. `null` if no Service is matched or the Service has no tags."
    example: |
      `service.tags != null && "internal" in service.tags`
  - field: "`consumer.id`"
    type: "`string`"
    description: "The UUID of the authenticated Consumer, if one has been identified by a higher-priority plugin. `null` if no Consumer is matched."
    example: |
      `consumer.id == "a1b2c3d4-..."`
  - field: "`consumer.username`"
    type: "`string`"
    description: "The username of the authenticated Consumer. `null` if no Consumer is matched or the Consumer has no username."
    example: |
      `consumer.username == "alice"`
  - field: "`consumer.custom_id`"
    type: "`string`"
    description: "The custom ID of the authenticated Consumer. `null` if no Consumer is matched or the Consumer has no custom ID."
    example: |
      `consumer.custom_id == "user-123"`
  - field: "`consumer.tags`"
    type: "`list<string>`"
    description: "Tags assigned to the authenticated Consumer. `null` if no Consumer is matched or the Consumer has no tags."
    example: |
      `consumer.tags != null && "vip" in consumer.tags`
  - field: "`consumer_group.names`"
    type: "`list<string>`"
    description: "Names of Consumer Groups matched for this request. `null` if no Consumer Groups are matched."
    example: |
      `consumer_group.names != null && "premium" in consumer_group.names`
  - field: "`consumer_group.ids`"
    type: "`list<string>`"
    description: "UUIDs of Consumer Groups matched for this request. `null` if no Consumer Groups are matched."
    example: |
      `consumer_group.ids != null && "a1b2c3d4-..." in consumer_group.ids`
  - field: "`kong.ctx.shared`"
    type: "`Map`"
    description: |
      Values from the `kong.ctx.shared` table, set by higher-priority plugins during the `access` phase.
      Inner keys must be checked with `has()` before access, as they are not pre-populated.
      See [Null handling](#null-handling).
    example: |
      `has(kong.ctx.shared.my_flag) && kong.ctx.shared.my_flag == "enabled"`
  - field: "`principal.id`"
    type: "`string`"
    description: "The UUID of the authenticated Principal. `null` if no Principal is authenticated."
    example: |
      `principal.id == "a1b2c3d4-..."`
  - field: "`principal.name`"
    type: "`string`"
    description: "The display name of the authenticated Principal. `null` if no Principal is authenticated."
    example: |
      `principal.name == "alice"`
  - field: "`principal.metadata`"
    type: "`Map`"
    description: |
      Attributes of the authenticated Principal's metadata. `null` if no Principal is authenticated.
      Inner keys must be checked with `has()` before access.
      See [Null handling](#null-handling).
    example: |
      `has(principal.metadata.department) && principal.metadata.department == "finance"`
{% endtable %}
<!--vale on-->

{:.info}
> `consumer.*` and `consumer_group.*` fields are only populated after an authentication plugin (such as Key Auth or Basic Auth) has run.
> Conditions referencing these fields must be on a plugin with a **lower priority** than the authentication plugin.

#### Plugin state fields

The following fields reflect the configured state of other plugins in the same Gateway workspace or control plane at the time the condition is evaluated.

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
  - field: "`plugins.<plugin_name>.is_matched`"
    type: "`boolean`"
    description: |
      * `true` if the plugin is configured and its Route or Service scope matches this request (Consumer scope excluded).
      * `false` if the plugin is configured but its scope does not match.
      * `null` if the plugin isn't configured.
    example: |
      `plugins.key_auth.is_matched == true`
  - field: "`plugins.<plugin_name>.priority`"
    type: "`int`"
    description: "The priority of the matched plugin. `null` if the plugin isn't matched."
    example: |
      `plugins.key_auth.priority > 1000`
  - field: "`plugins.<plugin_name>.access_has_executed`"
    type: "`boolean`"
    description: |
      * `true` if the plugin's `access` phase has already executed at the time this condition is evaluated.
      * `false` if the plugin is matched but its `access` phase has not run yet.
      * `null` if the plugin isn't configured.
    example: |
      `plugins.key_auth.access_has_executed == true`
{% endtable %}
<!--vale on-->

### Null handling

How null values behave depends on the field type.

The following fields return `null` when a value isn't set:
* `http.headers.*`
* `http.queries.*`
* `http.headers_list.*`
* `http.queries_list.*`
* `net.tls.sni`
* All context fields (`consumer.*`, `route.*`, `service.*`, `principal.*`, `consumer_group.*`, `plugins.*`)

You can compare these directly using `null`:

```sh
consumer.id != null
route.tags != null && "internal" in route.tags
```

The `kong.ctx.shared` and `principal.metadata` fields are maps whose inner keys are not pre-populated by {{site.base_gateway}}.
Accessing a missing key in these maps causes a runtime error (500).
Before accessing a key, use `has()` to check for its existence:

```sh
has(kong.ctx.shared.my_flag) && kong.ctx.shared.my_flag == "enabled"
```

Alternatively, wrap the entire expression in `default()` to return a safe fallback if the key is missing:

```sh
default(kong.ctx.shared.my_flag == "enabled", false)
```

### Operators and functions

The following operators and functions are supported in plugin condition expressions:

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
  - type: "`starts_with()`"
    description: "Returns `true` if the string starts with the given prefix."
  - type: "`ends_with()`"
    description: "Returns `true` if the string ends with the given suffix."
  - type: "`matches()`"
    description: |
      Tests the string against a [RE2 regular expression](https://github.com/google/re2/wiki/Syntax).
      Matches any substring unless anchored with `^` and `$`.
  - type: "`size()`"
    description: "Returns the number of elements in a list, or the number of characters in a string."
  - type: "`has()`"
    description: "Returns `true` if the key exists in the map. Required before accessing inner keys of `kong.ctx.shared` or `principal.metadata`."
  - type: "`all()`"
    description: "Returns `true` if all elements in the list satisfy the predicate."
  - type: "`exists()`, `map()`, `filter()`"
    description: "Additional CEL comprehension macros for working with lists."
  - type: "`default()`"
    description: |
      Wraps an expression to return a fallback boolean value if the expression produces a runtime error.
      Wraps an expression to return a fallback boolean value if the expression produces a runtime error.
      Must wrap the **entire** expression, and cannot be used inline within a larger expression.
      <br><br>
      The second argument for this function accepts only boolean values (`true` or `false`).
{% endtable %}
<!--vale on-->

{:.info}
> Regular expressions follow the rules of [Rust Crate regex](https://docs.rs/regex/latest/regex/#syntax). 
> Regular expression matches succeed if they match a substring of the argument. 
> Use explicit anchors (`^` and `$`) in the pattern to force full-string matching, if desired. 
> For example, `http.path.matches("^/api/v[0-9]+$")` matches `/api/v1` but not `/other/api/v1`.

### Types

Plugins support the following CEL types:

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
    example: "See `kong.ctx.shared` field."
  - type: "`null`"
    description: "Null value, returned when an optional field has no value."
    example: "`null`"
{% endtable %}
<!--vale on-->

### Handling default values

`default()` makes condition expressions safe at runtime.
If the expression raises an evaluation error (for example, accessing a missing key in a map), `default()` returns the fallback value instead of causing a 500 error.

`default()` must wrap the **entire** expression. It can't appear inline within a larger expression:

```sh
# Valid — wraps the entire expression
default(kong.ctx.shared.my_flag == "enabled", false)

# Not valid — default() can't be used inline
kong.ctx.shared.my_flag == "enabled" && default(principal.id == "abc", false)
```
{:.no-copy-code}

Use `default()` when your expression references fields that might not be set for every request, such as `kong.ctx.shared.*` or `principal.metadata.*`:

```sh
default(principal.metadata["Department"] == "finance", false)
```

## Debugging

When {{site.base_gateway}} is running with debug logging enabled, a log line is emitted for each condition evaluation.

When a condition is **not matched** and the plugin is skipped:

```
plugin condition not matched for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6): skipped
```
{:.no-copy-code}

When a condition is **matched** and the plugin executes:

```
plugin condition matched for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6)
```
{:.no-copy-code}

If a condition expression **fails at runtime**, the error is logged at the `ERROR` level and {{site.base_gateway}} returns a 500 to the client:

```
error evaluating plugin condition for plugin 'request-termination' (ID: 66a1adbb-0179-49af-a065-4d0bc6c28cd6): No such key: foo
```
{:.no-copy-code}

To prevent runtime errors, wrap your expression in `default()`:

```json
"condition": "default(kong.ctx.shared.my_flag == \"enabled\", false)"
```
