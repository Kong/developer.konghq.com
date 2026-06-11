---
title: Deploy test services and validate isolation
description: "Deploy a backend service and HTTPRoute in each tenant namespace, then confirm that each gateway only serves its own routes."
content_type: how_to

permalink: /operator/dataplanes/how-to/multi-tenancy/test-services/
series:
  id: operator-multi-tenancy
  position: 4

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem

min_version:
  operator: '2.0'

related_resources:
  - text: "Multi-tenancy reference"
    url: /operator/reference/multi-tenancy/
  - text: "{{site.operator_product_name}} architecture"
    url: /operator/reference/architecture/

next_steps:
  - text: "Multi-tenancy reference"
    url: /operator/reference/multi-tenancy/
  - text: "Limiting namespaces watched by ControlPlane"
    url: /operator/reference/control-plane-watch-namespaces/

tldr:
  q: How do I verify that two gateways are isolated from each other?
  a: |
    Deploy a backend service and `HTTPRoute` in each tenant namespace. Each in-memory KIC
    is scoped to its own namespace via `watchNamespaces.type: own`, so routes in
    `kong-gw-public` are invisible to the private gateway and vice versa.

prereqs:
  skip_product: true
---

<!-- SOURCE: Baptiste's gist https://gist.github.com/bcollard/44caa409cdf7d796506a7a2e61a4a0d5,
     operator-get-started-gateway-api-3-create-route.md -->

## Deploy a test service in each namespace

Deploy the echo service in both tenant namespaces:

```bash
kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong-gw-public
kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong-gw-private
```

## Create an HTTPRoute for the public gateway

Create an `HTTPRoute` in the `kong-gw-public` namespace pointing to the echo service:

```bash
kubectl apply -f - <<EOF
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: echo
  namespace: kong-gw-public
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: gw-public
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /echo
    backendRefs:
    - name: echo
      port: 1027
EOF
```

## Create an HTTPRoute for the private gateway

Create an equivalent `HTTPRoute` in the `kong-gw-private` namespace:

```bash
kubectl apply -f - <<EOF
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: echo
  namespace: kong-gw-private
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: gw-private
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /echo
    backendRefs:
    - name: echo
      port: 1027
EOF
```

## Validate

Get the external IP address for each gateway:

```bash
export PUBLIC_GW_IP=$(kubectl get gateway gw-public -n kong-gw-public \
  -o jsonpath='{.status.addresses[0].value}')
export PRIVATE_GW_IP=$(kubectl get gateway gw-private -n kong-gw-private \
  -o jsonpath='{.status.addresses[0].value}')
```

Both gateways should respond on `/echo`:

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PUBLIC_GW_IP
konnect_url: $PUBLIC_GW_IP
{% endvalidation %}

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PRIVATE_GW_IP
konnect_url: $PRIVATE_GW_IP
{% endvalidation %}

<!-- GAP: There is no built-in mechanism in Kong Operator to verify that a route in namespace A
     is NOT reachable through the gateway in namespace B. The isolation is enforced by the
     watchNamespaces scoping (logical isolation), not by a NetworkPolicy (network-level isolation).
     Users who need hard network-level isolation should add Kubernetes NetworkPolicy resources. -->
