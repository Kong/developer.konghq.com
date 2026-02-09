---
title: Reference {{site.konnect_short_name}} authentication across multiple namespaces with {{ site.operator_product_name }}
description: "Learn how to use the KongReferenceGrant resource to use {{site.konnect_short_name}} authentication configuration across namespaces."
content_type: how_to

permalink: /operator/konnect/how-to/auth-cross-namespace-reference/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

tldr:
  q: How do I reference a KonnectAPIAuthConfiguration resource from a different namespace?
  a: Use a `KongReferenceGrant` in the same namespace as the `KonnectAPIAuthConfiguration` to authorize references from the source namespace.

related_resources:
  - text: Reference Secrets across multiple namespaces
    url: /operator/konnect/how-to/secret-cross-namespace-reference/

min_version:
  operator: '2.1'
---

{% include /operator/cross-namespace-ref.md %}

This example shows how to allow a `Gateway` in the `kong` namespace to use {{site.konnect_short_name}} authentication credentials stored in the `auth` namespace using `KongReferenceGrant`. For an example using `ReferenceGrant`, see [Reference Secrets across multiple namespaces](/operator/konnect/how-to/secret-cross-namespace-reference/).

## Create the KonnectAPIAuthConfiguration

Run the following command to create an `auth` namespace and a `KonnectAPIAuthConfiguration` in that namespace:

```sh
echo '
apiVersion: v1
kind: Namespace
metadata:
  name: auth
---
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth
  namespace: auth
spec:
  type: token
  token: '"$KONNECT_TOKEN"'
  serverURL: us.api.konghq.com' | kubectl apply -f -
```

## Create the KongReferenceGrant

Create a `KongReferenceGrant` in the **auth** namespace to allow a `KonnectGatewayControlPlane` in the `kong` namespace to access the credentials:

```sh
echo '
kind: KongReferenceGrant
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: allow-kong-cp-to-auth
  namespace: auth
spec:
  from:
    - group: konnect.konghq.com
      kind: KonnectGatewayControlPlane
      namespace: kong
  to:
    - group: konnect.konghq.com
      kind: KonnectAPIAuthConfiguration' | kubectl apply -f -
```

## Create the GatewayConfiguration

Create a `kong` namespace and configure a `GatewayConfiguration` to reference the credential in the `auth` namespace.

```sh
echo '
apiVersion: v1
kind: Namespace
metadata:
  name: kong
---
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/v2beta1
metadata:
  name: gateway-configuration
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth
      namespace: auth
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}' | kubectl apply -f -
```

## Create the Gateway

Create a `GatewayClass` resource that references the `GatewayConfiguration`, and a `Gateway` resource that references the `GatewayClass`.

```sh
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: gateway-class
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: gateway-class
  listeners:
    - name: http
      port: 80
      protocol: HTTP' | kubectl apply -f -
```

## Validate

To validate, check that the `KonnectGatewayControlPlane` resource was automatically created:

```sh
kubectl get konnectgatewaycontrolplane -n kong
```