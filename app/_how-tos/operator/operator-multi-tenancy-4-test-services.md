---
title: Deploy test services
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
    Deploy a backend service and `HTTPRoute` in each tenant namespace. Each in-memory {{ site.kic_product_name_short }}
    is scoped to its own namespace via `watchNamespaces.type: own`, so routes in
    `kong-gw-public` are invisible to the private gateway and vice versa.

prereqs:
  skip_product: true

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Delete the routes, services, gateways, and gateway configurations from both tenant namespaces, then the cluster-scoped resources:

        ```bash
        kubectl delete -n kong-gw-public --ignore-not-found \
          httproute/echo \
          service/echo \
          gateway/gw-public \
          gatewayconfiguration/gw-public

        kubectl delete -n kong-gw-private --ignore-not-found \
          httproute/private-only \
          service/echo \
          gateway/gw-private \
          gatewayconfiguration/gw-private

        kubectl delete --ignore-not-found \
          gatewayclass/gw-public \
          gatewayclass/gw-private \
          konglicense/kong-license
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

    - title: Delete the namespaces
      content: |
        ```bash
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kong-gw-private kong-gw-public kong-system
        ```
      icon_url: /assets/icons/kubernetes.svg
---

## Deploy test services

1. Deploy the echo service in both tenant namespaces:

   ```bash
   kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong-gw-public
   kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong-gw-private
   ```
   {: data-test-step="block" }

1. Wait for both deployments to be ready:

   ```bash
   kubectl rollout status deployment/echo -n kong-gw-public --timeout=60s
   kubectl rollout status deployment/echo -n kong-gw-private --timeout=60s
   ```
   {: data-test-step="block" }

## Create an HTTPRoute for the public gateway

Create an `HTTPRoute` in the `kong-gw-public` namespace pointing to the echo service:

```bash
echo '
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
' | kubectl apply -f -
```
{: data-test-step="block" }

## Create two HTTPRoutes for the private gateway

Create two `HTTPRoute` resources in the `kong-gw-private` namespace. One is equivalent to the one in the `kong-gw-public` namespace, and the other is a `/private` path in `kong-gw-private` only:

```bash
echo '
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
---
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
' | kubectl apply -f -
```
{: data-test-step="block" }

## Validate

Wait for the routes to be programmed. Route conditions are nested in `status.parents`, so the wait uses a jsonpath instead of a condition:

```bash
kubectl wait --for=jsonpath='{.status.parents[0].conditions[?(@.type=="Programmed")].status}'=True httproute/echo -n kong-gw-public --timeout=300s
kubectl wait --for=jsonpath='{.status.parents[0].conditions[?(@.type=="Programmed")].status}'=True httproute/echo -n kong-gw-private --timeout=300s
kubectl wait --for=jsonpath='{.status.parents[0].conditions[?(@.type=="Programmed")].status}'=True httproute/private-only -n kong-gw-private --timeout=300s
```
{: data-test-step="block" }

1. Get the external IP address for each gateway:

   ```bash
   export PUBLIC_GW_IP=$(kubectl get gateway gw-public -n kong-gw-public \
     -o jsonpath='{.status.addresses[0].value}')
   echo $PUBLIC_GW_IP
   ```
   {: data-test-step="block" }

   ```bash
   export PRIVATE_GW_IP=$(kubectl get gateway gw-private -n kong-gw-private \
     -o jsonpath='{.status.addresses[0].value}')
   echo $PRIVATE_GW_IP
   ```
   {: data-test-step="block" }

{% capture check_1 %}
{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: http://$PUBLIC_GW_IP
konnect_url: http://$PUBLIC_GW_IP
{% endvalidation %}
{% endcapture %}

{% capture check_2 %}
{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: http://$PRIVATE_GW_IP:8080
konnect_url: http://$PRIVATE_GW_IP:8080
{% endvalidation %}
{% endcapture %}

{% capture check_3 %}
{% validation request-check %}
url: /private
status_code: 200
on_prem_url: http://$PRIVATE_GW_IP:8080
konnect_url: http://$PRIVATE_GW_IP:8080
{% endvalidation %}
{% endcapture %}

{% capture check_4 %}
{% validation custom-command %}
command: |
  curl -s -o /dev/null -w '%{http_code}' "$PUBLIC_GW_IP/private"
expected:
  message: "404"
  return_code: 0
render_output: false
{% endvalidation %}
{% endcapture %}

1. The public gateway listens on port 80 and the private gateway on port 8080. Check that both return a `200` response on `/echo`:
   
   {{check_1 | indent}}
   {{check_2 | indent}}

1. Send a request to the Route that only exists in `kong-gw-private` to verify that the public gateway has no knowledge of it:

   {{check_3 | indent}}
   {{check_4 | indent}}

The public gateway returns 404 because its in-memory {{ site.kic_product_name_short }} only watches `kong-gw-public`. The `private-only` HTTPRoute lives in `kong-gw-private`, so the public {{ site.kic_product_name_short }} never processes it and never programs it into the public data plane. No matter what routes are deployed in `kong-gw-private`, they are completely invisible to `gw-public`, and vice versa. This is namespace isolation working as intended.
