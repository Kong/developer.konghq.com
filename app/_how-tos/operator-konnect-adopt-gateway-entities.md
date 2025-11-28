---
title: Adopting Existing Gateway Entities from {{ site.konnect_short_name }}
description: "How to manage existing gateway entities using Kubernetes CRDs in {{ site.konnect_short_name }} by adoption"
content_type: how_to
permalink: /operator/konnect/crd/adoption/gateway
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Gateway"

products:
  - operator

works_on:
  - konnect
search_aliases:
  - operator gateway entity adoption
entities: []
tags:
  - konnect-crd
 
tldr:
  q: How do I manage existing gateway entities (like services, routes, plugins, ...) in {{ site.konnect_short_name }} by Kubernetes CRDs?
  a: Create a Kubernetes resource adopting the existing entity by its {{ site.konnect_short_name }} ID.


prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

You can manage a gateway entity in {{ site.konnect_short_name }} by a Kubernetes custom resource adopting it. To create such a custom resource, you need to have the control plane already created in the Kubernetes cluster.

## Create a Custom Resource in Kubernetes to adopt the entity

### Create a Custom Resource directly referencing a control plane

For entities directly referencing the control plane where they are in like services, you need to first have the `KonnectGatewayControlPlane` in the cluster to manage the {{ site.konnect_short_name }} control plane. Then you can create a custom resource to adopt it. Take a `service` as an example:

<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: adopt-service
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane # Reference to the KonnectGatewayControlPlane object
  adopt:
    from: konnect
    mode: override # Set to "override" to override the service in Konnect by the spec in the resource
    konnect:
      id: "08433c21-28b2-4738-b66c-3aa25f16032d" # The ID of the service in Konnect
  host: "example.com"
  protocol: "https"
{% endkonnect_crd %}
<!-- vale on -->

### Create a resource attaching to another resource

For entities that is attached to another entity (like a route attached to a service), you need have the `KonnectGatewayControlPlane` and also the parent resource already created in the Kubernetes cluster (the `KongService` in the example). Then you can create a resource to manage the existing entity, like a `KongRoute` for the route:

<!-- vale off -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: adopt-route
spec:
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: adopt-service # The name of the `KongService` it attaches to
  adopt:
    from: konnect
    mode: override # Set to "override" to override the route in Konnect by the spec in the resource
    konnect:
      id: "08433c21-28b2-4738-ae86-faab31415926" # The ID of the route in Konnect
    name: route-1
    protocols:
    - http
    hosts:
    - example.com
    paths:
    - "/example"
{% endkonnect_crd %}
<!-- vale on -->

### Create a KongPluginBinding and a KongPlugin to adopt a plugin

For Plugins, you need to create 2 different custom resource for adopting a plugin in {{ site.konnect_short_name }}. A `KongPlugin` needs to be created to specify the configuration of the plugin and a `KongPluginBinding` needs to be created to adopt the plugin by ID and specify the relationship of the plugin and attached entities.

The example below shows the resources needs to be created for adopting a `rate-limiting` plugin attached to a service in {{ site.konnect_short_name }}.

<!-- vale off -->
{% konnect_crd %}
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
 name: rate-limit-5-min
config:
 minute: 5
 policy: local
plugin: rate-limiting
---
apiVersion: configuration.konghq.com/v1alpha1
kind: KongPluginBinding
metadata:
  name: plugin-binding-kongservice
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane # Reference to the KonnectGatewayControlPlane object
  pluginRef:
    name: rate-limit-5-min # Reference to the KongPlugin resource storing the plugin configuration
  adopt:
    from: konnect
    mode: override # Set to "override" to override the plugin in Konnect by the spec in the resource
    konnect:
      id: "08433c21-28b2-4739-bc01-abc012def456" # The ID of the plugin in Konnect  
  targets:
    serviceRef:
      name: adopt-service # The name of the `KongService` it attaches to
      kind: KongService
      group: configuration.konghq.com
{% endkonnect_crd %}
<!-- vale on -->

## Adopting Cloud Gateway Entities

The {{ site.konnect_short_name }} cloud gateway resources including networks, dataplane group configurations, and transit gateways are immutable, so we cannot modify them after created by adoption. We must adopt them in "match" mode, which adoption works only the spec of the Kubernetes resource matches the existing entity in {{ site.konnect_short_name }}.

Also, {{ site.konnect_short_name }} dataplane client certificates are immutable so they only supports the match mode adoption.

Here is an example of adopting a network in {{ site.konnect_short_name }} cloud gateway:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectCloudGatewayNetwork
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: adopt-konnect-network
  namespace: default
spec:
  adopt:
    from: konnect
    mode: match # Can only set to "match" because CGW networks are immutable
    konnect:
      id: "01234567-a001-b234-c456-d789e654f321" # The ID of the network in Konnect
  name: network1 # every field must match the existing network in Konnect, otherwise the adoption fails
  cloud_gateway_provider_account_id: "01234567-a001-b234-c456-aabbccddeeff" # The cloud gateway provider ID that can be got from getting the network by API
  availability_zones:
  - "use1-az1"
  - "use1-az2"
  - "use1-az4"
  - "use1-az5"
  - "use1-az6"
  cidr_block: "10.0.0.1/24"
  region: "us-east-1"
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
