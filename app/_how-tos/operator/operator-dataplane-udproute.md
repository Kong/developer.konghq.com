---
title: Proxy UDP traffic using UDPRoute
description: "Learn how to configure UDPRoute with {{ site.operator_product_name }} to route UDP traffic by port."
content_type: how_to

permalink: /operator/dataplanes/how-to/udproute/
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

min_version:
  operator: '2.3'

tldr:
  q: How do I route UDP traffic with {{ site.operator_product_name }}?
  a: Add a `UDP` listener to your `Gateway`, then create a `UDPRoute` resource. {{ site.operator_product_name }} converts the `UDPRoute` into a {{ site.base_gateway }} [Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  skip_product: true

---

`UDPRoute` is a Kubernetes Gateway API resource for routing UDP traffic by port. This guide shows how to configure {{ site.operator_product_name }} to proxy UDP traffic to a backend Service.

{% include k8s/kong-namespace.md %}

## Configure the Gateway

Create a `GatewayConfiguration`, `GatewayClass`, and `Gateway` with an `HTTP` listener:

```bash
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-gateway-configuration
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
              name: proxy
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong-udp
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong-gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-udp-gateway
  namespace: kong
spec:
  gatewayClassName: kong-udp
  listeners:
    - name: http
      port: 80
      protocol: HTTP' | kubectl apply -f -
```

## Deploy a UDP backend

Install the `tftp` Service, a small TFTP test server that listens over UDP:

```bash
kubectl apply -f {{site.links.web}}/manifests/kic/udp-service.yaml -n kong
```

## Route UDP traffic

Re-apply the `kong-udp-gateway` Gateway with an additional `UDP` listener:

{:.warning}
> **Warning**: Applying this Gateway replaces the listener list. Include every listener you want to keep.

```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-udp-gateway
  namespace: kong
spec:
  gatewayClassName: kong-udp
  listeners:
    - name: http
      port: 80
      protocol: HTTP
    - name: stream9999
      port: 9999
      protocol: UDP
      allowedRoutes:
        namespaces:
          from: All' | kubectl apply -f -
```

Next, create a `UDPRoute`:

```bash
echo "apiVersion: gateway.networking.k8s.io/v1
kind: UDPRoute
metadata:
  name: tftp
  namespace: kong
spec:
  parentRefs:
    - name: kong-udp-gateway
      sectionName: stream9999
  rules:
    - backendRefs:
        - name: tftp
          port: 9999
" | kubectl apply -f -
```

This configuration instructs {{ site.base_gateway }} to forward UDP traffic it receives on port `9999` to the `tftp` Service on port `9999`.

## Validate

1. Check the status of the Gateway to ensure the listeners are programmed:

   ```bash
   kubectl get gateway kong-udp-gateway -n kong -o jsonpath='{.status.listeners}'
   ```

1. Get the Gateway's external IP:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong-udp-gateway -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Send a TFTP request through the proxy:

   ```bash
   curl -s tftp://$PROXY_IP:9999/hello
   ```

   The results should look like this:

   ```text
   Hostname: tftp-5849bfd46f-nqk9x

   Request Information:
     client_address=10.244.0.1
     client_port=39364
     real path=/hello
     request_scheme=tftp
   ```
   {:.no-copy-code}
