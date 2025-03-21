---
title: Proxy GRPC Traffic over HTTP
description: "Route GRPC requests over HTTP to services in your cluster using GRPCRoute"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/grpc-over-http/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - /kubernetes-ingress-controller/routing/

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I route gRPC traffic with Kong Ingress Controller?
  a: Create a `GRPCRoute` resource, which will then be converted in to a {{ site.base_gateway }} Service and Route

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - grpcbin-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kic.svg
---

## gRPC over HTTP

All services are assumed to be either HTTP or HTTPS by default. We need to update the service to specify gRPC as the protocol by adding a `konghq.com/protocol` annotation.

The annotation `grpc` informs Kong that this service is a gRPC (with TLS) service and not a HTTP service.

```bash
kubectl annotate service -n kong grpcbin 'konghq.com/protocol=grpc'
```

For gRPC over HTTP (plaintext without TLS), configuration of {{site.base_gateway}} needs to be adjusted. By default {{site.base_gateway}} accepts HTTP/2 traffic with TLS on port `443`. And HTTP/1.1 traffic on port `80`. To accept HTTP/2 (which is required by gRPC standard) traffic without TLS on port `80`, the configuration has to be adjusted.

```bash
kubectl set env deployment/kong-gateway -n kong 'KONG_PROXY_LISTEN=0.0.0.0:8000 http2, 0.0.0.0:8443 http2 ssl'
```

**Caveat:** {{site.base_gateway}} 3.6.x and earlier doesn't offer simultaneous support of HTTP/1.1 and HTTP/2 without TLS on a single TCP socket. Hence it's not possible to connect with HTTP/1.1 protocol, requests will be rejected. For HTTP/2 with TLS everything works seamlessly (connections are handled transparently). You may configure an alternative HTTP/2 port (e.g. `8080`) if you require HTTP/1.1 traffic on port 80.  Since {{site.base_gateway}} 3.6.x, {{site.base_gateway}} is able to support listening HTTP/2 without TLS(h2c) and HTTP/1.1 on the same port, so you can use port 80 for both HTTP/1.1 and HTTP/2 without TLS.

## Route gRPC traffic

Now that the test application is running, you can create GRPC routing configuration that
proxies traffic to the application:

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

This annotation informs Kong that this Ingress routes gRPC (with TLS) traffic and not a HTTP traffic.

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
