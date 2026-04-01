---
title: Proxy GRPC Traffic over TLS
description: "Use GRPCRoute to route traffic to a service secured with TLS"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/grpc/
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
  - tls
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

## Annotate the Kubernetes service

All services are assumed to be either HTTP or HTTPS by default. We need to update the service to specify gRPC over TLS as the protocol by adding a `konghq.com/protocol` annotation.

The annotation `grpcs` informs {{site.base_gateway}} that this service is a gRPC (with TLS) service and not an HTTP service.

```bash
kubectl annotate service -n kong grpcbin 'konghq.com/protocol=grpcs'
```

## Generate a TLS certificate

{% include /k8s/create-certificate.md namespace='kong' hostname='example.com' cert_required=true %}

## Route gRPC traffic

Now that the test application is running, you can create GRPC routing configuration that
proxies traffic to the application.

{% navtabs api %}
{% navtab "Gateway API" %}
To reconcile the `GRPCRoute`, configure an additional TLS listener configured on your `Gateway` resource:

```bash
kubectl patch -n kong --type=json gateway kong -p='[
    {
        "op":"add",
        "path":"/spec/listeners/-",
        "value":{
            "name":"grpc",
            "port":443,
            "protocol":"HTTPS",
            "hostname":"example.com",
            "tls": {
                "certificateRefs":[{
                    "group":"",
                    "kind":"Secret",
                    "name":"example.com"
                 }]
            }
        }
    }
]'
```

Next, create a `GRPCRoute`:

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
      port: 9001
' | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Ingress" %}

All routes and services are assumed to be either HTTP or HTTPS by default. We need to update the service to specify gRPC as the protocol by adding a `konghq.com/protocols` annotation.

This annotation informs {{site.base_gateway}} that this Ingress routes gRPC (with TLS) traffic and not HTTP traffic.

```bash
echo "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grpcbin
  namespace: kong
  annotations:
    konghq.com/protocols: grpcs
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
              number: 9001" | kubectl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

## Test the configuration

{% validation grpc-check %}
method: hello.HelloService.SayHello
authority: example.com
port: 443
payload: |-
  {"greeting": "Kong"}
response: |-
  {
    "reply": "hello Kong"
  }
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
