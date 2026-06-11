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

1. Deploy the echo service in both tenant namespaces:

   ```bash
   kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong-gw-public
   kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong-gw-private
   ```

1. Wait for both deployments to be ready:

   ```bash
   kubectl rollout status deployment/echo -n kong-gw-public --timeout=60s
   kubectl rollout status deployment/echo -n kong-gw-private --timeout=60s
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

The public gateway listens on port 80 and the private gateway on port 8080. Both should respond on `/echo`:

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PUBLIC_GW_IP
konnect_url: $PUBLIC_GW_IP
{% endvalidation %}

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: http://$PRIVATE_GW_IP:8080
konnect_url: http://$PRIVATE_GW_IP:8080
{% endvalidation %}

## Test isolation

Both gateways responding on `/echo` confirms they are running, but it does not prove isolation — both routes happen to use the same path. The following test deploys a route that only exists in `kong-gw-private` and verifies that the public gateway has no knowledge of it.

Create an `HTTPRoute` for a `/private` path in `kong-gw-private` only:

```bash
kubectl apply -f - <<EOF
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: private-only
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
        value: /private
    backendRefs:
    - name: echo
      port: 1027
EOF
```

Confirm it is accessible via the private gateway:

{% validation request-check %}
url: /private
status_code: 200
on_prem_url: http://$PRIVATE_GW_IP:8080
konnect_url: http://$PRIVATE_GW_IP:8080
{% endvalidation %}

Confirm it returns 404 on the public gateway:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://$PUBLIC_GW_IP/private
# Expected: 404
```

The public gateway returns 404 because its in-memory KIC only watches `kong-gw-public`. The `private-only` HTTPRoute lives in `kong-gw-private`, so the public KIC never processes it and never programs it into the public DataPlane. No matter what routes are deployed in `kong-gw-private`, they are completely invisible to `gw-public` — and vice versa. This is namespace isolation working as intended.
