---
title: "{{site.event_gateway_short}} expressions language"

description: "Reference for the CEL expression language used for defining {{site.event_gateway_short}} conditions and dynamic values."

content_type: reference
layout: reference

products:
  - event-gateway

related_resources:
  - text: Event Gateway policy hub
    url: /event-gateway/policies/
  - text: Policy entity
    url: /event-gateway/entities/policy/

breadcrumbs:
  - /event-gateway/

works_on:
  - konnect

---

In {{site.event_gateway}}, you can use a policy's `condition` field to determine whether a policy should execute, and in some policies, to compute a dynamic value such as a list of fields to encrypt.

{{site.event_gateway_short}} expressions are written in [Common Expression Language (CEL)](https://cel.dev/), wrapped in double curly braces. For example, this condition selects all topics that end with the suffix `my_suffix`:

{% raw %}
```json
{"condition": "{{context.topic.name.endsWith(\"my_suffix\")}}"}
```
{% endraw %}

Conditions must be between 1 and 1000 characters long.

{:.info}
> **Legacy syntax**: Expressions without the double curly brace wrapper are parsed as {{site.event_gateway_short}}'s older JavaScript-subset syntax, which is currently supported but will be deprecated in an upcoming update. See [Legacy JavaScript-style syntax](#legacy-javascript-style-syntax).

## Expression syntax

A predicate is the basic unit of an expression and compares a field against a value:

```sh
context.topic.name == "my_topic"
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
    description: "A value extracted from the connection, request, or record being evaluated."
    example: "`context.topic.name`"
  - object: Value
    description: "The value the field is compared against. Can be a constant (`string`, `int`, `bool`) or another field."
    example: '`"my_topic"`'
  - object: Operator
    description: "Defines the comparison to perform between the field and the value."
    example: "`==`"
  - object: Predicate
    description: "Compares a field against a value using the given operator. Returns `true` if the comparison passes, `false` if it does not."
    example: |
      `context.topic.name == "my_topic"`
{% endtable %}
<!--vale on-->

The `context.` prefix is optional. `topic.name == "my_topic"` and `context.topic.name == "my_topic"` are equivalent.

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
    description: "Logical AND. True if both sides are true."
    example: '`context.topic.name == "a" && context.auth.type == "anonymous"`'
  - operator: "`||`"
    description: "Logical OR. True if either side is true."
    example: '`context.auth.principal.name == "user1" || context.auth.principal.name == "user2"`'
  - operator: "`!`"
    description: "Logical NOT. Inverts the result."
    example: '`!(context.auth.type == "anonymous")`'
  - operator: "`()`"
    description: "Parentheses. Control evaluation order."
    example: '`context.topic.name == "a" && (context.auth.type == "b" || context.auth.type == "c")`'
{% endtable %}
<!--vale on-->

## Available fields

Depending on where an expression is authored, the fields available in the context vary.
The source of truth for these is the `x-expression` field in the [API specification](/api/konnect/event-gateway/).

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Type
    key: type
  - title: Description
    key: description
  - title: Availability
    key: availability
  - title: Example
    key: example
rows:
  - variable: "`context.auth.type`"
    type: "`string`"
    description: |
      The type of authentication used.
    availability: |
      * `condition` field in Cluster, Produce, and Consume policies
      * `resource_names` field in ACL policies
    example: |
      `context.auth.type == "anonymous"`
  - variable: "`context.auth.principal.name`"
    type: "`string`"
    description: |
      The name of the principal for this connection.
    availability: |
      * `condition` field in Cluster, Produce, and Consume policies
      * `resource_names` field in ACL policies
    example: |
      `context.auth.principal.name == "user1"`
  - variable: |
      `context.auth.principal.id` {% new_in 1.2 %}
    type: "`string`"
    description: |
      The UUID of the authenticated principal. Only populated when the principal was resolved through a [{{site.identity}}](/event-gateway/kong-identity-oauth/) directory lookup.
    availability: |
      * `condition` field in Cluster, Produce, and Consume policies
      * `resource_names` field in ACL policies
    example: |
      `context.auth.principal.id == "a1b2c3d4-..."`
  - variable: |
      `context.auth.principal.metadata` {% new_in 1.2 %}
    type: "`map<string, any>`"
    description: |
      Metadata attached to the authenticated principal in {{site.identity}}. Inner keys must be checked with `has()` before access.
    availability: |
      * `condition` field in Cluster, Produce, and Consume policies
      * `resource_names` field in ACL policies
    example: |
      `has(context.auth.principal.metadata.team) && context.auth.principal.metadata.team == "operators"`
  - variable: |
      `context.auth.token.claims` {% new_in 1.1 %}
    type: "`map<string, any>`"
    description: |
      Only populated for `sasl_oauth_bearer` authentication. Contains all claims from the JWT token. Claims can be strings, numbers, booleans, arrays, or nested JSON objects.
    availability: |
      * `condition` field in Cluster, Produce, and Consume policies
      * `resource_names` field in ACL policies
    example: |
      `"test-claim" in context.auth.token.claims`
  - variable: "`context.topic.name`"
    type: "`string`"
    description: |
      The name of the topic of the record.
    availability: |
      * `condition` field in Produce and Consume policies
    example: |
      `context.topic.name == "my-ns.my-topic"`
  - variable: "`record.headers`"
    type: "`map<string, string>`"
    description: |
      The headers of the record.
    availability: |
      * `condition` field in Produce and Consume policies
    example: |
      `record.headers["skip-record"] == "true"`
  - variable: "`record.value.content`"
    type: "`map<string, any>`"
    description: |
      The value of the record. Deep fields can be accessed using map indexing.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.content["sub.other"] == 3`
  - variable: "`record.value.validated`"
    type: "`bool`"
    description: |
      Whether record validation succeeded or not.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.validated == true`
  - variable: |
      `record.value.schema.id` {% new_in 1.2 %}
    type: "`int`"
    description: |
      Registry-assigned schema ID. Populated when the record value is validated by a Confluent schema registry.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.id == 42`
  - variable: |
      `record.value.schema.version` {% new_in 1.2 %}
    type: "`int`"
    description: |
      Registry-assigned schema version, when returned by the registry.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.version == 3`
  - variable: |
      `record.value.schema.format` {% new_in 1.2 %}
    type: "`string`"
    description: |
      `"avro"` or `"json"`.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.format == "avro"`
  - variable: |
      `record.value.schema.avro.name` {% new_in 1.2 %}
    type: "`string`"
    description: |
      Avro record name (Avro only).
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.avro.name == "User"`
  - variable: |
      `record.value.schema.avro.namespace` {% new_in 1.2 %}
    type: "`string`"
    description: |
      Avro record namespace (Avro only, when declared on the schema).
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.avro.namespace == "com.example"`
  - variable: |
      `record.value.schema.json.title` {% new_in 1.2 %}
    type: "`string`"
    description: |
      JSON Schema `title` (JSON only, when declared on the schema).
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.json.title == "Order"`
  - variable: |
      `record.value.schema.json.id` {% new_in 1.2 %}
    type: "`string`"
    description: |
      JSON Schema `$id` (JSON only, when declared on the schema).
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.json.id == "https://example.com/schemas/order.json"`
  - variable: "`record.value.schema.metadata.tags`"
    type: "`list<string>`"
    description: |
      Tags assigned to the schema in the schema registry.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `"PII" in record.value.schema.metadata.tags`
  - variable: "`record.value.schema.metadata.properties`"
    type: "`map<string, string>`"
    description: |
      Custom properties assigned to the schema in the schema registry.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.schema.metadata.properties["owner"] == "team-orders"`
  - variable: |
      `record.key.schema.*` {% new_in 1.2 %}
    type: |
      Same shape as `record.value.schema.*`
    description: |
      Populated when the record key has `schema_validation` configured. Sub-fields are absent when not applicable; use `has()` to test presence.
    availability: |
      * `condition` field in Produce and Consume policies used as children of Schema Validation
    example: |
      `record.key.schema.format == "json" && record.key.schema.json.title == "UserKey"`
  - variable: "`context.certificate.subject`"
    type: "`map<string, string>`"
    description: |
      Subject distinguished name of the client certificate, as a map. Access individual attributes such as `context.certificate.subject["CN"]` (Common Name) or `context.certificate.subject["O"]` (Organization).
    availability: |
      * `principal_mapping` field in TLS Server listener policies (mTLS)
    example: |
      `context.certificate.subject["CN"]`
  - variable: "`context.certificate.issuer`"
    type: "`map<string, string>`"
    description: |
      Issuer distinguished name of the client certificate, same format as `subject`.
    availability: |
      * `principal_mapping` field in TLS Server listener policies (mTLS)
    example: |
      `context.certificate.issuer["O"]`
  - variable: "`context.certificate.serialNumber`"
    type: "`string`"
    description: |
      Serial number of the client certificate.
    availability: |
      * `principal_mapping` field in TLS Server listener policies (mTLS)
    example: |
      `context.certificate.serialNumber`
  - variable: "`context.certificate.sans.dns`"
    type: "`list<string>`"
    description: |
      DNS Subject Alternative Names on the client certificate.
    availability: |
      * `principal_mapping` field in TLS Server listener policies (mTLS)
    example: |
      `context.certificate.sans.dns[0]`
  - variable: "`context.certificate.sans.uri`"
    type: "`list<string>`"
    description: |
      URI Subject Alternative Names on the client certificate.
    availability: |
      * `principal_mapping` field in TLS Server listener policies (mTLS)
    example: |
      `context.certificate.sans.uri.filter(u, u.startsWith("spiffe://"))[0]`
{% endtable %}

{:.info}
> `principal_mapping` expressions only have access to `context.certificate`. 
They can't reference `context.auth`, `context.topic`, or `record`, since no connection or record exists yet at certificate mapping time.

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
    description: "Tests whether a value is a member of a list, or a key is present in a map."
  - type: "`contains()`"
    description: "Returns `true` if the string contains the given substring."
  - type: "`startsWith()`"
    description: "Returns `true` if the string starts with the given prefix."
  - type: "`endsWith()`"
    description: "Returns `true` if the string ends with the given suffix."
  - type: "`matches()`"
    description: "Tests the string against an [RE2 regular expression](https://github.com/google/re2/wiki/syntax) string. Matches any substring unless anchored with `^` and `$`."
  - type: "`substring()`"
    description: "Returns the part of the string from the start index up to and excluding the end index."
  - type: "`size()`"
    description: "Returns the number of elements in a list or map, or the number of characters in a string."
  - type: "`has()`"
    description: "Returns `true` if the key exists in the map. Required before accessing inner keys of `context.auth.principal.metadata` or `record.value.schema.*`/`record.key.schema.*`, since those sub-fields aren't pre-populated."
  - type: "`all()`"
    description: "Returns `true` if all elements in the list satisfy the predicate."
  - type: "`exists()`, `map()`, `filter()`"
    description: "Additional CEL comprehension macros for working with lists and maps."
  - type: "`?:` (ternary)"
    description: "Conditional expression: `condition ? value_if_true : value_if_false`."
{% endtable %}
<!--vale on-->

{:.info}
> Regular expression matching follows [RE2 syntax](https://github.com/google/re2/wiki/syntax).
> {{site.event_gateway_short}} doesn't support a `default()` or other fallback function for CEL expressions.
> An expression that accesses a field that isn't present, or a `record.value.schema.*`/`record.key.schema.*` field gated to a higher [`min_runtime_version`](/event-gateway/entities/policy/), is rejected at configuration time rather than allowed to fail at runtime.
> Check for optional fields with `has()` and version-gate your policies with `min_runtime_version` instead.

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
    description: "Map with string keys and values of any type."
    example: "See `record.value.content` or `context.auth.token.claims`."
{% endtable %}
<!--vale on-->

## Example expressions

Don't apply a policy if a record has an `x-restricted=true` header and the user isn't an admin:

```sh
context.topic.name == "filterdemo" && record.headers["x-restricted"] == "true" && context.auth.principal.name != "admin"
```

Apply a policy only for `user1` and `user2`:

```sh
context.auth.principal.name == "user1" || context.auth.principal.name == "user2"
```

Apply a policy only for topics that start with `my-prefix`:

```sh
context.topic.name.startsWith("my-prefix")
```

Apply a policy if a header is present, regardless of value:

```sh
"x-optional-header" in record.headers
```

Apply a policy if the topic is `filterdemo` and the record content has a field `foo` equal to `bar`, or a field `sub.other` equal to `3`:

```sh
context.topic.name == "filterdemo" && record.value.content["foo"] == "bar" || record.value.content["sub.other"] == 3
```

Compute a dynamic list of fields to encrypt, based on the principal's identity:

```sh
context.auth.principal.name == "external-partner" ? ["personal.ssn", "personal.name"] : []
```

## Migrating from the legacy JavaScript-style syntax

{{site.event_gateway_short}} originally shipped with an expression language based on a subset of JavaScript, and has now moved to CEL as its expression language.
CEL is a widely adopted standard, has a stricter and better-specified grammar than a JavaScript subset, and gives {{site.event_gateway_short}} room to support additional CEL-native capabilities over time.

### How the two syntaxes coexist

Both syntaxes are accepted today, and the notation you use decides which one parses your `condition` (and other expression fields):

* **Wrapped in double curly braces**: Parsed as CEL.
* **Not wrapped**: Parsed as the legacy JavaScript-style syntax.

Existing expressions written in the legacy syntax continue to work unchanged. You don't need to migrate them immediately, but new expressions should use CEL.

### Syntax comparison

The fields available to an expression are the same in both syntaxes. 
Only the notation for accessing and comparing them differs.

<!--vale off-->
{% table %}
columns:
  - title: Concept
    key: concept
  - title: Legacy JavaScript-style syntax
    key: js
  - title: CEL
    key: cel
rows:
  - concept: Delimiters
    js: "None. The raw expression is the entire field value."
    cel: "Double curly braces wrap the entire field value."
  - concept: Field access
    js: "`context.topic.name`"
    cel: "`context.topic.name`, or the shorter `topic.name` (the `context.` prefix is optional in CEL)"
  - concept: String contains
    js: "`.includes(...)`"
    cel: "`.contains(...)`"
  - concept: String prefix/suffix
    js: "`.startsWith(...)`, `.endsWith(...)`"
    cel: "`.startsWith(...)`, `.endsWith(...)` (unchanged)"
  - concept: Substring
    js: "`.substring(start, end)`"
    cel: "`.substring(start, end)` (unchanged)"
  - concept: Regex match
    js: "`.match(...)`"
    cel: "`.matches(...)`"
  - concept: Length
    js: "`.length`"
    cel: "`.size()`"
  - concept: Membership test
    js: "`in`"
    cel: "`in` (unchanged)"
  - concept: Key presence test
    js: "`'key' in someMap`"
    cel: "`has(someMap.key)` for the maps that require it (see [Operators and functions](#operators-and-functions)); `'key' in someMap` also works"
  - concept: String concatenation
    js: "`+`"
    cel: "`+` (unchanged)"
  - concept: Conditional value
    js: "`condition ? valueIfTrue : valueIfFalse`"
    cel: "`condition ? valueIfTrue : valueIfFalse` (unchanged)"
  - concept: Secret and environment references
    js: "`${env['MY_VAR']}`, `${vault.my_vault.my_secret}`"
    cel: "Not available inside `condition` or other boolean/comparison expressions; `vault` and `env` aren't declared fields there. Continue using the legacy `${...}` syntax for `condition` and similar expression fields."
{% endtable %}
<!--vale on-->

{:.info}
> **`vault` and `env` aren't available inside `condition` expressions.** Use the legacy `${env[...]}`/`${vault...}` syntax for secret and environment references on fields like `condition`, even in a policy where other fields use CEL.

### Example migrations

{% table %}
columns:
  - title: Legacy JavaScript-style syntax
    key: js
  - title: CEL
    key: cel
rows:
  - js: "`context.topic.name.endsWith('my_suffix')`"
    cel: "`context.topic.name.endsWith(\"my_suffix\")`"
  - js: "`context.topic.name.includes('demo')`"
    cel: "`context.topic.name.contains(\"demo\")`"
  - js: "`record.value.content['name'].length > 3`"
    cel: "`record.value.content[\"name\"].size() > 3`"
  - js: "`context.auth.token.claims.topic_prefix + \"*\"`"
    cel: "`context.auth.token.claims.topic_prefix + \"*\"`"
  - js: "`context.topic.name.startsWith(\"public_\") ? [\"personal.ssn\"] : []`"
    cel: "`context.topic.name.startsWith(\"public_\") ? [\"personal.ssn\"] : []`"
{% endtable %}

### Legacy JavaScript-style syntax

The following reference covers the JavaScript-subset syntax used when an expression isn't wrapped in double curly braces.
The [available fields](#available-fields) are the same as for CEL; only the operators and functions differ.

#### Supported operators and expressions

{% table %}
columns:
  - title: Operator or expression type
    key: type
  - title: Operator or function
    key: details
rows:
  - type: "Logical operators"
    details: |
      `&&`, `||`, `!`
  - type: "Comparison operators"
    details: |
      `==`, `!=`, `<`, `<=`, `>`, `>=`
  - type: "Concatenation operator"
    details: |
      `+`
  - type: "Relational operator"
    details: |
      `in`
  - type: "Conditional operator"
    details: |
      `? :`
  - type: "String functions"
    details: |
      `includes`, `startsWith`, `endsWith`, `substring`, `match`, `length`
{% endtable %}

#### Legacy string functions

* `includes`: Performs a case-sensitive search to determine whether a given string may be found within this string, as
  defined in
  the [JavaScript standard](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/includes).
* `startsWith`: Determines whether the string begins with the characters of a specified
  string, [equivalent to the JavaScript standard function](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith).
* `endsWith`: Determines whether the string ends with the characters of a specified
  string, [equivalent to the JavaScript standard function](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith).
* `substring`: Returns the part of this string from the start index up to and excluding the end index.
* `match`: Retrieves the result of matching this string against
  an [RE2 regular expression](https://github.com/google/re2/wiki/syntax) string.
* `length`: Returns the number of characters in the string.

#### Legacy example expressions

Don't apply a policy if a record has a `x-restricted=true` header and user is not admin:

```sh
context.topic.name == 'filterdemo' && record.headers['x-restricted'] == 'true' && context.auth.principal.name != 'admin'
```

Apply a policy only for `user1` and `user2`:
```sh
context.auth.principal.name == 'user1' || context.auth.principal.name == 'user2'
```

Apply a policy only for topics that start with `my-prefix`:

```sh
context.topic.name.startsWith('my-prefix')
```

Apply a policy if a header is present regardless of the value:

```sh
'x-optional-header' in record.headers
```

Apply a policy if the topic is `filterdemo` and that the record content has a field `foo` equal to `bar` and a sub field `sub.other` equal to 3.

```sh
context.topic.name == 'filterdemo' && record.value.content['foo'] == 'bar' || record.value.content['sub.other'] == 3
```
