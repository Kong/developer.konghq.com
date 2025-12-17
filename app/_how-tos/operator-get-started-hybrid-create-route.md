---
title: Create a Route with {{ site.operator_product_name }}
description: "Create a {{ site.base_gateway }} Service and Route using {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/dataplanes/get-started/hybrid/create-route/
series:
  id: operator-get-started-hybrid
  position: 3

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "Get Started"

products:
  - operator

tools:
  - operator

works_on:
  - konnect

tldr:
  q: How can I create a Route with {{ site.operator_product_name }}?
  a: Create a `KongService` object , then create a `KongRoute` and associate it to the `KongService`.
next_steps:
  - text: Learn about Custom resource definitions (CRDs)
    url: /operator/reference/custom-resources/
  - text: Create a {{site.kic_product_name}} Control Plane
    url: /operator/konnect/crd/control-planes/kubernetes/
---

{:data-deployment-topology='konnect'}
## Create a Service

Creating the `KongService` object in your Kubernetes cluster will provision a {{site.konnect_product_name}} service for your [API Gateway](/gateway/). 
You can refer to the CR [API](/operator/reference/custom-resources/#kongservice) to see all the available fields.

Your `KongService` must be associated with a `KonnectGatewayControlPlane` object that you've created in your cluster.

Create a `KongService` by applying the following YAML manifest:


<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: service
spec:
  name: service
  host: httpbin.konghq.com
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

At this point, you should see the Service in the API Gateway UI.

## Create a Route

Creating the `KongRoute` object in your Kubernetes cluster will provision a {{site.konnect_product_name}} Route for
your [API Gateway](/gateway/).
You can refer to the CR [API](/operator/reference/custom-resources/#kongroute) to see all the available fields.

### Associate a Route with a Service

You can create a `KongRoute` associated with a `KongService` by applying the following YAML manifest:

<!-- vale off -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: route-with-service
spec:
  name: route-with-service
  protocols:
  - http
  paths:
  - /
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: service
{% endkonnect_crd %}
<!-- vale on -->

## Send test traffic

After the Service and Route are created, send traffic to the proxy. {{site.base_gateway}} will forward the request to `httpbin.konghq.com`. You can use the `/anything` endpoint to echo the request made in the response.

To make a request to the proxy, fetch the LoadBalancer IP address using `kubectl get services`:

```bash
NAME=$(kubectl get -o yaml -n kong service | yq '.items[].metadata.name | select(contains("dataplane-ingress"))')
export PROXY_IP=$(kubectl get svc -n kong $NAME -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
echo "Proxy IP: $PROXY_IP"
```

{:.info}
> Note: If your cluster can't provision LoadBalancer type Services, then you might not receive an IP address.

Test the routing rules by sending a request to the proxy IP address:

{% validation request-check %}
url: /anything/hello
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
