---
title: Customize Data Plane Configuration
description: "Learn how to customize the Kong Gateway Data Plane using environment variables and custom images."
content_type: how_to
permalink: /operator/dataplanes/how-to/customize-configuration/
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
  q: How do I change the Kong image or set environment variables?
  a: Use the `dataPlaneOptions.deployment.podTemplateSpec` field in your `GatewayConfiguration`.
---

## Overview

You may need to customize the underlying `DataPlane` deployment for various reasons:
- **Environment Variables**: To configure Kong parameters not exposed directly in the CRDs (e.g., `KONG_LOG_LEVEL`, `KONG_Trusted_IPS`).
- **Custom Images**: To use a specific version of Kong Gateway or a custom Enterprise image.
- **Resources**: To adjust CPU and memory requests/limits.

These customizations are handled via the `GatewayConfiguration` resource.

## Configuration

### 1. Create a GatewayConfiguration

You can use the `podTemplateSpec` within `dataPlaneOptions` to inject standard Kubernetes pod settings.

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: custom-config
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong:3.9-ubuntu
            env:
            - name: KONG_LOG_LEVEL
              value: "debug"
            - name: KONG_HEADER_FILTER_BY_LUA
              value: "return" # Disable a specific header or feature
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
```

### 2. Configure the Gateway

Update your `Gateway` to reference these options.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong-custom
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: custom-config
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-custom
  namespace: kong
spec:
  gatewayClassName: kong-custom
  listeners:
  - name: http
    protocol: HTTP
    port: 80
```

## Verify the Customization

1.  Check the deployed Pod to confirm the image and environment variables are set:

    ```bash
    # Get the pod name
    POD_NAME=$(kubectl get pods -n kong -l gateway-operator.konghq.com/gateway-name=kong-custom -o jsonpath='{.items[0].metadata.name}')

    # Verify Image
    kubectl get pod $POD_NAME -n kong -o jsonpath='{.spec.containers[0].image}'
    # Expected: kong:3.9-ubuntu

    # Verify Environment Variable
    kubectl get pod $POD_NAME -n kong -o jsonpath='{.spec.containers[0].env[?(@.name=="KONG_LOG_LEVEL")].value}'
    # Expected: debug
    ```

2.  Check the logs to see the effect (e.g., debug logs):

    ```bash
    kubectl logs $POD_NAME -n kong
    ```
