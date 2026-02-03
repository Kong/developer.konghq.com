---
title: Preserve Client IP Addresses
description: "Learn how to configure the Kong Gateway Operator to preserve the original client IP address using externalTrafficPolicy."
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
tldr:
  q: How do I see the real client IP in Kong logs?
  a: Configure `externalTrafficPolicy: Local` in your `GatewayConfiguration`.
---

## Overview

By default, when traffic enters a Kubernetes cluster through a Service of type `LoadBalancer`, the source IP is often replaced with the IP of the node (SNAT). This means your applications and access logs see the node's IP instead of the client's IP.

To preserve the client IP, you can configure the underlying Service to use `externalTrafficPolicy: Local`.

## Configuration

You can configure the generated `Service` for the Data Plane using `GatewayConfiguration`.

### 1. Create a GatewayConfiguration

Create a `GatewayConfiguration` that sets the `externalTrafficPolicy` to `Local` in the `dataPlaneOptions`.

```yaml
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
          # Set the externalTrafficPolicy to Local to preserve the client IP
          externalTrafficPolicy: Local
          type: LoadBalancer
          annotations:
            # Example annotation for cloud providers (optional)
            # service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

### 2. Configure the Gateway

Update your `Gateway` to reference the `GatewayConfiguration`.

```yaml
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
    port: 80
```

## Verify the Configuration

1.  Check the generated Service for the `externalTrafficPolicy` setting:

    ```bash
    kubectl get service -n kong -l gateway-operator.konghq.com/dataplane-service-type=ingress -o jsonpath='{.items[0].spec.externalTrafficPolicy}'
    ```
    
    The output should be `Local`.

