---
title: 'Request Callout'
name: 'Request Callout'

content_type: plugin
tags:
  - transformations

publisher: kong-inc
description: 'Insert arbitrary API calls before proxying a request to the upstream service.'
tier: enterprise

products:
    - gateway

works_on:
  - on-prem
  - konnect

min_version:
   gateway: '3.10'

topologies:
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

This plugin is composed of callout objects, where each object specifies the 
API callout declaratively, with custom query parameters, headers, and request body.

API callout responses are stored in the {{site.base_gateway}} shared context 
under a `kong.ctx.shared.callouts.CALLOUT_NAME`. Responses can be cached with a TTL.

{:.info}
> Content modifications in both callout and upstream bodies assume a JSON content 
type.

{:.warning}
> When `tls_certificate_verify` is enabled in {{site.base_gateway}}, certificate verification for this plugin is enforced at runtime, not at configuration time. Since the `url` field can be set dynamically {% new_in 3.13 %}, the plugin cannot validate whether `ssl_verify=false` is appropriate until the request is processed. If the URL resolves to an HTTPS endpoint with `ssl_verify=false`, the request will be blocked. Conversely, if the URL resolves to an HTTP endpoint, the configuration is valid and the request proceeds.

## Callout context

Callout request and response context is stored in `kong.ctx.shared.callouts.CALLOUT_NAME`. 

The request context includes:

* `.CALLOUT_NAME.request.params`: Full callout request config, including `url`, `method`, `query`, `headers` (case-sensitive), `body`, `decode`, `ssl_verify`, `proxy`, `timeouts`, and other HTTP options.
* `.CALLOUT_NAME.request.retries`: Retry attempts if `error = retry`, with:
  * `reason`: `error` (TCP error) or `code` (HTTP status code).
  * `err`: Specific error.
  * `http_code`: Triggering status code.
* `.CALLOUT_NAME.request.n_retries`: Total retry count.
* `.CALLOUT_NAME.caching`: Cache config per plugin schema. If `cache_key` is set, it overrides the key for the current callout.

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
or Lua function available within the {{site.base_gateway}} sandbox can be used. The syntax is the 
same as the [Request Transformer Advanced plugin](/plugins/request-transformer-advanced/)
uses for Lua expressions. 
In `custom` values, callouts can be referenced via the shorthand `callouts.CALLOUT_NAME`
instead of the full `kong.ngx.shared.callouts.CALLOUT_NAME`. 
Lua expressions don't carry side effects.
If the `custom` value is a raw string, make sure the string doesn't start with `#` or `$`,
as the backend interpreter will read anything following these characters as a Lua expression.
If you need to include a `#` or `$` character, change the value to `$("$|#RAW STRING")`.
For example, `#1234!` is not a valid `custom` value. To make it valid, pass the value as `$("#1234!")`.

`by_lua` fields work in a similar way, but they don't support shortcuts.
Shortcuts can produce unintended side effects and modify callout and upstream requests.

Both request and response callout objects may contain a `by_lua` field:
* `request.by_lua` runs before the callout request is performed or the cache is queried
and is useful to further customize aspects of the request.
* `response.by_lua` runs after a response is obtained from the service and 
before it is stored in the cache and is useful to customize aspects of the
response.

The upstream object may also contain a `by_lua` field for Lua code 
that runs before the upstream request runs. This is useful to further customize 
the upstream request, or even to bypass it completely, short-circuiting the 
request and response from {{site.base_gateway}}.

Lua code may contain references and modify values in the callout context. 

{:.warning}
> Schema validation will detect syntax issues. Other errors, such as 
> nil references, happen at runtime and will lead to an `Internal Server Error`. 
> Lua code must be thoroughly tested to ensure that it's correct and meets 
> performance requirements.

## Forwarding headers

Callout request and upstream request configuration blocks contain a `forward` 
flag that controls whether specific request components are used to build the 
callout or upstream request. 

If [`config.upstream.headers.forward`](./reference/#schema--config-upstream-headers-forward) is set to `false`, 
this effectively clears all incoming request headers, including essential 
headers such as `Content-Type` and `Host`.

If you need to forward only a subset of headers, you can reinsert a custom list of headers 
using the [`config.upstream.headers.custom`](./reference/#schema--config-upstream-headers-custom) configuration parameter.

## Caching

The Request Callout plugin supports caching of callout requests. Globally, the 
behavior is configured via the [`config.cache`](/plugins/request-callout/reference/#schema--config-cache) setting.

### Cache key

The callout cache key is the SHA-256 of the following proxy request and callout 
request components:
- Proxy request:
  * Route ID
  * Plugin ID
  * Consumer ID (if a Consumer is set)
  * Consumer Groups (if at least one Consumer Group exists)
- Callout request:
  * Callout name
  * HTTP method
  * Callout URL
  * Callout query params (sorted by key name)
  * Callout headers (sorted by header name)
  * Callout request body (sorted by key name, if a key-value format like JSON is 
    used)

{:.info}
> By default, only callout request query and headers are part of the cache key, 
and incoming proxy request headers and query params are not.
If callout headers and query params have a `forward` flag set, then incoming request headers and query params are forwarded in the callout requests, causing them to be part of the 
cache key.

{% include plugins/redis-cloud-auth.md %}