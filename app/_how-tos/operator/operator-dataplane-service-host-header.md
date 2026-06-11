---
title: Set the Host header sent to a Service
description: "Learn how to override the Host header that {{ site.base_gateway }} sends to upstream services using the konghq.com/host-header annotation."
content_type: how_to

permalink: /operator/dataplanes/how-to/set-host-header/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem
  - konnect

min_version:
  operator: '2.2'

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway
    - title: Create a Service and a Route
      include_content: /prereqs/operator/httpbin-service-route

tldr:
  q: How do I override the Host header sent to an upstream service with {{ site.operator_product_name }}?
  a: |
    Annotate the Kubernetes `Service` with `konghq.com/host-header: "your-hostname"`. {{ site.base_gateway }} will use this value as the `Host` header when forwarding requests upstream instead of the Pod IP address.

related_resources:
  - text: Service annotations reference
    url: /operator/dataplanes/reference/service-annotations/
---

By default, {{site.base_gateway}} sets the `Host` header to the IP address of the individual Pod it is forwarding the request to. Some upstream services perform host-based virtual hosting or access control and require a specific `Host` header value. You can override this behavior using the `konghq.com/host-header` annotation.

## Check the default behavior

1. Get the Gateway's external IP address:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Send a request to the `/headers` endpoint, which returns all request headers received by the upstream service:

   ```bash
   curl -s $PROXY_IP/httpbin/headers
   ```

   The response shows the headers the upstream received. The `Host` header will contain the Pod IP address assigned by {{site.base_gateway}}:

   ```json
   {
     "headers": {
       "Host": "10.0.0.5",
       ...
     }
   }
   ```

## Annotate the Service

Annotate the `httpbin` Service to set a custom `Host` header:

```bash
kubectl annotate service httpbin -n kong \
  konghq.com/host-header="internal.example.com"
```

## Validate

Send the same request again:

```bash
curl -s $PROXY_IP/httpbin/headers
```

The `Host` header in the upstream request now reflects the configured value:

```json
{
  "headers": {
    "Host": "internal.example.com",
    ...
  }
}
```

{:.info}
> **Note**: If the client-side `Host` header must be preserved instead, use the `konghq.com/preserve-host: "true"` annotation on the `HTTPRoute` or `Ingress` resource. When `preserve-host` is set to `true`, it takes precedence over `konghq.com/host-header`.
