---
title: Proxy TCP traffic using TCPRoute
description: "Learn how to configure TCPRoute with {{ site.operator_product_name }} to route raw TCP traffic by port."
content_type: how_to

permalink: /operator/dataplanes/how-to/tcproute/
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
  - konnect

min_version:
  operator: '2.3'

tldr:
  q: How do I route TCP traffic with {{ site.operator_product_name }}?
  a: Add a `TCP` listener to your `Gateway`, then create a `TCPRoute` resource. {{ site.operator_product_name }} converts the `TCPRoute` into a {{ site.base_gateway }} [Service](/gateway/entities/service/) and [Route](/gateway/entities/route/).

prereqs:
  operator:
    konnect:
      auth: true
  inline:
    - title: telnet installed
      include_content: prereqs/telnet
      icon_url: /assets/icons/code.svg

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `Gateway` also deletes the control plane and data plane resources {{ site.operator_product_name }} created for it. Deleting the `kong-system` namespace removes the operator:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          tcproute/echo-plaintext \
          gateway/kong-tcp-gateway \
          gatewayconfiguration/kong-gateway-configuration
        kubectl delete --ignore-not-found gatewayclass/kong-tcp
        kubectl delete --ignore-not-found namespace kong
        helm uninstall kong-operator -n kong-system
        kubectl delete --ignore-not-found namespace kong-system
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg
---

`TCPRoute` is a Kubernetes Gateway API resource for routing raw TCP traffic by port, without any TLS or L7 awareness. This guide shows how to configure {{ site.operator_product_name }} to proxy TCP traffic to a backend Service.

{% include k8s/kong-namespace.md %}

## Configure the Gateway

{% konnect %}
content: |
  Create a `GatewayConfiguration`, `GatewayClass`, and `Gateway` with an `HTTP` listener. Setting `spec.konnect.authRef` hands the data plane to {{site.konnect_short_name}}, which manages its configuration:

  ```bash
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: kong-gateway-configuration
    namespace: kong
  spec:
    konnect:
      authRef:
        name: konnect-api-auth
        namespace: kong
    dataPlaneOptions:
      deployment:
        podTemplateSpec:
          spec:
            containers:
              - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
                name: proxy
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: kong-tcp
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: kong-gateway-configuration
      namespace: kong
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: kong-tcp-gateway
    namespace: kong
  spec:
    gatewayClassName: kong-tcp
    listeners:
      - name: http
        port: 80
        protocol: HTTP' | kubectl apply -f -
  ```
  {: data-test-step="block" }
{% endkonnect %}

{% on_prem %}
content: |
  Create a `GatewayConfiguration`, `GatewayClass`, and `Gateway` with an `HTTP` listener:

  ```bash
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: kong-gateway-configuration
    namespace: kong
  spec:
    dataPlaneOptions:
      deployment:
        podTemplateSpec:
          spec:
            containers:
              - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
                name: proxy
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: kong-tcp
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: kong-gateway-configuration
      namespace: kong
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: kong-tcp-gateway
    namespace: kong
  spec:
    gatewayClassName: kong-tcp
    listeners:
      - name: http
        port: 80
        protocol: HTTP' | kubectl apply -f -
  ```
  {: data-test-step="block" }
{% endon_prem %}

## Deploy a TCP backend

Install the `echo` Service, which accepts plain TCP connections on port `1025` and echoes back anything it receives:

```bash
kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n kong
```
{: data-test-step="block" }

## Route TCP traffic

1. Re-apply the `kong-tcp-gateway` Gateway with an additional `TCP` listener:

   {:.warning}
   > **Warning**: Applying this Gateway replaces the listener list. Include every listener you want to keep.

   ```bash
   echo 'apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: kong-tcp-gateway
     namespace: kong
   spec:
     gatewayClassName: kong-tcp
     listeners:
       - name: http
         port: 80
         protocol: HTTP
       - name: stream9000
         port: 9000
         protocol: TCP' | kubectl apply -f -
    ```
    {: data-test-step="block" }

1. Create a `TCPRoute`:

   ```bash
   echo "apiVersion: gateway.networking.k8s.io/v1
   kind: TCPRoute
   metadata:
     name: echo-plaintext
     namespace: kong
   spec:
     parentRefs:
       - name: kong-tcp-gateway
         sectionName: stream9000
     rules:
       - backendRefs:
           - name: echo
             port: 1025
   " | kubectl apply -f -
   ```
   {: data-test-step="block" }

This configuration instructs {{ site.base_gateway }} to forward all traffic it receives on port `9000` to the `echo` Service on port `1025`.

## Validate

1. Wait for the Gateway to be programmed:

    ```bash
    kubectl wait gateway/kong-tcp-gateway -n kong \
      --for=condition=Programmed=True \
      --timeout=5m
    ```
    {: data-test-step="block" }

1. Wait for the Gateway to be programmed after the listener change:

    ```bash
    kubectl wait --for=condition=Programmed gateway/kong-tcp-gateway -n kong --timeout=5m
    ```
    {: data-test-step="block" }

1. Get the Gateway's external IP:

    ```bash
    export PROXY_IP=$(kubectl get gateway kong-tcp-gateway -n kong -o jsonpath='{.status.addresses[0].value}')
    echo $PROXY_IP
    ```
    {: data-test-step="block" }

1. Test the Route using `telnet`:

    ```bash
    telnet -e '^X' $PROXY_IP 9000
    ```
    {: data-test-step="block" data-test-retry-count="6" }

   {:.info}
   > The `-e '^X'` flag allows you to chose an escape key to exit telnet.

   After you connect, type some text that you want as a response from the echo Service:

   ```text
   Telnet escape character is '^X'.
   Trying 127.0.0.1...
   Connected to 127.0.0.1.
   Escape character is '^X'.
   Welcome, you are connected to node orbstack.
   Running on Pod echo-bcf7f965b-m5mnv.
   In namespace kong.
   With IP address 127.0.0.1.
   Hello
   Hello
   ```
   {:.no-copy-code}

1. Press `Ctrl+X` and enter `quit` to exit.
