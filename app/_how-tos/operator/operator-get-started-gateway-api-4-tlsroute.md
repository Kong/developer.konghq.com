---
title: Proxy TLS traffic by SNI using TLSRoute
description: "Use TLSRoute with {{ site.operator_product_name }} to route TCP traffic secured by TLS."
content_type: how_to

permalink: /operator/get-started/gateway-api/create-tlsroute/
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

min_version:
  operator: '2.2'

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

{:.info}
> {{ site.operator_product_name }} only reconciles `TLSRoute` resources using the `gateway.networking.k8s.io/v1` API, which is available in [Gateway API](https://gateway-api.sigs.k8s.io/) 1.5 or later (standard channel). If you installed the CRDs from an earlier release while following [step 1 of this series](/operator/get-started/gateway-api/install/), upgrade {{ site.operator_product_name }} to the version that supports `TLSRoute`. It will install or upgrade gateway API CRDs with the appropriate version. If you did not install gateway API CRDs by the {{ site.operator_product_name }} helm release, install or upgrade them manually:
> 
> 

## Generate a TLS certificate

{% include /k8s/create-certificate.md namespace='kong' hostname='tls9443.kong.example' cert_required=true %}

## Attach the TLS certificate to the echo Service

The `echo` Service we deployed in a [previous step](/operator/get-started/gateway-api/create-route/#create-a-backend-service) doesn't listen on the TLS port by default as it requires a certificate stored in a Kubernetes Secret. Patch the `echo` Deployment to mount the Secret in the pod and set the `TLS_CERT_FILE` and `TLS_KEY_FILE` environment variables to allow the `echo` Service to terminate TLS:

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

## Route TCP traffic with TLS

Re-apply the `kong` Gateway with the additional `stream9443` TLS listener in `Passthrough` mode:

```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: kong
  listeners:
    - name: http
      protocol: HTTP
      port: 80
    - name: stream9443
      port: 9443
      protocol: TLS
      hostname: tls9443.kong.example
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Passthrough' | kubectl apply -f -
```

Next, create a `TLSRoute`:

```bash
echo "apiVersion: gateway.networking.k8s.io/v1
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

The results should look like this:

```text
Welcome, you are connected to node kind-control-plane.
Running on Pod echo-5f44d4c6f9-krnhk.
In namespace default.
With IP address 10.244.0.26.
hello
```
{:.no-copy-code}

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

Reapply the `kong` Gateway with a `stream9444` TLS listener in `Terminate` mode, referencing the labeled Secret:

{:.warning}
> **Warning**: Applying this Gateway replaces the listener list. If you completed the Passthrough walkthrough above, the `stream9443` listener will be removed and the `echo-tls` `TLSRoute` will no longer attach to a parent. Run `kubectl delete tlsroute echo-tls -n kong` to remove the leftover route if you only want the Terminate demo running.

```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: kong
  listeners:
    - name: http
      protocol: HTTP
      port: 80
    - name: stream9444
      port: 9444
      protocol: TLS
      hostname: tls9444.kong.example
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRefs:
          - group: ""
            kind: Secret
            name: tls9444.kong.example' | kubectl apply -f -
```

### Create a TLSRoute for the Terminate listener

Because Kong is now terminating TLS, the backend can receive plain TCP. Point the `TLSRoute` at the unmodified `echo` Service on its default plain TCP port `1025`:

```bash
echo "apiVersion: gateway.networking.k8s.io/v1
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
        port: 1025
" | kubectl apply -f -
```

### Validate the Terminate listener

Reuse the `$PROXY_IP` you exported earlier and connect to the new listener:

```bash
echo "hello" | openssl s_client -connect $PROXY_IP:9444 -servername tls9444.kong.example -quiet 2>/dev/null
```

You should see similar output as previously shown in the example using `Passthrough` TLS mode.

Unlike the Passthrough case, the TLS handshake terminates at {{ site.base_gateway }}: the certificate presented to the client is the one stored in the labeled Secret, not a certificate served by the `echo` backend. You can confirm this by dropping the `-quiet` flag and inspecting the `subject=` line in the openssl output — it should match `CN=tls9444.kong.example`.
