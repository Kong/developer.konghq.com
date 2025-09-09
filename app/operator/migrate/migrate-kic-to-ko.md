---
title: "Migrating from {{site.kic_product_name}} to Kong Operator 2.0.0"
description: "Complete migration guide from {{site.kic_product_name}} (KIC) to Kong Operator (KO) 2.0.0."
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
works_on:
  - on-prem
  - konnect
tags:
  - migration

related_resources:
  - text: "Kong Operator Changelog"
    url: /operator/changelog/
  - text: "Version Compatibility"
    url: /operator/reference/version-compatibility/

---

Kong Operator (KO) is next generation Kubernetes-native operator that simplifies the management of ingress controllers and Kong data planes.

In this guide, we will walk you through the steps to migrate from {{site.kic_product_name}} (KIC) to Kong Operator (KO) 2.0.0.

## Prerequisites

Before starting the migration, ensure you have:

1. **Backup your current configuration**

1. **Note down the current {{ site.base_gateway }} version that you use.**

1. **Access to Kubernetes cluster** with admin privileges

1. **Verify cert-manager is installed** (recommended for webhooks certificate management):

   {:.info}
   > **Note**: Kong Operator 2.0.0 uses webhooks that require TLS certificates managed by cert-manager. If cert-manager is not installed, follow the [cert-manager installation guide](https://cert-manager.io/docs/installation/) before proceeding.

## Migrate to Kong Operator 2.0.0

   {:.warning}
   > **Important**: This process involves down time. Plan your migration accordingly.

The migration process requires several manual steps due to breaking changes in certificate management and CRD structure. Follow these steps carefully:

### Step 1: Uninstall existing KIC Helm Release

Uninstall `helm` release which was used to deploy {{ site.base_gateway }} and {{ site.kic_product_name_short }}.

```bash
helm uninstall ${RELEASE_NAME} -n ${RELEASE_NAMESPACE}
```

### Step 2: Install KO

Install KO using `helm`

```bash
helm repo update kong
helm upgrade --install ko kong/kong-operator \
  -n kong-system \
  --create-namespace \
  --take-ownership \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --set ko-crds.enabled=true \
  --set global.conversionWebhook.certManager.enabled=true
```

### Step 3: Verify the Installation

Verify that Kong Operator 2.0.0 is running correctly:

```bash
# Check the operator deployment
kubectl get pod -n kong-system

# Check operator logs
kubectl logs -n kong-system -l app=ko-kong-operator
```

### Step 4: Prepare `Gateway` manifest to replace {{ site.base_gateway }} and {{ site.kic_product_name_short }}

KO uses CRDs to manage among other things: {{ site.base_gateway }} and the ingress controller.

What used to be a pair of {{ site.base_gateway }} and {{ site.kic_product_name_short }} deployed via `helm` is now modelled through Gateway API's `Gateway`.

You can learn more about it on [Gateway API website](https://gateway-api.sigs.k8s.io/api-types/gateway/).

To customize the `Gateway` manifest for your environment, you can use Kong's `GatewayConfiguration` CRD.

Please refer to the following example which can serve as a base for your configuration:

```yaml
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/v2beta1
metadata:
  name: kong
  namespace: default
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:3.11 # Use Kong Gateway version that matches your deployment.
  controlPlaneOptions:
    featureGates:
    - name: GatewayAlpha
      state: enabled
    controllers:
    - name: GWAPI_GATEWAY
      state: enabled
    - name: GWAPI_HTTPROUTE
      state: enabled
---
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong
    namespace: default
---
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong
  namespace: default
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    protocol: HTTP
    port: 80
```

Learn more about the parameters of `GatewayConfiguration` on [the reference page](/operator/reference/custom-resources/#gatewayconfiguration).

### Step 5: Verify `Gateway` status

At this point the `Gateway` should be marked as `Programmed` in its status:

```
kubectl get gateway -n default kong -o jsonpath-as-json='{.status}'
```

```
[
    {
        "addresses": [
            {
                "type": "IPAddress",
                "value": "172.18.128.1"
            }
        ],
        "conditions": [
            {
                "lastTransitionTime": "2025-08-09T18:17:00Z",
                "message": "",
                "observedGeneration": 1,
                "reason": "Programmed",
                "status": "True",
                "type": "Programmed"
            },
            ...
    }
]
```
