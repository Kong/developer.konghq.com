---
title: 'jq'
name: 'jq'

tags:
  - jq
  - transformations

content_type: plugin

publisher: kong-inc
description: 'Transform JSON objects included in API requests or responses using jq programs'

min_version:
    gateway: '2.6'

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
icon: jq.png

categories:
  - transformations
---

The jq plugin enables arbitrary jq transformations on JSON objects included in API requests or responses.

The configuration accepts two sets of options: one for the request and another for the response.
For both the request and response, a [jq program](https://jqlang.org/manual/) string can be included, along with some jq option flags and a list of media types.

One of the configured media types must be included in the `Content-Type` header of the request or response for the jq program to run. 
The default media type in the `Content-Type` header is `application/json`.

In the response context, you can also specify a list of status codes, one of which must match the response status code.
The default response status code is `200`.

{:.info}
> **Note:** In the response context, the entire body must be buffered to be processed.
> This requirement also implies that the `Content-Length` header will be dropped if present, and the body transferred with chunked encoding.

See jq's documentation on [Basic filters](https://jqlang.org/manual/#basic-filters) for more information on writing programs with jq.

