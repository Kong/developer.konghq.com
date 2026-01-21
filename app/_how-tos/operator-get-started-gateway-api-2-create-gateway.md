---
title: Provision a Gateway
description: "Provision a Hybrid Gateway in {{site.konnect_short_name}} using the Gateway API."
content_type: how_to

permalink: /operator/get-started/gateway-api/deploy-gateway/
series:
  id: operator-get-started-gateway-api
  position: 2
  
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Hybrid Gateway"

products:
  - operator

works_on:
  - konnect
  - on-prem

entities: []
search_aliases:
  - kgo gateway
  - kgo hybrid gateway
  - konnect hybrid gateway

tldr:
  q: How can I create a Gateway with {{ site.operator_product_name }} with self-managed Control Plane?
  a: Create a `GatewayConfiguration` object, then create a `GatewayClass` instance and a `Gateway` resource.

prereqs:
  skip_product: false
  operator:
    konnect:
      auth: true

---

## Create a `GatewayConfiguration`

{: data-deployment-topology="konnect" }
Use the `GatewayConfiguration` resource to configure a `GatewayClass` for Hybrid Gateways. `GatewayConfiguration` is for Hybrid Gateways when field `spec.konnect.authRef` is set.

<!-- vale off -->
{% konnect_crd %}
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: kong-configuration
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:3.12
{% endkonnect_crd %}
<!-- vale on -->

{: data-deployment-topology="on-prem" }
Use the `GatewayConfiguration` resource to configure a `GatewayClass` for on-premise Gateways.

<!-- vale off -->
{% on_prem_crd %}
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: kong-configuration
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:3.12
{% endon_prem_crd %}
<!-- vale on -->

## Create a `GatewayClass`

Next configure respective `GatewayClass` to use the above `GatewayConfiguration`.

```bash
echo 'kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong-configuration
    namespace: kong
' | kubectl apply -f -
```

## Create a `Gateway` Resource

Now create a `Gateway` resource that references the `GatewayClass` you just created.

```bash
echo '
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    protocol: HTTP
    port: 80
' | kubectl apply -f -
```

## Validation

{% validation kubernetes-resource %}
kind: Gateway
name: kong
namespace: kong
{% endvalidation %}

{: data-deployment-topology="konnect" }
The respective `DataPlane`, `KonnectExtension`, and `KonnectGatewayControlPlane` are created automatically by the Gateway Operator.
{: data-deployment-topology="konnect" }

{: data-deployment-topology="on-prem" }
The respective `DataPlane` and `ControlPlane` are created automatically by the Gateway Operator.
{: data-deployment-topology="on-prem" }
