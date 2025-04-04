---
title: Proxy TCP traffic by SNI
published: false
description: "Use `TLSRoute` or `TCPIngress` to route TCP traffic secured by TLS"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/tcp-by-sni/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I route TCP traffic with {{ site.kic_product_name }}?
  a: Create a `TCPRoute` or `TCPIngress` resource, which will then be converted in to a [{{ site.base_gateway }} Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  kubernetes:
    gateway_api: experimental
  entities:
    services:
      - echo-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

{% include /k8s/configure-tcp-listen.md plaintext=false tls=true %}

## Generate a TLS certificate

{% include /k8s/create-certificate.md namespace='kong' hostname='tls9443.kong.example' cert_required=true %}

## Route TCP traffic

To publicly expose the service, create a `TCPRoute` resource for Gateway APIs or a `TCPIngress` resource for Ingress.

{% navtabs api %}
{% navtab "Gateway API" %}

To reconcile the `TCPRoute`, configure an additional TLS listener on your `Gateway` resource:

```bash
kubectl patch -n kong --type=json gateway kong -p='[
    {
        "op":"add",
        "path":"/spec/listeners/-",
        "value":{
            "name":"stream9443",
            "port":9443,
            "protocol":"TLS",
            "hostname":"tls9443.kong.example",
            "allowedRoutes": {
              "namespaces": {
                "from": "All"
              }
            },
            "tls": {
                "certificateRefs":[{
                    "group":"",
                    "kind":"Secret",
                    "name":"tls9443.kong.example"
                  }]
            }
        }
    }
]'
```

Next, create a `TLSRoute`:

```bash
echo "apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: echo-tls
  namespace: kong
spec:
  parentRefs:
    - name: kong
      sectionName: stream9443
  hostnames:
    - tls9443.kong.example
  rules:
    - backendRefs:
      - name: echo
        port: 1025
" | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Ingress" %}
```bash
echo "apiVersion: configuration.konghq.com/v1beta1
kind: TCPIngress
metadata:
  name: echo-tls
  namespace: kong
  annotations:
    kubernetes.io/ingress.class: kong
spec:
  tls:
  - secretName: tls9443.kong.example
    hosts:
      - tls9443.kong.example
  rules:
  - host: tls9443.kong.example
    port: 9443
    backend:
      serviceName: echo
      servicePort: 1025
" | kubectl apply -f -
" | kubectl apply -f -
```

{% endnavtab %}
{% endnavtabs %}

This configuration instructs {{site.base_gateway}} to forward all traffic it
receives on port 9000 to the `echo` service on port 1025.

## Validate your configuration

You can now access the `echo` service on port 9443 with SNI `tls9443.kong.example`.

In real-world usage, you would create a DNS record for `tls9443.kong.example` pointing to your proxy Service's public IP address, which causes TLS clients to add a SNI automatically. For this demo, add it manually using the OpenSSL CLI.

```bash
echo "hello" | openssl s_client -connect $PROXY_IP:9443 -servername tls9443.kong.example -quiet 2>/dev/null
```
Press Ctrl+C to exit.

The results should look like this:
```text
Welcome, you are connected to node kind-control-plane.
Running on Pod echo-5f44d4c6f9-krnhk.
In namespace default.
With IP address 10.244.0.26.
hello
```