---
title: 'Request Validator'
name: 'Request Validator'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Validates requests before they reach the upstream service'

related_resources:
  - text: OAS Validation plugin
    url: /plugins/oas-validation/
  - text: WebSocket Validator plugin
    url: /plugins/websocket-validator/

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: request-validator.png

categories:
  - traffic-control

tags:
  - traffic-control
  - validation

search_aliases:
  - request-validator

min_version:
  gateway: '1.0'
---

The Request Validator plugin allows you to validate requests before they reach the upstream server. This plugin supports validating the schema of the body and the parameters of the request using either Kong's own schema validator (body only) or a JSON Schema Draft 4 compliant validator.

If a validation fails, a `400 Bad Request` response is returned.

## Content-Type validation

The request `Content-Type` header is validated against the plugin's [`config.allowed_content_types`](./reference/#schema--config-allowed-content-types) setting. If the `Content-Type` is not listed, the request will be rejected, and return an `HTTP/400` error: `{"message":"specified Content-Type is not allowed"}`.

The parameter is strictly validated, which means a request with a parameter (for example, `application/json; charset=UTF-8`) is NOT considered valid for one without the same parameter (for example, `application/json`). The type, subtype, parameter names, and the value of the charset parameter are not case sensitive based on the RFC explanation.

{:.warning}
> When setting this configuration, the `Content-Type` header only gets validated when the `body_schema` is configured.

## Parameter validation

You can validate query parameters, path parameters, and headers in a request using the [`config.parameter_schema`](./reference/#schema--config-parameter-schema) configuration. Only the JSON Schema Draft 4 compliant validator is supported for parameter validation.

{:.warning}
> Even if `config.version` is set to `kong`, the parameter validation will still use the JSON Schema Draft 4 compliant validator.

### Parameter schema definition

You can set up definitions for each parameter  using the parameters under [`config.parameter_schema`](./reference/#schema--config-parameter-schema). 
These definitions are based on the OpenAPI Specification, and the plugin will validate each parameter against it. 
For more information, see the [OpenAPI specification](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#parameter-object) and the [OpenAPI examples](https://swagger.io/docs/specification/serialization/).

## Body validation

Request body validation is only performed for:
* Requests in which the `Content-Type` header is set to `application/json`
* {% new_in 3.6 %} Requests in which the `+json` suffix is added to the `Content-Type` For example: subtype: `application/merge-patch+json` 

For requests with any other allowed `Content-Type`, body validation is skipped. In that case, the request is proxied to the upstream without validating the body.

Either Kong's own schema validator (`config.version=kong`) or a JSON Schema Draft 4 compliant validator (`config.version=draft4`) can be used to validate the request body.

### Body schema definition

{:.info}
> This section describes the schema definition for the `kong` validator. For more information about the JSON Schema Draft 4-compliant validator, see the [JSON Schema website](https://json-schema.org/).

The [`config.body_schema`](./reference/#schema--config-body-schema) parameter expects a JSON array with the definition of each field expected to be in the request body.

Each field definition contains the following attributes:

{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - attribute: '`type`'
    required: yes
    description: |
      The expected type of the field. The following values are supported:
      * `string`
      * `number`
      * `integer`
      * `boolean`
      * `map`
      * `array`
      * `record`
  - attribute: '`required`'
    required: no
    description: Whether the field is required
{% endtable %}

Additionally, specific types may have their own required fields:

{% navtabs "types" %}

{% navtab "Map" %}
{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - attribute: '`keys`'
    required: yes
    description: The schema for the map keys
  - attribute: '`values`'
    required: yes
    description: The schema for the map values
{% endtable %}

For example:
```json
{
 "type": "map",
 "keys": {
   "type": "string"
 },
 "values": {
   "type": "boolean"
 }
}
```
{% endnavtab %}


{% navtab "Array" %}
{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - attribute: '`elements`'
    required: yes
    description: The schema for the array elements
{% endtable %}

For example:
```json
{
 "type": "array",
 "elements": {
   "type": "integer"
 }
}
```
{% endnavtab %}


{% navtab "Record" %}
{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - attribute: '`fields`'
    required: yes
    description: The record schema
{% endtable %}

For example:
```json
{
 "type": "record",
 "fields": [
   {
     "street": {
       "type": "string",
     }
   },
   {
     "zipcode": {
       "type": "string",
     }
   }
 ]
}
```
{% endnavtab %}

{% endnavtabs %}

Each field specification may also contain validators, which perform specific validations:

{% table %}
columns:
  - title: Validator
    key: validator
  - title: Applies to
    key: applies
  - title: Description
    key: description
rows:
  - validator: '`between`'
    applies: Integers
    description: Checks if the value is between two integers. Specified as an array; for example, `{1, 10}`
  - validator: '`len_eq`'
    applies: |
      * Arrays
      * Maps
      * Strings
    description: Checks if an array’s length is a given value
  - validator: '`len_min`'
    applies: |
      * Arrays
      * Maps
      * Strings
    description: Checks if an array's length is at least a given value
  - validator: '`len_max`'
    applies: |
      * Arrays
      * Maps
      * Strings
    description: Checks if an array's length is at most a given value
  - validator: '`match`'
    applies: Strings
    description: Checks if the value matches a given Lua pattern
  - validator: '`not_match`'
    applies: Strings
    description: Checks if the value doesn't match a given Lua pattern
  - validator: '`match_all`'
    applies: Arrays
    description: Checks if all strings in the array match the specified Lua pattern
  - validator: '`match_none`'
    applies: Arrays
    description: Checks if all strings in the array match the specified Lua pattern
  - validator: '`match_any`'
    applies: Arrays
    description: Checks if any one of the strings in the array matches the specified Lua pattern
  - validator: '`starts_with`'
    applies: Strings
    description: Checks if the string value starts with the specified substring
  - validator: '`one_of`'
    applies: |
      * Strings
      * Numbers
      * Integers
    description: Checks if the string field value matches one of the specified values
  - validator: '`timestamp`'
    applies: Integers
    description: Checks if the field value is a valid timestamp
  - validator: '`uuid`'
    applies: Strings
    description: Checks if the string is a valid UUID
{% endtable %}

For more information, see [Lua patterns](https://www.lua.org/pil/20.2.html).

### Semantic validation for the JSON Schema `format` attribute

{:.warning}
> This feature is only supported in JSON Schema Draft 4.

Structural validation alone may be insufficient to validate that an instance
meets all the requirements of an application. The `format` keyword is defined
to allow interoperable semantic validation for a fixed subset of values that
are accurately described by authoritative resources, be they RFCs or other
external specifications. The following attributes are available:

{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: description
    key: description
rows:
  - attribute: '`date`'
    description: Defined by [RFC 3339](https://tools.ietf.org/html/rfc3339), sections [5.6](https://tools.ietf.org/html/rfc3339#section-5.6) and further validated by [5.7](https://tools.ietf.org/html/rfc3339#section-5.7)
  - attribute: '`date-time`'
    description: Defined by RFC 3339, sections 5.6
  - attribute: '`time`'
    description: Defined by RFC 3339, sections 5.6 and further validated by 5.7
{% endtable %}

