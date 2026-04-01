---
title: Create an Upstream and Target
description: "Provision an Upstream and attach Targets to it in {{site.konnect_short_name}} using Kubernetes CRDs."

content_type: how_to

permalink: /operator/konnect/crd/gateway/upstream-target/
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

entities: []
search_aliases:
  - kgo upstream
  - kgo target
tags:
  - konnect-crd
 
tldr:
  q: How do I configure load balancing with Upstreams and Targets using KGO?
  a: Define a `KongUpstream` and associate one or more `KongTarget` resources with it to distribute traffic across backend services.


prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongUpstream`

Use the `KongUpstream` resource to define a load balancing group for backend services. Your `KongUpstream` must be associated with a `KonnectGatewayControlPlane` object that you’ve created in your cluster.

<!-- vale off -->
{% konnect_crd %}
kind: KongUpstream
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: upstream
spec:
  name: upstream
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

## Create `KongTargets`

Use the `KongTarget` resource to register two individual backend Targets for the Upstream.

First, create `target-a`:

<!-- vale off -->
{% konnect_crd %}
kind: KongTarget
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: target-a
spec:
  upstreamRef:
    name: upstream
  target: "10.0.0.1"
  weight: 30
{% endkonnect_crd %}

Next, `target-b`:

{% konnect_crd %}
kind: KongTarget
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: target-b
spec:
  upstreamRef:
    name: upstream
  target: "10.0.0.2"
  weight: 70
{% endkonnect_crd %}
<!-- vale on -->


## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongUpstream
name: upstream
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KongTarget
name: target-a
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KongTarget
name: target-b
{% endvalidation %}
<!-- vale on -->