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

## Create a Backend Service

In order to route a request using {{ site.base_gateway }} we need a Service running in our cluster. Install an `echo` Service using the following command:

```bash
kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong
```

## Create an HTTPRoute

Create an `HTTPRoute` to send any requests that start with `/echo` to the echo Service.

```yaml
echo '
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: echo
  namespace: kong
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo
          port: 1027
' | kubectl apply -f -
```

The results should look like this:

```text
httproute.gateway.networking.k8s.io/echo created
```

## Test your Backend

Run `kubectl get gateway kong -n default` to get the IP address for the gateway and set that as the value for the variable `PROXY_IP`.

```bash
export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
```

Test your Service:
{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
display_headers: true
{% endvalidation %}

You should see the following message:

```text
Welcome, you are connected to node king.
Running on Pod echo-965f7cf84-rm7wq.
In namespace default.
With IP address 192.168.194.10.
```
