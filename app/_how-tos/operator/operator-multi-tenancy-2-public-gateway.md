---
title: Deploy the public gateway
description: "Create a {{ site.base_gateway }} instance scoped to the public tenant namespace."
content_type: how_to

permalink: /operator/dataplanes/how-to/multi-tenancy/public-gateway/
series:
  id: operator-multi-tenancy
  position: 2

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
  operator: '2.0'

related_resources:
  - text: "Multi-tenancy reference"
    url: /operator/reference/multi-tenancy/
  - text: "Managed Gateways"
    url: /operator/dataplanes/managed-gateways/
  - text: "Gateway configuration"
    url: /operator/dataplanes/gateway-configuration/

tldr:
  q: How do I deploy an isolated gateway for a single tenant?
  a: |
    Create a `GatewayConfiguration` with `controlPlaneOptions.watchNamespaces.type: own`,
    then create the matching `GatewayClass` and `Gateway` in the tenant namespace.

prereqs:
  skip_product: true
---

## Create a GatewayConfiguration

The `controlPlaneOptions.watchNamespaces.type: own` field restricts the in-memory {{ site.kic_product_name_short }} for this gateway to watch only the `kong-gw-public` namespace. Without this, it would watch all namespaces and process routes belonging to other tenants.

```bash
echo '
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: gw-public
  namespace: kong-gw-public
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
  controlPlaneOptions:
    watchNamespaces:
      type: own
' | kubectl apply -f -
```

## Create a GatewayClass

1. Create a `GatewayClass` that references the `GatewayConfiguration` above:

   ```bash
   echo '
   kind: GatewayClass
   apiVersion: gateway.networking.k8s.io/v1
   metadata:
     name: gw-public
   spec:
     controllerName: konghq.com/gateway-operator
     parametersRef:
       group: gateway-operator.konghq.com
       kind: GatewayConfiguration
       name: gw-public
       namespace: kong-gw-public
   ' | kubectl apply -f -
   ```

1. Wait for {{ site.operator_product_name }} to accept the `GatewayClass`:

   ```bash
   kubectl wait --for=condition=Accepted=True gatewayclass/gw-public --timeout=60s
   ```

## Create a Gateway

1. Create the `Gateway` resource in the `kong-gw-public` namespace, referencing the `GatewayClass` above:

   ```bash
   echo '
   kind: Gateway
   apiVersion: gateway.networking.k8s.io/v1
   metadata:
     name: gw-public
     namespace: kong-gw-public
   spec:
     gatewayClassName: gw-public
     listeners:
     - name: http
       protocol: HTTP
       port: 80
   ' | kubectl apply -f -
   ```

1. Wait for the gateway to be programmed:

   ```bash
   kubectl wait --for=condition=Programmed=True gateway/gw-public -n kong-gw-public --timeout=120s
   ```

## Validate

Verify the public gateway was reconciled successfully:

{% validation kubernetes-resource %}
kind: Gateway
name: gw-public
namespace: kong-gw-public
{% endvalidation %}
