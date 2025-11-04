---
title: Create a Gateway
description: "Configure {{ site.gateway_operator_product_name }}, {{ site.kic_product_name }}, and {{ site.base_gateway }} using open standards."
content_type: how_to

permalink: /operator/dataplanes/get-started/kic/create-gateway/
series:
  id: operator-get-started-kic
  position: 2

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "Get Started"

products:
  - operator

works_on:
  - konnect
  - on-prem

entities: []

tldr:
  q: How can I create a Gateway with {{ site.gateway_operator_product_name }} and {{ site.kic_product_name }}?
  a: Create a `GatewayConfiguration` object, then create a `GatewayClass` instance and a `Gateway` resource.

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true
      control_plane: kic
      konnectextension: true

---

## ControlPlane and DataPlane resources

{% assign gatewayApiVersion = "v1" %}

Creating `GatewayClass` and `Gateway` resources in Kubernetes causes {{ site.gateway_operator_product_name }} to create a {{ site.kic_product_name }} and {{ site.base_gateway }} deployment.

You can customize your {{ site.kic_product_name }} and {{ site.base_gateway }} deployments using the `GatewayConfiguration` CRD. This allows you to control the image being used, and set any required environment variables.

{:data-deployment-topology='konnect'}
## Create the GatewayConfiguration

In order to specify the `KonnectExtension` in `Gateway`'s configuration you need to create a `GatewayConfiguration` object which will hold the `KonnectExtension` reference.

```bash
echo '
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: kong
  namespace: kong
spec:
  extensions:
  - kind: KonnectExtension
    name: my-konnect-config
    group: konnect.konghq.com
  dataPlaneOptions:
    deployment:
      replicas: 2' | kubectl apply -f -
```

{:data-deployment-topology='on-prem'}

{% include k8s/kong-namespace.md %}

## GatewayConfiguration

```yaml
echo 'kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: kong
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong:{{site.latest_gateway_oss_version}}' | kubectl apply -f -
```

## GatewayClass

To use the Gateway API resources to configure your Routes, you need to create a `GatewayClass` instance and create a `Gateway` resource that listens on the ports that you need.

```yaml
echo '
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/{{ gatewayApiVersion }}
metadata:
  name: kong
  namespace: kong
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong
    namespace: kong
---
kind: Gateway
apiVersion: gateway.networking.k8s.io/{{ gatewayApiVersion }}
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    protocol: HTTP
    port: 80' | kubectl apply -f -
```

You can verify that everything works by checking the `Gateway` resource via `kubectl`:

```bash
kubectl get -n kong gateway kong -o wide
```

You should see the following output:

```
NAME   CLASS   ADDRESS        PROGRAMMED   AGE
kong   kong    172.18.0.102   True         9m5s
```

## Check the Programmed status

If the `Gateway` has `Programmed` condition set to `True`, you can visit {{site.konnect_short_name}} and see your configuration being synced by {{ site.kic_product_name }}.

<!-- vale off -->
{% validation kubernetes-resource %}
kind: Gateway
name: kong
namespace: kong
{% endvalidation %}
<!-- vale on -->
