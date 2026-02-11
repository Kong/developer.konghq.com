---
title: Configure a plugin for a specific HTTPRoute
description: "Learn how to attach plugins to HTTPRoute resources using KongPluginBinding, ExtensionRef, or annotations."
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

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway
    - title: Create a Service and a Route
      include_content: /prereqs/operator/echo-service-route

tldr:
  q: How do I attach a plugin to an HTTPRoute with {{ site.operator_product_name }}?
  a: |
    Use an `ExtensionRef`, the legacy `konghq.com/plugins` annotation, or the `KongPluginBinding` resource ({{site.konnect_short_name}} only).
---

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

## Apply the plugin to the HTTPRoute

{% navtabs "Methods" %}

{% navtab "KongPluginBinding (Konnect only)" %}

The `KongPluginBinding` resource can be used when managing entities in {{site.konnect_short_name}} or when using the Hybrid mode. 
It allows you to bind a plugin to one or more entities without modifying those entities.

For more details about the `KongPluginBinding` resources, see [Understanding KongPluginBinding](/operator/konnect/kongpluginbinding/).

Use this method if you need to reuse the same plugin configuration across multiple Routes without editing each Route resource, or if you do not have permission to modify the Route.

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
      name: gateway-control-plane
  pluginRef:
    name: rate-limit-example
  targets:
    routeRef:
      group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: echo-route
' | kubectl apply -f -
```
{% endnavtab %}

{% navtab "ExtensionRef" %}

The Gateway API supports extending Route rules using `filters`. {{ site.operator_product_name }} supports the `ExtensionRef` filter type to attach plugins directly to the `HTTPRoute` specification. This is the preferred method for standard Gateway API deployments.

```sh
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
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
          port: 1027' | kubectl apply -f -
```
{% endnavtab %}

{% navtab "Annnotation (legacy)" %}

You can use the `konghq.com/plugins` annotation on the `HTTPRoute` resource:

```sh
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-route
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
          port: 1027' | kubectl apply -f -
```

This method is consistent with the [{{site.kic_product_name}}](/kubernetes-ingress-controller/) behavior.

{% endnavtab %}
{% endnavtabs %}

## Validate

1.  Get the proxy IP address:
    ```bash
    export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
    ```

1.  Send multiple requests to the `/echo` endpoint:
    ```bash
    for i in {1..6}; do curl -s http://$PROXY_IP/echo; done
    ```

   You should receive a `429 Too Many Requests` status code with the last request.
