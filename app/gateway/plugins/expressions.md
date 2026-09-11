---
title: CEL expressions reference

description: Reference for the CEL expression language and fields available to plugin conditions and other CEL-driven plugin config in {{site.base_gateway}}.
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

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Plugin conditional execution reference
    url: /gateway/plugins/conditions/
  - text: Dynamic plugin config with CEL
    url: /gateway/plugins/expressible-fields/
  - text: Expressions router
    url: /gateway/routing/expressions/
  - text: Plugin entity
    url: /gateway/entities/plugin/
---

[Common Expression Language (CEL)](https://cel.dev/) is a lightweight expression language used across {{site.base_gateway}}'s CEL-driven plugin config for [plugin conditions](/gateway/plugins/conditions/) and [dynamic plugin configuration fields](/gateway/plugins/expressible-fields/). 

This page is the shared reference for that language, its available fields, and its types. 
See the linked pages for how each mechanism works.

## Expression syntax

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

## Combining predicates

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

## Available fields

Plugin conditions and other CEL-driven plugin config support HTTP request fields, {{site.base_gateway}} context fields, and plugin state fields.

#### HTTP request fields

These fields reflect the state of the incoming HTTP request at the time the expression is evaluated.
Higher-priority plugins may have already modified these values (for example, by rewriting a header or query parameter) before the expression is evaluated.

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
      `http.path.startsWith("/api/v2")`
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

The following fields are populated during plugin execution and reflect the Gateway context at the time the expression is evaluated.

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
  - field: "`principal.display_name`"
    type: "`string`"
    description: "The display name of the authenticated Principal. `null` if no Principal is authenticated."
    example: |
      `principal.display_name == "alice"`
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
> `consumer.*` and `consumer_group.*` fields are only populated after an authentication plugin (such as Key Auth or Basic Auth) has run. On a plugin condition, this means the condition must be on a plugin with a **lower priority** than the authentication plugin.

#### Plugin state fields

The following fields reflect the configured state of other plugins in the same Gateway workspace or control plane at the time the expression is evaluated.

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
      * `true` if the plugin's `access` phase has already executed at the time this field is evaluated.
      * `false` if the plugin is matched but its `access` phase has not run yet.
      * `null` if the plugin isn't configured.
    example: |
      `plugins.key_auth.access_has_executed == true`
{% endtable %}
<!--vale on-->

## Null handling

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
Accessing a missing key in these maps causes a runtime error.
Before accessing a key, use `has()` to check for its existence:

```sh
has(kong.ctx.shared.my_flag) && kong.ctx.shared.my_flag == "enabled"
```

How that runtime error is handled once it occurs (for example, whether it can be caught with `default()`) depends on which CEL-driven mechanism the expression belongs to. See [Plugin conditions](/gateway/plugins/conditions/) and [Dynamic plugin config with CEL](/gateway/plugins/expressible-fields/) for each mechanism's own error handling.

## Operators and functions

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
      Wraps an expression to return a fallback value if the expression produces a runtime error.
      Whether `default()` is available depends on the CEL-driven mechanism. See [Plugin conditions](/gateway/plugins/conditions/#handling-default-values) and [Dynamic plugin config with CEL](/gateway/plugins/expressible-fields/) for each mechanism's own rules.
{% endtable %}
<!--vale on-->

{:.info}
> Regular expressions follow the rules of [Rust Crate regex](https://docs.rs/regex/latest/regex/#syntax). 
> Regular expression matches succeed if they match a substring of the argument. 
> Use explicit anchors (`^` and `$`) in the pattern to force full-string matching, if desired. 
> For example, `http.path.matches("^/api/v[0-9]+$")` matches `/api/v1` but not `/other/api/v1`.

## Types

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
