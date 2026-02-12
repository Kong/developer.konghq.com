---
title: "{{site.event_gateway_short}} expressions language"

description: "Reference for the expressions language used for defining {{site.event_gateway_short}} conditions."

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

In {{site.event_gateway}}, you can use a policy's condition field to determine whether a certain policy should be executed.

For example, you can create a condition that selects all topics that end with the suffix `my_suffix`:

```json
{"condition": "context.topic.name.endsWith('my_suffix')"}
```

Conditions must be between 1 and 1000 characters long.

## Supported operators and expressions

For policy conditions and template strings, {{site.event_gateway}} supports a subset of JavaScript operators and expressions:

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
  - type: "[String functions](#string-functions)"
    details: |
      `includes`, `startsWith`, `endsWith`, `substring`, `match`
{% endtable %}

### String functions

{{site.event_gateway}} supports the following string functions in conditional fields:

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

### Supported fields

Depending on where an expression is authored the fields available in the context vary.
In this section we state for each area how the context varies.
The source of truth for these is the `x-expression` field in
the [API specification](/api/konnect/event-gateway/v1/).

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
      The type of authentication used
    availability: |
      Cluster, Produce and Consume policies
    example: |
      `context.auth.type == 'anonymous'`
  - variable: "`context.auth.principal.name`"
    type: "`string`"
    description: |
      The name of the principal for this connection
    availability: |
      Cluster, Produce and Consume policies
    example: |
      `context.auth.principal.name == 'user1'`
  - variable: "`context.topic.name`"
    type: "`string`"
    description: |
      The name of the topic of the record
    availability: |
      Produce and Consume policies
    example: |
      `context.topic.name == 'my-ns.my-topic'`
  - variable: "`record.headers`"
    type: "`map<string, string>`"
    description: |
      The headers of the record
    availability: |
      Produce and Consume policies
    example: |
      `record.headers['skip-record'] == 'true'`
  - variable: "`record.value.content`"
    type: "`map<string, string>`"
    description: |
      The value of the record. Deep fields can be accessed using json object notation
    availability: |
      Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.content['sub.other'] == 3`
  - variable: "`record.value.validated`"
    type: "`boolean`"
    description: |
      Whether record validation succeeded or not
    availability: |
      Produce and Consume policies used as children of Schema Validation
    example: |
      `record.value.validated == true`
{% endtable %}

### Example expressions


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