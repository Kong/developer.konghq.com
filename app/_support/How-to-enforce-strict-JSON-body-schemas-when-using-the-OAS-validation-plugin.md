---
title: How to enforce strict JSON body schemas when using the OAS validation plugin
content_type: support
description: Set the additionalProperties field to false in your OAS body schema so the OAS validation plugin rejects request bodies containing keys not defined in the schema.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
---

## Overview

How can I enforce strict JSON body schemas when using the OAS validation plugin?

## Steps

When using OAS-Validation plugin to validate a request against a particular OAS specification, a boolean field called `additionalProperties` can be set to either `true` or `false` in the body schema definition.

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

When `additionalProperties` is set to `true` or omitted entirely from the schema, the plugin will allow any number of JSON keys in the request body, as long as there is a `value` key present.

The request body above will pass validation as this is a fail-open scenario.

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

The additional `blah` key in the request body is not explicitly defined in the schema above, and `additionalProperties` is not disallowed, therefore the request will fail validation.

This is the fail-safe scenario.
