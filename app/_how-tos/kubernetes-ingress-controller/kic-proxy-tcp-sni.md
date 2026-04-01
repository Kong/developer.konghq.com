---
title: Proxy TCP traffic over TLS by SNI
description: "Use TLSRoute to route TCP traffic secured by TLS"
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
  a: Create a `TLSRoute` resource, which will then be converted in to a [{{ site.base_gateway }} Service](/gateway/entities/service/) and [Route](/gateway/entities/route/). TLS passthrough is _not_ supported using `TCPIngress`.

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

## Attach the TLS certificate to the echo service

The `echo` service does not listen on the TLS port by default as it requires a certificate stored in a Kubernetes Secret. Patch the `echo` deployment to mount the Secret in the pod and set the `TLS_CERT_FILE` and `TLS_KEY_FILE` environment variables to allow the `echo` service to terminate TLS:

```bash
kubectl patch -n kong --type=json deployment echo -p='[
    {
        "op":"add",
        "path":"/spec/template/spec/containers/0/env/-",
        "value":{
            "name": "TLS_PORT",
            "value": "1030"
        }
    },
    {
        "op":"add",
        "path":"/spec/template/spec/containers/0/env/-",
        "value":{
            "name": "TLS_CERT_FILE",
            "value": "/var/run/certs/tls.crt"
        }
    },
    {
        "op":"add",
        "path":"/spec/template/spec/containers/0/env/-",
        "value":{
            "name": "TLS_KEY_FILE",
            "value": "/var/run/certs/tls.key"
        }
    },
    {
        "op":"add",
        "path":"/spec/template/spec/containers/0/volumeMounts",
        "value":[{
            "mountPath": "/var/run/certs",
            "name": "secret-test",
            "readOnly": true
        }]
    },
    {
        "op":"add",
        "path":"/spec/template/spec/volumes",
        "value":[{
            "name": "secret-test",
            "secret": {
              "defaultMode": 420,
              "secretName": "tls9443.kong.example"
            }
        }]
    }
]'
```

## Route TCP traffic

To reconcile the `TLSRoute`, configure an additional TLS listener on your `Gateway` resource:

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
              "mode": "Passthrough",
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
        port: 1030
" | kubectl apply -f -
```

This configuration instructs {{site.base_gateway}} to forward all traffic it receives on port 9000 to the `echo` service on port 1030.

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
