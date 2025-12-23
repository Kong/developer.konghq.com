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
    section: "Konnect CRDs: Hybrid Gateway"


products:
  - operator

works_on:
  - konnect

entities: []
search_aliases:
  - kgo gateway
  - kgo hybrid gateway
  - konnect hybrid gateway

tldr:
  q: How do I configure a Hybrid Gateway in {{site.konnect_short_name}}?
  a: Fill Konnect related fields in `GatewayConfiguration` for `GatewayClass` that will be used for Hybrid Gateways.

prereqs:
  operator:
    konnect:
      auth: true

---

## Create a `GatewayClass` for a Hybrid Gateway

Use the `GatewayConfiguration` resource to configure a `GatewayClass` for Hybrid Gateways. `GatewayConfiguration` is for Hybrid Gateways when field `spec.konnect.authRef` is set.

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
            image: kong/kong-gateway:3.12
{% endkonnect_crd %}
<!-- vale on -->

Next configure respective `GatewayClass` to use the above `GatewayConfiguration`.

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

Now create a `Gateway` resource that references the `GatewayClass` you just created.

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

## Validation

{% validation kubernetes-resource %}
kind: Gateway
name: hybrid-gateway
{% endvalidation %}

The respective `DataPlane` and `KonnectGatewayControlPlane` are created automatically by the Gateway Operator.
