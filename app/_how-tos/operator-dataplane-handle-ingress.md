---
# @TODO KO 2.1
title: Handle Kubernetes Ingress
description: "Configure {{ site.operator_product_name }} to manage traditional Kubernetes Ingress resources."
content_type: how_to

permalink: /operator/dataplanes/how-to/handle-ingress/
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

tldr:
  q: How do I configure {{ site.operator_product_name }} to handle Kubernetes Ingress resources?
  a: Set the `ingressClass` field in the `ControlPlane` resource to match your `Ingress` resource's `ingressClassName`.

---

## Overview

While the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) is the preferred mechanism for configuring inbound routing, {{ site.operator_product_name }} continues to support the [Kubernetes Ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/).

When you use {{ site.operator_product_name }} to manage your Ingress traffic, it creates a `ControlPlane` (serving as the controller) and a `DataPlane` (serving as the {{ site.base_gateway }}). The `ControlPlane` is configured to listen for `Ingress` resources with a specific `IngressClass`.

## Prerequisites

- Access to a Kubernetes cluster.
- `kubectl` installed.
- `helm` installed.

## Install the Kong Operator

Install {{ site.operator_product_name }} using Helm:

```bash
helm upgrade --install kong-operator kong/kong-operator -n kong-system --create-namespace
```

## Configure Ingress Handling

To handle `Ingress` resources, you need to create a `GatewayConfiguration`, a `DataPlane`, and a `ControlPlane`.

### Create the GatewayConfiguration

The `GatewayConfiguration` allows you to customize the deployment options for your `DataPlane` and `ControlPlane`.

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-ingress-config
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      replicas: 1
' | kubectl apply -f -
```

### Create the DataPlane

The `DataPlane` resource defines the {{ site.base_gateway }} deployment.

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: kong-ingress-dp
  namespace: kong
spec:
  deployment:
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong:3.9
' | kubectl apply -f -
```

### Create the ControlPlane

The `ControlPlane` resource defines the controller that will manage the `DataPlane`. To enable Ingress support, you must specify the `ingressClass` field.

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: kong-ingress-cp
  namespace: kong
spec:
  dataplane:
    type: ref
    ref:
      name: kong-ingress-dp
  ingressClass: kong
' | kubectl apply -f -
```

## Deploy a Sample Application

To test the Ingress setup, deploy the standard Kong echo service and an `Ingress` resource.

### Create the Echo Service

```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

### Create the Ingress resource

Create an `Ingress` resource that uses the `ingressClassName` matching the one configured in the `ControlPlane`, pointing to the `echo` service.

```yaml
echo '
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-ingress
  namespace: kong
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echo
            port:
              number: 1027
' | kubectl apply -f -
```

## Verify the Setup

1. Check the status of the `ControlPlane` and `DataPlane`:

   ```bash
   kubectl get controlplane,dataplane -n kong
   ```

2. Check the Ingress resource:

   ```bash
   kubectl get ingress echo-ingress -n kong
   ```

3. (Optional) If your cluster supports LoadBalancers, you can find the external IP of the `DataPlane` service and test the routing:

   ```bash
   export PROXY_IP=$(kubectl get svc -n kong -l app=kong-ingress-dp,gateway-operator.konghq.com/dataplane-service-type=ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
   curl -i http://$PROXY_IP/
   ```
