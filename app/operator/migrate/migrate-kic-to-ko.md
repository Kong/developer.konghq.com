---
title: "Migrating from {{site.kic_product_name}} to {{ site.operator_product_name }} 2.0.0"
description: "Complete migration guide from {{site.kic_product_name}} (KIC) to {{ site.operator_product_name }} ({{ site.operator_product_name_short }}) 2.0.0."
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

{{ site.operator_product_name }} ({{ site.operator_product_name_short }}) is next generation Kubernetes-native operator that simplifies the management of ingress controllers and Kong data planes.

In this guide, we will walk you through the steps to migrate from {{ site.kic_product_name }} ({{ site.kic_product_name_short }}) to {{ site.operator_product_name }} ({{ site.operator_product_name_short }}) 2.0.0.

## Prerequisites

Before starting the migration, ensure you:

1. **Backup your current configuration**

1. **Verify current {{site.kic_product_name}} version**:

   ```bash
   # Depending on the release name the deployment name and chart used (kong/ingress) might have a different name
   kubectl get deploy -n ${NAMESPACE} kong-controller -o jsonpath="{.spec.template.spec.containers[?(@.name=='ingress-controller')].image}"
   kong/kubernetes-ingress-controller:3.5.0
   ```

   This guide assumes that you're running the latest version of {{ site.kic_product_name }} ({{ site.data.kic_latest.release }}).

   If you're not running {{ site.data.kic_latest.release }}, please upgrade before proceeding.

1. Can **Access the Kubernetes cluster** with admin privileges

1. **Verify cert-manager is installed** (recommended for webhooks certificate management):

   {:.info}
   > **Note**: {{ site.operator_product_name }} 2.0.0 uses webhooks that require TLS certificates managed by cert-manager. If cert-manager is not installed, follow the [cert-manager installation guide](https://cert-manager.io/docs/installation/) before proceeding.

## Migrate to {{ site.operator_product_name }} 2.0.0

   {:.warning}
   > **Important**: This process involves down time. Plan your migration accordingly.

The migration process requires several manual steps due to breaking changes in certificate management and CRD structure. Follow these steps carefully:

### Step 1: Uninstall existing {{ site.kic_product_name_short }} deployment

First step is to uninstall the existing {{ site.kic_product_name_short }} deployment to stop it from reconciling in cluster objects.
This will prevent both {{ site.kic_product_name_short }} and the new {{ site.operator_product_name_short }} from reconciling the same resources and fighting over the status updates on those.

{% navtabs "uninstall-kic" %}
{% navtab "`kong` chart" %}

Set the following in your helm values:

```yaml
ingressController:
  enabled: false
```

Apply the changes with:

```bash
helm upgrade -n ${NAMESPACE} ${RELEASE_NAME} kong/kong
```

{% endnavtab %}
{% navtab "`ingress` chart" %}

Set the following in your helm values:

```yaml
controller:
  enabled: false
```

Apply the changes with:

```bash
helm upgrade -n ${NAMESPACE} ${RELEASE_NAME} kong/ingress
```

{% endnavtab %}
{% endnavtabs %}

At this point you have the {{ site.kic_product_name_short }} uninstalled and {{ site.base_gateway }} still serving traffic with the existing configuration.

### Step 2: Install KO

Install the new {{ site.operator_product_name }} using Helm:

```bash
helm repo update kong
helm upgrade --install kong-operator kong/kong-operator \
  -n kong-system \
  --create-namespace \
  --take-ownership \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --set ko-crds.enabled=true \
  --set global.conversionWebhook.enabled=true \
  --set global.conversionWebhook.certManager.enabled=true 
```

### Step 3: Verify the Installation

Verify that {{ site.operator_product_name }} 2.0.0 is running correctly:

Check the operator deployment:
```bash
kubectl get pod -n kong-system
```
Check operator logs:
```
kubectl logs -n kong-system -l app=kong-operator-kong-operator
```

### Step 4: Prepare the `Gateway` manifest to replace {{ site.base_gateway }} and {{ site.kic_product_name_short }}

{{ site.operator_product_name_short }} uses CRDs to manage among other things: {{ site.base_gateway }} and the ingress controller.

What used to be a pair of {{ site.base_gateway }} and {{ site.kic_product_name_short }} deployed via `helm` is now modelled through Gateway API's `Gateway`.

You can learn more about it on [Gateway API website](https://gateway-api.sigs.k8s.io/api-types/gateway/).

To customize the `Gateway` manifest for your environment, you can use Kong's `GatewayConfiguration` CRD.

Please refer to the following example which can serve as a base for your configuration:

```yaml
echo '
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
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
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
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
' | kubectl apply -f -
```

For more information on the `GatewayConfiguration` parameters review [the reference page](/operator/reference/custom-resources/#gatewayconfiguration).

### Step 5: Validate `Gateway` status

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

### Step 6: Validate generated configuration

Validate configuration generated by {{ site.operator_product_name }} by accessing the {{ site.base_gateway }}.

From the above `Gateway` status, you can see the address is `172.18.128.1`. You can test the configuration by sending requests against this address.

### Step 7: Uninstall remaining {{ site.base_gateway }} deployment

If everything is working as expected, you can proceed to uninstall the remaining {{ site.base_gateway }} deployment.

```bash
helm uninstall -n ${NAMESPACE} ${RELEASE_NAME}
```
