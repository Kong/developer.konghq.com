---
title: Preserve client IP addresses
description: "Learn how to configure {{site.operator_product_name}} to preserve the original client IP address using externalTrafficPolicy."
content_type: how_to
permalink: /operator/dataplanes/how-to/preserve-client-ip/
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

prereqs:
  operator:
    konnect:
      auth: true

tldr:
  q: How do I see the real client IP in Kong logs?
  a: "Configure `externalTrafficPolicy: Local` in your `GatewayConfiguration`."
cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `Gateway` also deletes the control plane and data plane resources {{ site.operator_product_name }} created for it. Deleting the `kong-system` namespace removes the operator:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          gateway/kong-external-traffic \
          gatewayconfiguration/preserve-client-ip
        kubectl delete --ignore-not-found gatewayclass/kong-external-traffic
        kubectl delete --ignore-not-found namespace kong
        helm uninstall kong-operator -n kong-system
        kubectl delete --ignore-not-found namespace kong-system
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg
---

By default, when traffic enters a Kubernetes cluster through a Service of type `LoadBalancer`, the source IP is often replaced with the IP of the node (SNAT). This means your applications and access logs see the node's IP instead of the client's IP.

To preserve the client IP, you can configure the underlying Service to use `externalTrafficPolicy: Local`.

{% include /k8s/kong-namespace.md %}

## Create a GatewayConfiguration

Create a `GatewayConfiguration` that sets the `externalTrafficPolicy` to `Local` in the `dataPlaneOptions`:

{% konnect %}
content: |
  ```yaml
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: preserve-client-ip
    namespace: kong
  spec:
    konnect:
      authRef:
        name: konnect-api-auth
        namespace: kong
    dataPlaneOptions:
      network:
        services:
          ingress:
            externalTrafficPolicy: Local
            type: LoadBalancer' | kubectl apply -f -
  ```
  {: data-test-step="block" }
{% endkonnect %}

{% on_prem %}
content: |
  ```yaml
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: preserve-client-ip
    namespace: kong
  spec:
    dataPlaneOptions:
      network:
        services:
          ingress:
            externalTrafficPolicy: Local
            type: LoadBalancer' | kubectl apply -f -
  ```
  {: data-test-step="block" }
{% endon_prem %}

### Configure the Gateway

Create a `GatewayClass` resource that references the `GatewayConfiguration`, and a `Gateway` that references the `GatewayClass`:

{% konnect %}
content: |
  ```yaml
  echo '
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: kong-external-traffic
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: preserve-client-ip
      namespace: kong
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: kong-external-traffic
    namespace: kong
    annotations:
      gateway-operator.konghq.com/static-naming: "true"
  spec:
    gatewayClassName: kong-external-traffic
    listeners:
    - name: http
      protocol: HTTP
      port: 80' | kubectl apply -f -
  ```
  {: data-test-step="block" }
{% endkonnect %}

{% on_prem %}
content: |
  ```yaml
  echo '
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: kong-external-traffic
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: preserve-client-ip
      namespace: kong
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: kong-external-traffic
    namespace: kong
  spec:
    gatewayClassName: kong-external-traffic
    listeners:
    - name: http
      protocol: HTTP
      port: 80' | kubectl apply -f -
  ```
  {: data-test-step="block" }
{% endon_prem %}

## Validate

1. Wait for the Gateway to be programmed. The operator creates the generated Service with it:

    ```bash
    kubectl wait --for=condition=Programmed gateway/kong-external-traffic -n kong --timeout=5m
    ```
    {: data-test-step="block" }

1.  Check the generated Service for the `externalTrafficPolicy` setting:

{% validation custom-command %}
command: |
  kubectl get service -n kong -l gateway-operator.konghq.com/dataplane-service-type=ingress -o jsonpath='{.items[0].spec.externalTrafficPolicy}'
expected:
  return_code: 0
  message: Local
render_output: false
indent: 4
{% endvalidation %}

    The output should be `Local`. 

