---
title: 'Request Callout'
name: 'Request Callout'

content_type: plugin

publisher: kong-inc
description: 'Insert arbitrary API calls before proxying a request to the upstream service.'


products:
    - gateway

works_on:
  - on-prem
  - konnect

min_version:
   gateway: '3.10'

on_prem:
  - hybrid
  - db-less
  - traditional
konnect_deployments:
  - hybrid
  - cloud-gateways
  - serverless

icon: request-callout.png

categories:
  - transformations
---

The Request Callout plugin allows you to insert arbitrary API calls before
proxying a request to the upstream service. 

This plugin comprises of callout objects, where each object specifies the 
API callout declaratively, with custom query parameters, headers, and request body.

API callout responses are stored in the {{site.base_gateway}} shared context 
under a `kong.ctx.shared.callouts.<name>`. Responses can be cached with a TTL.

{:.info}
> Content modifications in both callout and upstream bodies assume a JSON content 
type.

## Callout context

Callout request and response context is stored in `kong.ctx.shared.callouts.<name>`. 

The request context includes:

* `.<name>.request.params`: Full callout request config, including `url`, `method`, `query`, `headers` (case-sensitive), `body`, `decode`, `ssl_verify`, `proxy`, `timeouts`, and other HTTP options.
* `.<name>.request.retries`: Retry attempts if `error = retry`, with:
  * `reason`: `error` (TCP error) or `code` (HTTP status code).
  * `err`: Specific error.
  * `http_code`: Triggering status code.
* `.<name>.request.n_retries`: Total retry count.
* `.<name>.caching`: Cache config per plugin schema. If `cache_key` is set, it overrides the key for the current callout.


The response context contains:
* `status`
* `headers`
* `body`

Header and body storage can be disabled via the 
[`config.callouts.response.headers.store`](./reference/#schema--config-callouts-response-headers-store)
and [`config.callouts.response.body.store`](./reference/#schema--config-callouts-response-body-store)
parameters.

## Lua code

All `custom` fields support Lua expressions in the value portion, and any PDK method 
or Lua function available within the Kong sandbox can be used. The syntax is the 
same as the [Request Transformer Advanced plugin](/plugins/request-transformer-advanced/)
uses for Lua expressions. In  `custom` values, callouts can be referenced via the shorthand `callouts.<name>`
instead of the full `kong.ngx.shared.callouts.<name>`. 
Lua expressions do not carry side effects.

`by_lua` fields work in a similar fashion, but do not support shortcuts can produce side effects and modify callout and upstream  requests.

Both request and response callout objects may contain a `by_lua` field:
* `request.by_lua` runs before the callout request is performed and is useful to 
further customize aspects of the request.
* `response.by_lua` runs after a response is obtained, and is useful to
customize aspects of the response such as caching.

The upstream object may also contain a `by_lua` field for Lua code 
that runs before the upstream request runs. This is useful to further customize 
the upstream request, or even to bypass it completely, short-circuiting the 
request and responding from {{site.base_gateway}}.

Lua code may contain references and modify values 
in the callout context. 

{:.warning}
> Schema validation will detect syntax issues. Other errors, such as 
> nil references, happen at runtime and will lead to an `Internal Server Error`. 
> Lua code must be thoroughly tested to ensure that it's correct and meets 
> performance requirements.

## The forward flag

Callout request and upstream request configuration blocks contain a `forward` 
flag that controls whether specific request components are used to build the 
callout or upstream request. If `config.upstream.headers.forward` is set to `false`, 
this effectively clears all incoming request headers, including essential 
headers such as `Content-Type` and `Host`.