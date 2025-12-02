---
title: Create a Consumer and Consumer Group
description: "Provision Consumers and manage Consumer Groups in {{site.konnect_short_name}} using Kubernetes CRDs."
content_type: how_to

permalink: /operator/konnect/crd/gateway/consumer/
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
  - kgo consumer
  - kgo consumer group
  - kgo credentials
entities: []

tags:
  - konnect-crd
 
tldr:
  q: How can I configure Consumers and Consumer Groups with KGO?
  a: Use the `KongConsumer` and `KongConsumerGroup` CRDs to configure Consumers and Groups in {{site.konnect_short_name}} through your Kubernetes cluster.


prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongConsumer`

Define a `KongConsumer` resource to provision a Consumer in {{site.konnect_short_name}}.

<!-- vale off -->
{% konnect_crd %}
kind: KongConsumer
apiVersion: configuration.konghq.com/v1
metadata:
  name: consumer
username: consumer
custom_id: 08433C12-2B81-4738-B61D-3AA2136F0212
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->


## Create a `KongConsumerGroup`

Creating the KongConsumerGroup object in your Kubernetes cluster will provision a {{site.konnect_short_name}} Consumer Group in your control plane.

<!-- vale off -->
{% konnect_crd %}
kind: KongConsumerGroup
apiVersion: configuration.konghq.com/v1beta1
metadata:
  name: consumer-group
spec:
  name: consumer-group
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->


## Associate a Consumer with a Consumer Group

Update the Consumer to include the `consumerGroups` field referencing the target group.

<!-- vale off -->
{% konnect_crd %}
kind: KongConsumer
apiVersion: configuration.konghq.com/v1
metadata:
  name: consumer
username: consumer
custom_id: 08433C12-2B81-4738-B61D-3AA2136F0212 
consumerGroups:
  - consumer-group # Reference to the KongConsumerGroup object
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->



## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongConsumer
name: consumer
{% endvalidation %}
<!-- vale on -->