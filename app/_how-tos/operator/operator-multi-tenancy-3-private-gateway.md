---
title: Deploy the private gateway
description: "Create a {{ site.base_gateway }} instance scoped to the private tenant namespace."
content_type: how_to

permalink: /operator/dataplanes/how-to/multi-tenancy/private-gateway/
series:
  id: operator-multi-tenancy
  position: 3

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
  q: How do I add a second isolated gateway to the same cluster?
  a: |
    Repeat the `GatewayConfiguration` / `GatewayClass` / `Gateway` triptych in the
    second tenant namespace with its own `watchNamespaces.type: own` setting.

prereqs:
  skip_product: true
---

## Create a GatewayConfiguration

As with the public gateway, `controlPlaneOptions.watchNamespaces.type: own` restricts the in-memory {{ site.kic_product_name_short }} to watch only the `kong-gw-private` namespace.

```bash
echo '
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: gw-private
  namespace: kong-gw-private
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
     name: gw-private
   spec:
     controllerName: konghq.com/gateway-operator
     parametersRef:
       group: gateway-operator.konghq.com
       kind: GatewayConfiguration
       name: gw-private
       namespace: kong-gw-private
   ' | kubectl apply -f -
   ```

1. Wait for {{ site.operator_product_name }} to accept the `GatewayClass`:

   ```bash
   kubectl wait --for=condition=Accepted=True gatewayclass/gw-private --timeout=60s
   ```

## Create a Gateway

1. Create the `Gateway` resource in the `kong-gw-private` namespace. The private gateway uses port 8080 to avoid a host-port conflict with the public gateway on single-node clusters (such as OrbStack, k3s, or kind) where each LoadBalancer service binds a host port.

   ```bash
   echo '
   kind: Gateway
   apiVersion: gateway.networking.k8s.io/v1
   metadata:
     name: gw-private
     namespace: kong-gw-private
   spec:
     gatewayClassName: gw-private
     listeners:
     - name: http
       protocol: HTTP
       port: 8080
   ' | kubectl apply -f -
   ```

1. Wait for the gateway to be programmed:

   ```bash
   kubectl wait --for=condition=Programmed=True gateway/gw-private -n kong-gw-private --timeout=120s
   ```

## Validate

Verify the private gateway was reconciled successfully:

{% validation kubernetes-resource %}
kind: Gateway
name: gw-private
namespace: kong-gw-private
{% endvalidation %}
