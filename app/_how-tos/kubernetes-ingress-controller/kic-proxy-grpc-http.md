---
title: Proxy GRPC Traffic over HTTP
description: "Use GRPCRoute to route traffic to a plain text GRPC listener"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/grpc-over-http/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

works_on:
  - on-prem
  - konnect

entities:
  - service
  - route

tags:
  - grpc
  - routing

tldr:
  q: How do I route gRPC traffic with {{ site.kic_product_name }}?
  a: Create a `GRPCRoute` resource, which will then be converted in to a [{{ site.base_gateway }} Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - grpcbin-service
  inline:
    - title: gRPCurl installed
      include_content: prereqs/grpcurl
      icon_url: /assets/icons/code.svg 

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## gRPC over HTTP

All Gateway Services are assumed to be either HTTP or HTTPS by default. We need to update the Service to specify gRPC as the protocol by adding a `konghq.com/protocol` annotation.

Annotate the `grpcbin` Service you installed in the [prerequisites](#prerequisites) with `grpc` to inform {{site.base_gateway}} that this service is a gRPC (with TLS) service and not an HTTP service:

```bash
kubectl annotate service -n kong grpcbin 'konghq.com/protocol=grpc'
```

{{site.base_gateway}} accepts HTTP/2 traffic with TLS on port `443`, and HTTP/1.1 traffic on port `80` by default. To accept HTTP/2 traffic (which is required by the gRPC standard) over HTTP (plaintext without TLS) on port `80` the configuration has to be adjusted.

```bash
kubectl set env deployment/kong-gateway -n kong 'KONG_PROXY_LISTEN=0.0.0.0:8000 http2, 0.0.0.0:8443 http2 ssl'
```

{:.info}
> **Caveat:** {{site.base_gateway}} 3.6.x and earlier do not offer simultaneous support of HTTP/1.1 and HTTP/2 without TLS on a single TCP socket. You may configure an alternative HTTP/2 port (e.g. `8080`) if you require HTTP/1.1 traffic on port 80.
>
> {{site.base_gateway}} 3.6.x and later supports listening HTTP/2 without TLS and HTTP/1.1 on the same port, allowing use of port 80 for both HTTP/1.1 and HTTP/2 without TLS.

## Route gRPC traffic

Now that the test application is running, you can create a GRPC routing configuration that
proxies traffic to the application.

{% navtabs api %}
{% navtab "Gateway API" %}
Create a `GRPCRoute`:

```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: grpcbin
  namespace: kong
spec:
  parentRefs:
  - name: kong
  hostnames:
  - "example.com"
  rules:
  - backendRefs:
    - name: grpcbin
      port: 9000
' | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Ingress" %}

All Ingresses are assumed to be either HTTP or HTTPS by default. We need to update the `Ingress` to specify gRPC as the protocol by adding a `konghq.com/protocols` annotation.

This annotation informs {{site.base_gateway}} that this Ingress routes gRPC (with TLS) traffic and not HTTP traffic.

```bash
echo "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grpcbin
  namespace: kong
  annotations:
    konghq.com/protocols: grpc
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grpcbin
            port:
              number: 9000" | kubectl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## Test the configuration

{% validation grpc-check %}
method: hello.HelloService.SayHello
authority: example.com
port: 80
plaintext: true
payload: |-
  {"greeting": "Kong"}
response: |-
  {
    "reply": "hello Kong"
  }
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
