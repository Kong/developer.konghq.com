---
title: "Route annotations"
description: "Configure route behavior such as path stripping, host preservation, buffering, HTTPS redirects, and path handling by annotating HTTPRoute and GRPCRoute resources."
content_type: reference
layout: reference

products:
  - operator

works_on:
  - on-prem
  - konnect

min_version:
  operator: '2.4'

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Advanced Usage

related_resources:
  - text: Redirect HTTP traffic to HTTPS
    url: /operator/dataplanes/how-to/redirect-http-to-https/
  - text: Service annotations reference
    url: /operator/dataplanes/reference/service-annotations/
  - text: KIC annotation reference
    url: /kubernetes-ingress-controller/reference/annotations/
---

{{ site.operator_product_name }} supports a set of `konghq.com/*` annotations on `HTTPRoute` and `GRPCRoute` resources. {{ site.operator_product_name }} propagates these annotations to the {{site.base_gateway}} Route that it generates for the resource.

For example:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
  namespace: kong
  annotations:
    konghq.com/strip-path: "true"
    konghq.com/request-buffering: "false"
    konghq.com/https-redirect-status-code: "301"
spec:
  parentRefs:
    - name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: my-service
          port: 80
```

{:.info}
> **Note**: Annotations that configure the upstream connection, such as timeouts and retries, are set on the `Service` instead. See the [Service annotations reference](/operator/dataplanes/reference/service-annotations/).

## Available annotations

{% table %}
columns:
  - title: Annotation
    key: name
  - title: HTTPRoute
    key: http
  - title: GRPCRoute
    key: grpc
  - title: Description
    key: description
rows:
  - name: "[`konghq.com/strip-path`](#konghq-com-strip-path)"
    http: "Yes"
    grpc: "No"
    description: "Strip the matched path prefix from the request before forwarding it upstream"
  - name: "[`konghq.com/preserve-host`](#konghq-com-preserve-host)"
    http: "Yes"
    grpc: "Yes"
    description: "Send the client `Host` header to the upstream service"
  - name: "[`konghq.com/request-buffering`](#konghq-com-request-buffering)"
    http: "Yes"
    grpc: "Yes"
    description: "Buffer the request body before proxying it upstream"
  - name: "[`konghq.com/response-buffering`](#konghq-com-response-buffering)"
    http: "Yes"
    grpc: "Yes"
    description: "Buffer the response body before sending it to the client"
  - name: "[`konghq.com/https-redirect-status-code`](#konghq-com-https-redirect-status-code)"
    http: "Yes"
    grpc: "Yes"
    description: "Status code returned when redirecting HTTP requests to HTTPS"
  - name: "[`konghq.com/path-handling`](#konghq-com-path-handling)"
    http: "Yes"
    grpc: "Yes"
    description: "Algorithm used to build the upstream request path"
{% endtable %}

Annotations are optional. A malformed value sets the `KongConfigurationValid` condition to `False` on the route, and {{ site.operator_product_name }} doesn't program the route in {{site.base_gateway}}.

## konghq.com/strip-path

Strips the matched path prefix from the request before forwarding it to the upstream service. For example, if the route matches the `/httpbin` prefix and the annotation is set to `"true"`, a request to `/httpbin/get` reaches the upstream service as `/get`.

Accepted values: 
- `"true"`
- `"false"`

Defaults to `"false"`.

This annotation has no effect on `GRPCRoute` resources, because {{site.base_gateway}} doesn't accept `strip_path` on `grpc` and `grpcs` Routes.

Sample usage:

```yaml
konghq.com/strip-path: "true"
```

## konghq.com/preserve-host

Controls whether {{site.base_gateway}} sends the `Host` header of the client request to the upstream service. When set to `"false"`, {{site.base_gateway}} sets the `Host` header to the upstream target, or to the value of the [`konghq.com/host-header`](/operator/dataplanes/reference/service-annotations/#konghq-com-host-header) Service annotation.

Accepted values: 
- `"true"`
- `"false"`

Defaults:

- `HTTPRoute`: `"true"`
- `GRPCRoute`: the {{site.base_gateway}} default, which is `false`. {{ site.operator_product_name }} only sets the field when the annotation is present, so existing routes keep their behavior.

Sample usage:

```yaml
konghq.com/preserve-host: "false"
```

## konghq.com/request-buffering

Controls whether {{site.base_gateway}} buffers the request body before proxying it to the upstream service. Disable buffering to stream large or long-lived request bodies to the upstream service as they arrive.

Accepted values: 
- `"true"`
- `"false"`

Defaults to `true`.

Sample usage:

```yaml
konghq.com/request-buffering: "false"
```

## konghq.com/response-buffering

Controls whether {{site.base_gateway}} buffers the response body before sending it to the client. Disable buffering to stream large or long-lived responses to the client as they arrive.

Accepted values: 
- `"true"`
- `"false"`

Defaults to `true`.

Sample usage:

```yaml
konghq.com/response-buffering: "false"
```

## konghq.com/https-redirect-status-code

Sets the HTTP status code that {{site.base_gateway}} returns when a client sends a plain HTTP request that matches a Route that only accepts HTTPS. Attach the route to an `HTTPS` listener only, for example with `sectionName` in `parentRefs`, for the redirect to apply.

Accepted values: 
- `"301"`
- `"302"`
- `"307"`
- `"308"`
- `"426"`

Defaults to `426`.

Sample usage:

```yaml
konghq.com/https-redirect-status-code: "301"
```

## konghq.com/path-handling

Sets the [path handling algorithm](/gateway/entities/route/#path-handling), which controls how {{site.base_gateway}} combines the Service `path` and the Route `path` into the path sent upstream.

Accepted values: 
- `v0`
- `v1`

If the annotation isn't set, {{site.base_gateway}} uses its default.

Sample usage:

```yaml
konghq.com/path-handling: "v1"
```

## Unsupported annotations

{{ site.operator_product_name }} doesn't support the following Route annotations on `HTTPRoute` and `GRPCRoute` resources:
- `konghq.com/methods`
- `konghq.com/headers.*`
- `konghq.com/host-aliases`
- `konghq.com/regex-priority`
- `konghq.com/protocols`
- `konghq.com/snis`

Configure the equivalent behavior with Gateway API fields or the `Gateway` listener instead.
