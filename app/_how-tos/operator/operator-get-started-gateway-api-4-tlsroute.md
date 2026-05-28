---
title: Proxy TCP traffic over TLS by SNI
description: "Use TLSRoute with {{ site.operator_product_name }} to route TCP traffic secured by TLS."
content_type: how_to

permalink: /operator/get-started/gateway-api/tlsroute/
series:
  id: operator-get-started-gateway-api
  position: 4

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "Get Started"

products:
  - operator

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I route TCP traffic with {{ site.operator_product_name }}?
  a: Add a `TLS` listener to your `Gateway` in either `Passthrough` or `Terminate` mode, then create a `TLSRoute` resource. {{ site.operator_product_name }} automatically reconciles the managed `DataPlane` stream listener and proxy Service port, and converts the `TLSRoute` into a {{ site.base_gateway }} [Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  skip_product: true

next_steps:
  - text: Learn about Custom resource definitions (CRDs)
    url: /operator/reference/custom-resources/
---

{{ site.operator_product_name }} reconciles the managed `DataPlane` from the `Gateway` listeners: when you add a `TLS` listener to your `Gateway`, Operator automatically sets the corresponding stream listener on the `DataPlane` and exposes the port on the proxy Service. The only Operator-specific step you need to take is updating the `Gateway`.

## Generate a TLS certificate

{% include /k8s/create-certificate.md namespace='kong' hostname='tls9443.kong.example' cert_required=true %}

## Attach the TLS certificate to the echo Service

If you haven't already deployed the `echo` Service, install it:

```bash
kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong
```

The `echo` Service does not listen on the TLS port by default as it requires a certificate stored in a Kubernetes Secret. Patch the `echo` Deployment to mount the Secret in the pod and set the `TLS_CERT_FILE` and `TLS_KEY_FILE` environment variables to allow the `echo` Service to terminate TLS:

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

To reconcile the `TLSRoute`, add a TLS listener to your `Gateway` resource:

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

This configuration instructs {{ site.base_gateway }} to forward all traffic it receives on port `9443` to the `echo` Service on port `1030`.

## Validate your configuration

Export the Gateway's external address:

```bash
export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
```

You can now access the `echo` Service on port `9443` with SNI `tls9443.kong.example`.

In real-world usage, you would create a DNS record for `tls9443.kong.example` pointing to your proxy Service's public IP address, which causes TLS clients to add an SNI automatically. For this demo, add it manually using the OpenSSL CLI:

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

## Terminate TLS at the listener

The previous sections used `tls.mode: Passthrough`, which forwards encrypted TLS bytes through {{ site.base_gateway }} so the backend completes the handshake. {{ site.operator_product_name }} also supports `tls.mode: Terminate`: {{ site.base_gateway }} terminates the client's TLS connection at the listener using a certificate you provide, then forwards plain TCP to the backend. Use this mode when you want Kong to apply plugins, observe traffic, or enforce TLS policy on the connection. The tradeoff is that the connection is no longer end-to-end encrypted.

The following sections walk through a second `TLSRoute` on a new listener (port `9444`) so it coexists with the Passthrough example above.

### Generate a TLS certificate for the Terminate listener

{% include /k8s/create-certificate.md namespace='kong' hostname='tls9444.kong.example' cert_required=true %}

### Label the certificate Secret

{{ site.operator_product_name }} only watches certificate Secrets that carry the `konghq.com/secret="true"` label. Add the label so Operator picks up the Secret you just created:

```bash
kubectl label secret tls9444.kong.example -n kong konghq.com/secret="true"
```

For more information about how {{ site.operator_product_name }} handles secrets, see the [Secrets reference](/operator/reference/secrets/).

### Add a Terminate TLS listener to the Gateway

Patch the existing `kong` Gateway to append a second TLS listener on port `9444` in `Terminate` mode, referencing the labelled Secret:

```bash
kubectl patch -n kong --type=json gateway kong -p='[
    {
        "op":"add",
        "path":"/spec/listeners/-",
        "value":{
            "name":"stream9444",
            "port":9444,
            "protocol":"TLS",
            "hostname":"tls9444.kong.example",
            "allowedRoutes": {
              "namespaces": {
                "from": "All"
              }
            },
            "tls": {
              "mode": "Terminate",
              "certificateRefs":[{
                "group":"",
                "kind":"Secret",
                "name":"tls9444.kong.example"
              }]
            }
        }
    }
]'
```

### Create a TLSRoute for the Terminate listener

Because Kong is now terminating TLS, the backend can receive plain TCP. Point the `TLSRoute` at the unmodified `echo` Service on its default plain TCP port `1027`:

```bash
echo "apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: echo-tls-terminate
  namespace: kong
spec:
  parentRefs:
    - name: kong
      sectionName: stream9444
  hostnames:
    - tls9444.kong.example
  rules:
    - backendRefs:
      - name: echo
        port: 1027
" | kubectl apply -f -
```

### Validate the Terminate listener

Reuse the `$PROXY_IP` you exported earlier and connect to the new listener:

```bash
echo "hello" | openssl s_client -connect $PROXY_IP:9444 -servername tls9444.kong.example -quiet 2>/dev/null
```

Press Ctrl+C to exit.

Unlike the Passthrough case, the TLS handshake terminates at {{ site.base_gateway }}: the certificate presented to the client is the one stored in the labelled Secret, not a certificate served by the `echo` backend. You can confirm this by dropping the `-quiet` flag and inspecting the `subject=` line in the openssl output — it should match `CN=tls9444.kong.example`.
