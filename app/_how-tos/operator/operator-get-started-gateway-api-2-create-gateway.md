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
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "Get Started"
    
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
  q: How do I deploy {{site.base_gateway}} using Kubernetes Gateway API?
  a: Use Gateway API constructs `GatewayConfiguration`,  `GatewayClass` and `Gateway` to provision a {{site.base_gateway}} on Kubernetes.

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

---

## Create a `GatewayConfiguration` resource

First, let's create a `GatewayConfiguration` resource to specify our Hybrid Gateway parameters. Set `spec.konnect.authRef.name` to the name of the `KonnectAPIAuthConfiguration` resource we created in the [prerequisites](#create-a-konnectapiauthconfiguration-resource) and specify your data plane configuration:
{:data-deployment-topology='konnect'}

First, let's create a `GatewayConfiguration` resource to specify our Gateway parameters:
{:data-deployment-topology='on-prem'}

```bash
echo '
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
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}' | kubectl apply -f -
```
{:data-deployment-topology='konnect'}

```bash
kubectl create namespace kong 
```
{:data-deployment-topology='on-prem'}

```bash
echo '
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
            image: kong/kong-gateway:3.9' | kubectl apply -f -
```
{:data-deployment-topology='on-prem'}

## Create a `GatewayClass`

Next, configure a `GatewayClass` resource to use the `GatewayConfiguration` we just created:

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

{{site.operator_product_name}} will automatically create the `DataPlane` and `KonnectGatewayControlPlane` resources.
{:data-deployment-topology='konnect'}

{{site.operator_product_name}} will automatically create the `DataPlane` and `ControlPlane` resources.
{:data-deployment-topology='on-prem'}

## Validation

{% validation kubernetes-resource %}
kind: Gateway
name: kong
namespace: kong
{% endvalidation %}

