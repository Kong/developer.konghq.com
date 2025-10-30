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
"condition": "context.topic.name.endsWith('my_suffix')"
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
  - type: "[String functions](#string-functions)"
    details: |
      `includes`, `startsWith`, `endsWith`, `substring`, `match`
{% endtable %}

### String functions

{{site.event_gateway}} supports the following string functions in conditional fields:

* `includes`: Performs a case-sensitive search to determine whether a given string may be found within this string, as defined in the [JavaScript standard](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/includes).
* `startsWith`: Determines whether the string begins with the characters of a specified string, [equivalent to the JavaScript standard function](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith).
* `endsWith`: Determines whether the string ends with the characters of a specified string, [equivalent to the JavaScript standard function](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith).
* `substring`: Returns the part of this string from the start index up to and excluding the end index.
* `match`: Retrieves the result of matching this string against an [RE2 regular expression](https://github.com/google/re2/wiki/syntax) string.


