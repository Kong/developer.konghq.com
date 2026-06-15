---
title: "Service annotations"
description: "Configure upstream behavior such as timeouts, retries, host header, and TLS by annotating Kubernetes Services exposed through an HTTPRoute."
content_type: reference
layout: reference

products:
  - operator

works_on:
  - on-prem
  - konnect

min_version:
  operator: '2.2'

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Advanced Usage

related_resources:
  - text: Set timeouts and retries for a Service
    url: /operator/dataplanes/how-to/set-timeouts-and-retries/
  - text: Set the Host header sent to a Service
    url: /operator/dataplanes/how-to/set-host-header/
  - text: Configure load balancing with KongUpstreamPolicy
    url: /operator/dataplanes/how-to/configure-upstream-policy/
  - text: KIC annotation reference
    url: /kubernetes-ingress-controller/reference/annotations/
---

{{ site.operator_product_name }} supports a set of `konghq.com/*` annotations on Kubernetes `Service` resources. These annotations configure how {{site.base_gateway}} communicates with the upstream service — including protocols, timeouts, retries, host headers, and TLS settings.

Annotations are placed on the `Service` object that is referenced as a `backendRef` in an `HTTPRoute`. For example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: kong
  annotations:
    konghq.com/connect-timeout: "3000"
    konghq.com/read-timeout: "10000"
    konghq.com/retries: "3"
spec:
  ports:
    - port: 80
```

## Available annotations

{% table %}
columns:
  - title: Annotation
    key: name
  - title: Description
    key: description
rows:
  - name: "[`konghq.com/protocol`](#konghq-com-protocol)"
    description: "Set the protocol {{site.base_gateway}} uses to communicate with the upstream service"
  - name: "[`konghq.com/path`](#konghq-com-path)"
    description: "Prepend an HTTP path to every request forwarded to the upstream service"
  - name: "[`konghq.com/host-header`](#konghq-com-host-header)"
    description: "Override the `Host` header sent to the upstream service"
  - name: "[`konghq.com/client-cert`](#konghq-com-client-cert)"
    description: "Client certificate and key pair {{site.base_gateway}} uses to authenticate itself to the upstream service (mTLS)"
  - name: "[`konghq.com/upstream-policy`](#konghq-com-upstream-policy)"
    description: "Override {{site.base_gateway}} Upstream configuration with a `KongUpstreamPolicy` resource"
  - name: "[`konghq.com/connect-timeout`](#konghq-com-connect-timeout)"
    description: "Timeout for completing a TCP connection to the upstream service, in milliseconds"
  - name: "[`konghq.com/read-timeout`](#konghq-com-read-timeout)"
    description: "Timeout for receiving an HTTP response after sending a request, in milliseconds"
  - name: "[`konghq.com/write-timeout`](#konghq-com-write-timeout)"
    description: "Timeout for transmitting data to the upstream service, in milliseconds"
  - name: "[`konghq.com/retries`](#konghq-com-retries)"
    description: "Maximum number of times to retry a failed request"
  - name: "[`konghq.com/tls-verify`](#konghq-com-tls-verify)"
    description: "Enable or disable verification of the upstream service's TLS certificate"
  - name: "[`konghq.com/tls-verify-depth`](#konghq-com-tls-verify-depth)"
    description: "Maximum certificate chain depth when verifying the upstream service's TLS certificate"
{% endtable %}

## konghq.com/protocol

Sets the protocol {{site.base_gateway}} uses to communicate with the upstream Kubernetes service.

Accepted values:

- `http`
- `https`
- `grpc`
- `grpcs`
- `tcp`
- `tls`

Sample usage:

```yaml
konghq.com/protocol: "https"
```

## konghq.com/path

Prepends an HTTP path segment to every request forwarded to the upstream service.

For example, if the annotation is set to `/api` and the incoming request path is `/orders/123`, the upstream service receives `/api/orders/123`.

Sample usage:

```yaml
konghq.com/path: "/api"
```

## konghq.com/host-header

Sets the value of the `Host` header sent to the upstream service. By default, {{site.base_gateway}} sets `Host` to the IP address of the individual Pod target.

This annotation overrides that default with a static hostname, which is useful when upstream services perform host-based virtual hosting.

Sample usage:

```yaml
konghq.com/host-header: "internal.example.com"
```

## konghq.com/client-cert

Sets the TLS client certificate and key pair that {{site.base_gateway}} presents to the upstream service when the upstream requires mutual TLS (mTLS) authentication.

The value must be the name of a Kubernetes `Secret` of type `kubernetes.io/tls` in the same namespace as the `Service`.

Sample usage:

```yaml
konghq.com/client-cert: "my-client-cert-secret"
```

## konghq.com/upstream-policy

Attaches a `KongUpstreamPolicy` resource to the `Service`, allowing fine-grained control over load balancing behavior such as algorithm selection, consistent hashing, and health checks.

The value is the name of a `KongUpstreamPolicy` object in the same namespace as the `Service`. See the [KongUpstreamPolicy reference](/kubernetes-ingress-controller/reference/custom-resources/#kongupstreampolicy) for the full list of configuration fields.

Sample usage:

```yaml
konghq.com/upstream-policy: "my-upstream-policy"
```

## konghq.com/connect-timeout

Sets the timeout for completing a TCP connection to the upstream service, in milliseconds. If the connection cannot be established within this time, {{site.base_gateway}} returns an error to the client.

Sample usage:

```yaml
konghq.com/connect-timeout: "3000"
```

## konghq.com/read-timeout

Sets the timeout for receiving the first byte of an HTTP response from the upstream service after sending the request, in milliseconds.

Sample usage:

```yaml
konghq.com/read-timeout: "10000"
```

## konghq.com/write-timeout

Sets the timeout for sending data to the upstream service before closing the connection, in milliseconds.

Sample usage:

```yaml
konghq.com/write-timeout: "10000"
```

## konghq.com/retries

Sets the maximum number of times {{site.base_gateway}} retries a failed request to the upstream service. A request is retried if the upstream returns a connection failure or timeout.

Sample usage:

```yaml
konghq.com/retries: "3"
```

## konghq.com/tls-verify

Enables or disables verification of the upstream service's TLS certificate when `konghq.com/protocol` is set to `https` or `grpcs`. Accepted values are `"true"` or `"false"`. Verification is disabled by default.

Sample usage:

```yaml
konghq.com/tls-verify: "true"
```

## konghq.com/tls-verify-depth

Sets the maximum certificate chain depth when verifying the upstream service's TLS certificate. If not set, the system default is used.

Sample usage:

```yaml
konghq.com/tls-verify-depth: "3"
```
