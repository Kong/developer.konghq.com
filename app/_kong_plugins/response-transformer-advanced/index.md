---
title: 'Response Transformer Advanced'
name: 'Response Transformer Advanced'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Modify the upstream response before returning it to the client, with greater customization capabilities'

tags: 
  - transformations

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
icon: response-transformer-advanced.png

categories:
  - transformations

search_aliases:
  - response-transformer-advanced

related_resources:
  - text: Response Transformer plugin
    url: /plugins/response-transformer/
  - text: All transformation plugins
    url: /plugins/?category=transformations

min_version:
  gateway: '1.0'
---

{% include plugins/request-response-transformer/response-transformer-description.md %}

The Response Transformer Advanced plugin provides features that aren't available in the [Response Transformer plugin](/plugins/response-transformer/), including:
* When transforming a JSON payload, transformations are applied to nested JSON objects and
  arrays. This can be turned enabled and disabled using the [`config.dots_in_keys`](./reference/#schema--config-dots-in-keys) configuration parameter.
  See [Arrays and nested objects](#arrays-and-nested-objects) for more information.
* Transformations can be restricted to responses with specific status codes using various
  `config.*.if_status` configuration parameters.
* JSON body contents can be restricted to a set of allowed properties with
  [`config.allow.json`](./reference/#schema--config-allow-json).
* The entire response body can be replaced using [`config.replace.body`](./reference/#schema--config-replace-body).
* Arbitrary transformation functions written in Lua can be applied.
* The plugin will decompress and recompress Gzip-compressed payloads
  when the `Content-Encoding` header is `gzip`.

{:.warning}
> **Notes:** 
* Transformations on the response body can cause changes in performance.
To parse and modify a JSON body, the plugin needs to retain it in memory,
which might cause pressure on the worker's Lua VM when dealing with large bodies (several MB).
Because of Nginx's internals, the `Content-Length` header will not be set when transforming a response body.
* If the value contains a `,` then the comma separated format for lists cannot be used. 
Array notation must be used instead.

## Order of execution

{% include plugins/request-response-transformer/transformation-order.md %}

## Arrays and nested objects

{% include plugins/request-response-transformer/arrays-nested-objects.md %}