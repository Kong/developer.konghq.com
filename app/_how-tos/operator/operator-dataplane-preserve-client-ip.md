---
title: Preserve client IP addresses
description: "Learn how to configure {{site.operator_product_name}} to preserve the original client IP address using externalTrafficPolicy."
content_type: how_to
permalink: /operator/dataplanes/how-to/preserve-client-ip/
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

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

tldr:
  q: How do I see the real client IP in Kong logs?
  a: "Configure `externalTrafficPolicy: Local` in your `GatewayConfiguration`."
---

By default, when traffic enters a Kubernetes cluster through a Service of type `LoadBalancer`, the source IP is often replaced with the IP of the node (SNAT). This means your applications and access logs see the node's IP instead of the client's IP.

To preserve the client IP, you can configure the underlying Service to use `externalTrafficPolicy: Local`.

{% include /k8s/kong-namespace.md %}

## Create a GatewayConfiguration

Create a `GatewayConfiguration` that sets the `externalTrafficPolicy` to `Local` in the `dataPlaneOptions`:

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: preserve-client-ip
  namespace: kong
spec:
  dataPlaneOptions:
    network:
      services:
        ingress:
          externalTrafficPolicy: Local
          type: LoadBalancer' | kubectl apply -f -
```

### Configure the Gateway

Create a `GatewayClass` resource that references the `GatewayConfiguration`, and a `Gateway` that references the `GatewayClass`:

```yaml
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong-external-traffic
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: preserve-client-ip
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-external-traffic
  namespace: kong
spec:
  gatewayClassName: kong-external-traffic
  listeners:
  - name: http
    protocol: HTTP
    port: 80' | kubectl apply -f -
```

## Validate

1.  Check the generated Service for the `externalTrafficPolicy` setting:

    ```bash
    kubectl get service -n kong -l gateway-operator.konghq.com/dataplane-service-type=ingress -o jsonpath='{.items[0].spec.externalTrafficPolicy}'
    ```

    The output should be `Local`.

