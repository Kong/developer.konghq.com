---
title: Create a Route with {{ site.operator_product_name }} with self-managed Control Plane
description: "Learn how to configure a Route using {{ site.operator_product_name }} with self-managed Control Plane."
content_type: how_to

permalink: /operator/dataplanes/get-started/kic/create-route/
series:
  id: operator-get-started-kic
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

entities: []

tldr:
  q: How can I create a Route with {{ site.operator_product_name }} with self-managed Control Plane?
  a: Create a Service, then create an `HTTPRoute`.

prereqs:
  skip_product: true
next_steps:
  - text: Proxying HTTP Traffic
    url: /kubernetes-ingress-controller/routing/http/
  - text: Rate limiting with {{site.kic_product_name}}
    url: /kubernetes-ingress-controller/rate-limiting/
---

{% assign gatewayApiVersion = "v1" %}

## Configure the echo service

1. In order to route a request using {{ site.base_gateway }} we need a Service running in our cluster. Install an `echo` Service using the following command:

    ```bash
    kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong
    ```

1.  Create an `HTTPRoute` to send any requests that start with `/echo` to the echo Service.

    ```yaml
    echo '
    kind: HTTPRoute
    apiVersion: gateway.networking.k8s.io/{{ gatewayApiVersion }}
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

## Test the configuration

1. Run `kubectl get gateway kong -n default` to get the IP address for the gateway and set that as the value for the variable `PROXY_IP`.

    ```bash
    export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
    ```

    {:.info}
    > Note: if your cluster can not provision LoadBalancer type Services then the IP you receive may only be routable from within the cluster.

1. Make a call to the `$PROXY_IP` that you configured.

{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
indent: 4
{% endvalidation %}

1. You should see the following:

    ```
    Welcome, you are connected to node king.
    Running on Pod echo-965f7cf84-rm7wq.
    In namespace default.
    With IP address 192.168.194.10.
    ```
