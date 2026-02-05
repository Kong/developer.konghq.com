---
title: Provision a Hybrid Gateway
description: "Provision a Hybrid Gateway in {{site.konnect_short_name}} using the Gateway API CRDs."
content_type: how_to
permalink: /operator/konnect/crd/gateway/hybrid
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

search_aliases:
  - kgo gateway
  - kgo hybrid gateway
  - konnect hybrid gateway

tldr:
  q: How do I configure a Hybrid Gateway in {{site.konnect_short_name}}?
  a: Create a `GatewayConfiguration` resource that includes your {{site.konnect_short_name}} authentication and data plane options. Then create a `GatewayClass` resource that references the `GatewayConfiguration`, and a `Gateway` resource that references the `GatewayClass`.

prereqs:
  operator:
    konnect:
      auth: true

---

## Create a `GatewayConfiguration` resource

Use the `GatewayConfiguration` resource to configure a `GatewayClass` for Hybrid Gateways. `GatewayConfiguration` is for Hybrid Gateways when field `spec.konnect.authRef` is set.

First, let's create a `GatewayConfiguration` resource to specify our Hybrid Gateway parameters. Set `spec.konnect.authRef.name` to the name of the `KonnectAPIAuthConfiguration` resource we created in the [prerequisites](#create-a-konnectapiauthconfiguration-resource) and specify your data plane configuration:

<!-- vale off -->
{% konnect_crd %}
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/v2beta1
metadata:
  name: hybrid-configuration
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
{% konnect_crd %}
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: hybrid-class
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: hybrid-configuration
    namespace: kong
{% endkonnect_crd %}
<!-- vale on -->

## Create a `Gateway` Resource

Finally, create a `Gateway` resource that references the `GatewayClass` we just created:

<!-- vale off -->
{% konnect_crd %}
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: hybrid-gateway
  namespace: kong
spec:
  gatewayClassName: hybrid-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
{% endkonnect_crd %}
<!-- vale on -->

{{site.operator_product_name}} automatically creates the `DataPlane` and `KonnectGatewayControlPlane` resources.

## Validation

{% validation kubernetes-resource %}
kind: Gateway
name: hybrid-gateway
{% endvalidation %}

