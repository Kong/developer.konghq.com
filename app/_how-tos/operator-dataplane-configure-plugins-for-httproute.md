---
# @TODO KO 2.1
title: Configure Plugins for HTTPRoute
description: "Learn how to attach Kong Plugins to Gateway API HTTPRoute resources using KongPluginBinding, ExtensionRef, or annotations."
content_type: how_to
permalink: /operator/dataplanes/how-to/configure-plugins-for-httproute/
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
tldr:
  q: How do I attach a plugin to an HTTPRoute with {{ site.operator_product_name }}?
  a: Use the `KongPluginBinding` CRD (recommended), an `ExtensionRef` filter in the `HTTPRoute` spec, or the legacy `konghq.com/plugins` annotation.
---

## Overview

In the Kong Operator, you can apply plugins to specific routes to control behavior like rate limiting, authentication, or request transformation. When using the [Gateway API](https://gateway-api.sigs.k8s.io/) `HTTPRoute` resource, the available methods depend on your deployment topology:

- **Self-managed Control Plane (KIC)**: Use `ExtensionRef` filters or `konghq.com/plugins` annotations.
- **Konnect/Hybrid Mode**: Use the `KongPluginBinding` CRD.

## Prerequisites

- Access to a Kubernetes cluster with {{ site.operator_product_name }} installed.
- A functional `Gateway` and `HTTPRoute`. You can follow the [Create a Route](/operator/dataplanes/get-started/kic/create-route/) guide to set one up.

## Create a KongPlugin

Regardless of the attachment method, you first need to define the plugin configuration using the `KongPlugin` CRD.

```bash
echo '
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: rate-limit-example
  namespace: kong
plugin: rate-limiting
config:
  minute: 5
  policy: local
' | kubectl apply -f -
```

## Method 1: ExtensionRef Filter (Gateway API Standard)

The Gateway API supports extending route rules using `filters`. {{ site.operator_product_name }} supports the `ExtensionRef` filter type to attach Kong plugins directly within the `HTTPRoute` specification. This is the preferred method for standard Gateway API deployments.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
  namespace: kong
spec:
  parentRefs:
    - name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      filters:
        - type: ExtensionRef
          extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: rate-limit-example
      backendRefs:
        - name: echo
          port: 1027
```

## Method 2: Annotations (Legacy)

You can use the `konghq.com/plugins` annotation on the `HTTPRoute` resource. This is consistent with the behavior of the Kong Ingress Controller.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
  namespace: kong
  annotations:
    konghq.com/plugins: rate-limit-example
spec:
  parentRefs:
    - name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo
          port: 1027
```

## Method 3: KongPluginBinding (Konnect/Hybrid only)

The `KongPluginBinding` resource is used when managing entities in **Konnect** or when using the **Hybrid Gateway** mode. It allows you to bind a plugin to one or more entities without modifying those entities.

> [!NOTE]
> This method is not supported for standard self-managed deployments.

For more details on how `KongPluginBinding` works and advanced usage scenarios, see the [Understanding KongPluginBinding](/operator/konnect/key-concepts/kongpluginbinding/) reference.

Use this method if you need to reuse the same plugin configuration across multiple routes without editing each Route resource, or if you do not have permission to modify the Route.

```bash
echo '
apiVersion: configuration.konghq.com/v1alpha1
kind: KongPluginBinding
metadata:
  name: bind-rate-limit-to-route
  namespace: kong
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: my-konnect-control-plane
  pluginRef:
    name: rate-limit-example
  targets:
    routeRef:
      group: configuration.konghq.com
      kind: KongRoute
      name: echo
' | kubectl apply -f -
```

## Verify the Plugin

Once the plugin is attached, you can verify it by making requests to your proxy and checking the response headers.

1.  Get the proxy IP address:
    ```bash
    export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
    ```

2.  Make multiple requests to the `/echo` endpoint:
    ```bash
    curl -i http://$PROXY_IP/echo
    ```

3.  Check the response for rate-limiting headers:
    ```text
    HTTP/1.1 200 OK
    ...
    X-RateLimit-Limit-Minute: 5
    X-RateLimit-Remaining-Minute: 4
    ...
    ```

If you exceed the limit (5 requests per minute in this example), you should receive a `429 Too Many Requests` status code.
