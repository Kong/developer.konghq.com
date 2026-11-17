---
title: Enable Proxy Caching
description: Use the `KongPlugin` CRD to configure proxy caching for a route or service.
content_type: how_to
permalink: /operator/get-started/konnect-crds/proxy-caching/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-get-started-konnect-crds
  position: 5 

tldr:
  q: How do I enable response caching with {{site.konnect_short_name}} CRDs?
  a: |
    Apply the `proxy-cache` plugin using the `KongPlugin` CRD.

products:
  - operator

tools:
  - operator

works_on:
  - konnect

tags:
  - caching

---

## Set up the `proxy-cache` plugin

Use the `KongPlugin` CRD to enable proxy caching on a `KongService`. The following example:

* Caches `200 OK` responses
* Applies to `GET` and `HEAD` requests
* Targets responses with `text/plain` content type
* Stores cached data in memory
* Sets the cache TTL to 300 seconds (5 minutes)

<!-- vale off -->
{% konnect_crd %}
kind: KongPlugin
apiVersion: configuration.konghq.com/v1
metadata:
  name: proxy-cache-all-endpoints
plugin: proxy-cache
config:
  response_code:
  - 200
  request_method:
  - GET
  - HEAD
  content_type:
  - text/plain; charset=utf-8
  cache_ttl: 300
  strategy: memory
{% endkonnect_crd %}
<!-- vale on -->

## Apply the plugin to the `KongService`

Apply the plugin by annotating the `KongService` with its name:

```bash
kubectl annotate -n kong kongservice service konghq.com/plugins=proxy-cache-all-endpoints --overwrite
```
{: data-test-step="block" }

## Validation

Send a request to the Route and inspect the `X-Cache-Status` header. The first request finds nothing in the cache, so it is sent to the upstream Service and its response is cached:

<!-- vale off -->
{% validation request-check %}
url: /echo
konnect_url: http://$PROXY_IP
on_prem_url: http://$PROXY_IP
display_headers: true
retry: true
extract_headers:
  - name: X-Cache-Status
    variable: CACHE_STATUS
expected_headers:
  - 'X-Cache-Status: Miss'
{% endvalidation %}
<!-- vale on -->

Send the same request again. This time the response is served from the cache:

<!-- vale off -->
{% validation request-check %}
url: /echo
konnect_url: http://$PROXY_IP
on_prem_url: http://$PROXY_IP
display_headers: true
retry: true
extract_headers:
  - name: X-Cache-Status
    variable: CACHE_STATUS
expected_headers:
  - 'X-Cache-Status: Hit'
{% endvalidation %}
<!-- vale on -->

Responses stay cached for 300 seconds, as set in the `cache_ttl` field of the plugin configuration.