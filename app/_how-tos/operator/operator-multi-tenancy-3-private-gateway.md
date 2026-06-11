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

<!-- SOURCE: Baptiste's gist https://gist.github.com/bcollard/44caa409cdf7d796506a7a2e61a4a0d5 -->

## Create a GatewayConfiguration

As with the public gateway, `controlPlaneOptions.watchNamespaces.type: own` restricts the in-memory KIC to watch only the `kong-gw-private` namespace.

```bash
kubectl apply -f - <<EOF
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
EOF
```

## Create a GatewayClass

Create a `GatewayClass` that references the `GatewayConfiguration` above:

```bash
kubectl apply -f - <<EOF
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
EOF
```

## Create a Gateway

Create the `Gateway` resource in the `kong-gw-private` namespace, referencing the `GatewayClass` above:

```bash
kubectl apply -f - <<EOF
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
    port: 80
EOF
```

## Validate

Wait for the private gateway to become ready:

{% validation kubernetes-resource %}
kind: Gateway
name: gw-private
namespace: kong-gw-private
{% endvalidation %}
