---
# @TODO KO 2.1
title: Mirror an existing Konnect Control Plane
description: "Configure {{ site.operator_product_name }} to connect to an existing Konnect Control Plane by ID."
content_type: how_to

permalink: /operator/konnect/how-to/mirror-control-plane/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

tldr:
  q: How do I use an existing Konnect Control Plane with {{ site.operator_product_name }}?
  a: Set `spec.konnect.source` to `Mirror` and provide the Control Plane ID in `spec.konnect.mirror.konnect.id` within your `GatewayConfiguration`.

---

## Overview

By default, {{ site.operator_product_name }} creates and manages the lifecycle of Control Planes in {{ site.konnect_short_name }}. However, in some scenarios, you may want to manage your Control Plane configuration outside of the operator (via the {{ site.konnect_short_name }} UI or {{ site.konnect_short_name }} API API) but still use the operator to manage the deployment of the Data Planes.

Using the `Mirror` source type in a `GatewayConfiguration` allows the operator to connect to an existing {{ site.konnect_short_name }} Control Plane by its unique ID.

## Prerequisites

- An existing Control Plane in {{ site.konnect_short_name }} with the ID you want to mirror.
- A valid {{ site.konnect_short_name }} API authentication token (PAT).

## Configuration

The following example demonstrates how to configure the operator to mirror an existing Control Plane.

### 1. Create Authentication Credentials

Create a `KonnectAPIAuthConfiguration` resource containing your {{ site.konnect_short_name }} API token. Ensure the `serverURL` matches your {{ site.konnect_short_name }} region.

```yaml
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth
  namespace: kong
spec:
  type: token
  # Replace with your actual {{ site.konnect_short_name }} API token
  token: kpat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  # Update with your {{ site.konnect_short_name }} region: us.api.konghq.tech, eu.api.konghq.tech, au.api.konghq.tech, etc.
  serverURL: us.api.konghq.tech
```

### 2. Configure the Gateway to Mirror the Control Plane

In your `GatewayConfiguration`, set `spec.konnect.source` to `Mirror` and provide the ID of the existing {{ site.konnect_short_name }} Control Plane.

```yaml
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/v2beta1
metadata:
  name: mirror-gateway-configuration
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth
    source: Mirror
    mirror:
      konnect:
        # Replace with your actual {{ site.konnect_short_name }} Control Plane ID
        id: xxx-xxx-xxx-xxx
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - image: kong/kong-gateway:3.12
              name: proxy
```

### 3. Define the GatewayClass and Gateway

Create a `GatewayClass` that references your mirrored configuration, and a `Gateway` that uses that class.

```yaml
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong-mirror
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: mirror-gateway-configuration
    namespace: kong
---
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong-mirror-gateway
  namespace: kong
spec:
  gatewayClassName: kong-mirror
  listeners:
    - name: http
      protocol: HTTP
      port: 80
```

## Verify the Connection

You can test that the mirrored Control Plane is correctly syncing configuration to the managed Data Planes by deploying a sample service and an `HTTPRoute`.

### 1. Deploy the standard echo service

```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

### 2. Create an HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httproute-echo
  namespace: kong
spec:
  parentRefs:
    - name: kong-mirror-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo
          kind: Service
          port: 80
```
