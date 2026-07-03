---
title: How to enforce strict JSON body schemas when using the OAS Validation plugin
content_type: support
description: Set the additionalProperties field to false in your OAS body schema to reject request bodies that contain keys not defined in the schema.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I enforce strict JSON body schemas when using the OAS Validation plugin?
  a: |
    Set the `additionalProperties` field to `false` in your OAS body schema definition.
    When `additionalProperties` is `true` or omitted, the plugin allows any extra JSON keys as
    long as the required keys are present (a fail-open scenario).
    When set to `false`, a request body containing any key not explicitly defined in the schema fails validation (the fail-safe scenario).
related_resources:
  - text: OAS Validation plugin
    url: /plugins/oas-validation/
---

## Steps

When using OAS Validation plugin to validate a request against a particular OAS specification, you can set `additionalProperties` to either `true` or `false` in the body schema definition.

Given the following JSON body in the request:

```json
{
  "value": "test",
  "blah": "invalid"
}
```

And this OAS schema for a JSON body:

```yaml
  schemas:
    Echo:
      type: object
      required:
        - value
      properties:
        value:
          type: string
        optionalValue:
          type:
            - "null"
            - string
```

When `additionalProperties` is set to `true` or omitted entirely from the schema, the plugin allows any number of JSON keys in the request body, as long as there is a `value` key present.

This example request body will pass validation as this is a fail-open scenario.

When `additionalProperties` is set to `false`:

```yaml
  schemas:
    Echo:
      type: object
      required:
        - value
      properties:
        value:
          type: string
        optionalValue:
          type:
            - "null"
            - string
      additionalProperties: false
```

The additional `blah` key in the request body is not explicitly defined in the example schema. Because `additionalProperties` is `false`, additional keys are not allowed, therefore the request fails validation.
