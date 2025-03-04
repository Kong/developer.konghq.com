---
title: 'OAS Validation'
name: 'OAS Validation'

content_type: plugin

publisher: kong-inc
description: 'Validate HTTP requests and responses based on an OpenAPI 3.0 or Swagger API Specification'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: oas-validation.png

categories:
  - traffic-control

search_aliases:
  - specification
  - openapi
  - swagger
  - oas-validation

faqs:
  - q: How can I prevent the OAS Validation plugin from validating the ETag header with the If-Match header?
    a: |
      If a request contains the `If-Match` request header, the OAS Validation plugin follows [RFC 2616](https://www.ietf.org/rfc/rfc2616.txt) to validate the `Etag` response header.

      If you don't want the plugin to validate the `Etag` with the `If-Match` request header,
      send the `If-Match` header with a wildcard (`*`) to skip validation.

      For example:
      ```sh
      curl http://localhost:8000/example-route \
        -H 'If-Match:*'
      ```

related_resources:
  - text: Event Hooks
    url: /gateway/entities/event-hook/
---

Validate HTTP requests and responses against an OpenAPI Specification.

The plugin supports Swagger v2 and OpenAPI 3.0.x and 3.1.0 specifications with a JSON Schema validator that supports [Draft 2019-09](https://json-schema.org/specification-links#draft-2019-09-(formerly-known-as-draft-8)).

## Supported OpenAPI 3.1.0 specification features

Starting with {{site.base_gateway}} 3.7, the OAS Validation plugin supports the following OpenAPI specification features:

| Category                        | Supported                      | Not supported                                                            |
|---------------------------------|--------------------------------|--------------------------------------------------------------------------|
| Request body                    | `application/json`             | `application/xml`<br>`multipart/form-data`<br>`text/plain`<br>`text/xml` |
| Response body                   | `application/json`             | -                                                                        |
| Request parameters              | `path`<br>`query`<br>`header`<br>`cookie` | -                                                             |
| Schema                          | `allOf`<br>`oneOf`<br>`anyOf`  | -                                                                        |
| Parameter serialization         | `style`<br>`explode `          | -                                                                        |

## Using Event Hooks with OAS Validation

[Event Hooks](/gateway/entities/event-hook/) are outbound calls from {{site.base_gateway}}. 
With Event Hooks, {{site.base_gateway}} can communicate with target services or resources, letting the target know that an event was triggered. 

For the OAS Validation plugin, Event Hook events can be enabled when a validation fails for:
* All request parameters, including: URI, header, query parameters, and request body
* The response body from the upstream service

To configure an Event Hook for the OAS Validation plugin, you'll need to pass the following parameters:

| Event Hook Parameter | Value       |
|--------------|---------------------|
| `source`     | `oas-validation`    |
| `event`      | `validation-failed` |
| `handler`    | `webhook`           |
| `on_change`  | `true`              |
| `config.url` | Your webhook URL    |

If validation fails, the webhook URL receives a response with JSON payload, which includes the forwarded IP address, Gateway Service and Consumer information, and the error message.

See the [Event Hooks](/gateway/entities/event-hook/) reference for details on how to configure an Event Hook.

