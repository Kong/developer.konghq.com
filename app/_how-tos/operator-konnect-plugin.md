---
title: Enable a plugin on a Route
description: "Enable a plugin on a Route in {{site.konnect_short_name}} using the KongPlugin and KongPluginBinding CRDs and configure it for use with your control plane."
content_type: how_to

permalink: /operator/konnect/crd/gateway/plugin/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Gateway"

products:
  - operator
search_aliases:
  - kgo plugin
works_on:
  - konnect

entities: []

tags:
  - konnect-crd
related_resources:
  - text: Understanding KongPluginBinding
    url: /operator/konnect/kongpluginbinding/
  - text: KongPlugin reference
    url: /operator/reference/custom-resources/#kongplugin
  - text: Plugins
    url: /gateway/entities/plugin/
tldr:
  q: How do I enable and configure a plugin in {{site.konnect_short_name}} that's associated with another entity using KGO?
  a: You can associate plugins with an entity, like a Consumer or Gateway Service, in {{site.konnect_short_name}}. To do this with KGO, you must create a `KongPlugin` and use `KongPluginBinding` to associate it with another entity.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongService` 
 
In this tutorial, we'll bind a plugin to {{site.base_gateway}} entities, like a Route, using the `KongPluginBinding` CRD. 

First, create a Gateway Service in {{site.konnect_short_name}} using the `KongService` CRD:

<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: example-service
spec:
  name: example-service
  host: httpbin.konghq.com
  protocol: http
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Create a `KongRoute`

To expose the Service, create a `KongRoute` associated with the `KongService` defined previously:

<!-- vale off -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: example-route
spec:
  name: example-route
  protocols:
  - http
  paths:
  - /anything
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: example-service
{% endkonnect_crd %}
<!-- vale on -->

## Enable a `KongPlugin` and create a `KongPluginBinding`

In this tutorial, you'll enable a simple configuration of the [Rate Limiting](/plugins/rate-limiting/) plugin. 

First, enable the plugin:

<!-- vale off -->
{% konnect_crd %}
kind: KongPlugin
apiVersion: configuration.konghq.com/v1
metadata:
  namespace: kong
  name: rate-limiting-minute-5
plugin: rate-limiting
config:
  policy: local
  minute: 5
  hour: 1000
{% endkonnect_crd %}
<!-- vale on -->

Then, to bind the plugin to the Route, create a `KongPluginBinding`:

<!-- vale off -->
{% konnect_crd %}
kind: KongPluginBinding
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: binding-route-example-rate-limiting
spec:
  pluginRef:
    kind: KongPlugin
    name: rate-limiting-minute-5
  targets:
    routeRef:
      group: configuration.konghq.com
      kind: KongRoute
      name: example-route
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Validate

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongPluginBinding
name: binding-route-example-rate-limiting
{% endvalidation %}
<!-- vale on -->