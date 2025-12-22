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
    section: "Konnect CRDs: Gateway"
min_version:
  operator: '2.1'

products:
  - operator

works_on:
  - konnect
  - on-prem

search_aliases:
  - kgo gateway
  - kgo hybrid gateway
  - konnect hybrid gateway

tldr:
  q: How do I configure a Hybrid Gateway in {{site.konnect_short_name}}?
  a: Create a `GatewayConfiguration` resource that includes your {{site.konnect_short_name}} authentication and data plane options. Then create a `GatewayClass` resource that references the `GatewayConfiguration`, and a `Gateway` resource that references the `GatewayClass`.

prereqs:
  skip_product: false
  operator:
    konnect:
      auth: true

---

## Create a `GatewayConfiguration` resource

{: data-deployment-topology="konnect" }
Use the `GatewayConfiguration` resource to configure a `GatewayClass` for Hybrid Gateways. `GatewayConfiguration` is for Hybrid Gateways when field `spec.konnect.authRef` is set.

First, let's create a `GatewayConfiguration` resource to specify our Hybrid Gateway parameters. Set `spec.konnect.authRef.name` to the name of the `KonnectAPIAuthConfiguration` resource we created in the [prerequisites](#create-a-konnectapiauthconfiguration-resource) and specify your data plane configuration:

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
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
{% endkonnect_crd %}
<!-- vale on -->

## Create a `GatewayClass` resource
Next, configure a `GatewayClass` resource to use the `GatewayConfiguration` we just created:

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

Finally, create a `Gateway` resource that references the `GatewayClass` we just created:

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

{{site.operator_product_name}} automatically creates the `DataPlane` and `KonnectGatewayControlPlane` resources.

## Validation

{% validation kubernetes-resource %}
kind: Gateway
name: kong
namespace: kong
{% endvalidation %}

The `DataPlane`, `KonnectExtension`, and `KonnectGatewayControlPlane` resources are created automatically by {{site.operator_product_name}}.
{: data-deployment-topology="konnect" }

The `DataPlane` and `ControlPlane` resources are created automatically by {{site.operator_product_name}}.
{: data-deployment-topology="on-prem" }
