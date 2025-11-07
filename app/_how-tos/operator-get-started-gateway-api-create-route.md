---
title: Configure route and service  
description: "Configure a {{ site.base_gateway }} Service and Route using {{ site.operator_product_name }}."
content_type: how_to

permalink: /operator/get-started/gateway-api/create-route/

series:
  id: operator-get-started-gateway-api
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

works_on:
  - konnect
  - on-prem
  
prereqs:
  skip_product: true

tldr:
  q: How can I create a Route with {{ site.operator_product_name }}?
  a: Create a Gateway API `HTTPRoute` object.
next_steps:
  - text: Learn about Custom resource definitions (CRDs)
    url: /operator/reference/custom-resources/
---

## Create an HTTPRoute

TODO

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
