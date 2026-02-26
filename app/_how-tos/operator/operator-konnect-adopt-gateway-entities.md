---
title: Adopt existing entities from {{ site.konnect_short_name }}
description: "Manage existing gateway entities using Kubernetes CRDs in {{ site.konnect_short_name }}."
content_type: how_to
permalink: /operator/konnect/crd/adoption/gateway/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect
search_aliases:
  - operator gateway entity adoption
entities:
  - service
  - route
  - plugin
tags:
  - konnect-crd

min_version:
  operator: '2.1'
 
tldr:
  q: How can I manage existing {{site.base_gateway}} entities in {{ site.konnect_short_name }} with Kubernetes CRDs?
  a: |
    Create a resource for each entity you want to manage and configure the `spec.adopt` parameters:
    * Set `spec.adopt.konnect.id` to the entity's {{ site.konnect_short_name }} ID.
    * Set `spec.adopt.mode` to:
      * `override` if you want to change the entity's configuration.
      * `match` if you want to keep the existing configuration.

faqs:
  - q: Why can't I override certain entities?
    a: |
      Immutable entities only support adoption in `match` mode and can't be modified after adoption. This is the case for:
      * Cloud Gateway resources: Networks, data plane group configurations, and transit gateways.
      * Data plane client certificates.
      
      You must adopt these entities in `match` mode and configure the resource to match the existing entity in {{ site.konnect_short_name }}.

      Here's an example of network adoption:

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
          mode: match
          konnect:
            id: $NETWORK_ID
        name: network1 
        cloud_gateway_provider_account_id: $CLOUD_GATEWAY_PROVIDER_ID
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


prereqs:
  operator:
    konnect:
      auth: true
  inline:
    - title: Create resources in {{ site.konnect_short_name }}
      include_content: /prereqs/operator/konnect_resources_adoption
    - title: Create the KonnectGatewayControlPlane resource
      include_content: /prereqs/operator/konnect_control_plane_reference
---

## Adopt a Gateway Service

To adopt entities directly referencing a control plane, such as [Services](/gateway/entities/service/), make sure you've created the [`KonnectGatewayControlPlane` resource](#create-the-konnectgatewaycontrolplane-resource) to manage the {{ site.konnect_short_name }} control plane.

In this example, we'll adopt the Service we created in the [prerequisites](#create-resources-in-konnect) in `match` mode. This mode is useful if you want to adopt an entity without making any changes to it yet.

Specify the Service's parameters to match the ones we defined when creating it, and add the Service's {{site.konnect_short_name}} ID and the reference to the control plane:
<!-- vale off -->
{% konnect_crd %}
kind: KongService
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: adopt-service
  namespace: kong
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
  adopt:
    from: konnect
    mode: match
    konnect:
      id: $SERVICE_ID
  name: demo-service
  protocol: http
  host: httpbin.konghq.com
  path: /anything
{% endkonnect_crd %}
<!-- vale on -->

You can validate that the Route was successfully adopted by fetching its configuration using the {{site.konnect_short_name}} API:

{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID
status_code: 200
method: GET
{% endkonnect_api_request %}

You should see `k8s-*` tags, which indicate that the Service is managed with Kubernetes.

## Adopt a Route

To adopt entities that are attached to another entity, such as a [Route](/gateway/entities/route/) attached to a Service, make sure you've created the [`KonnectGatewayControlPlane` resource](#create-the-konnectgatewaycontrolplane-resource) and the [parent resource](#adopt-a-gateway-service). 

Let's adopt the Route we created in the [prerequisites](#create-resources-in-konnect), and this time we'll use `override` mode to change its configuration.

Specify the Route's new parameters, and add the Route's {{site.konnect_short_name}} ID and the reference to the Service:

<!-- vale off -->
{% konnect_crd %}
kind: KongRoute
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: adopt-route
  namespace: kong
spec:
  serviceRef:
    type: namespacedRef
    namespacedRef:
      name: adopt-service
  adopt:
    from: konnect
    mode: override
    konnect:
      id: $ROUTE_ID
  name: demo-route
  paths:
  - "/new"
{% endkonnect_crd %}
<!-- vale on -->

You can validate that the Route was successfully adopted by fetching its configuration using the {{site.konnect_short_name}} API:

{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/routes/$ROUTE_ID
status_code: 200
method: GET
{% endkonnect_api_request %}

You should see the updated configuration and the `k8s-*` tags.

## Adopt a plugin

To adopt a plugin, we need to create two different resources:
* A `KongPlugin` resource to specify the configuration of the plugin.
* A `KongPluginBinding` resource to adopt the plugin by ID and specify the relationship between the plugin and other entities.

In this example, we'll modify the configuration of the [Rate Limiting](/plugins/rate-limiting/) plugin we created in the [prerequisites](#create-resources-in-konnect).

First, create the Rate Limiting `KongPlugin` resource:
<!-- vale off -->
{% konnect_crd %}
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: rate-limit
  namespace: kong
config:
 second: 3
 hour: 300
 policy: local
plugin: rate-limiting
{% endkonnect_crd %}
<!-- vale on -->

Create the `KongPluginBinding` resource to link the `KongPlugin` to the plugin we created in {{site.konnect_short_name}} and associate it to our Service:

<!-- vale off -->
{% konnect_crd %}
apiVersion: configuration.konghq.com/v1alpha1
kind: KongPluginBinding
metadata:
  name: plugin-binding-kongservice
  namespace: kong
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
  pluginRef:
    name: rate-limit
  adopt:
    from: konnect
    mode: override
    konnect:
      id: $PLUGIN_ID 
  targets:
    serviceRef:
      name: adopt-service
      kind: KongService
      group: configuration.konghq.com
{% endkonnect_crd %}
<!-- vale on -->

You can validate that the plugin was successfully adopted by fetching its configuration using the {{site.konnect_short_name}} API:

{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/$PLUGIN_ID
status_code: 200
method: GET
{% endkonnect_api_request %}

You should see the updated configuration and the `k8s-*` tags.