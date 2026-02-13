---
title: Create a Vault
description: "Provision a Vault in {{site.konnect_short_name}} using the KongVault CRD and configure it for use with your Control Plane."
content_type: how_to

permalink: /operator/konnect/crd/gateway/vault/
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
  - kgo vault
works_on:
  - konnect

entities: []

tags:
  - konnect-crd
related_resources:
  - text: Vault
    url: /gateway/entities/vault/
tldr:
  q: How do I create and configure a Vault in Konnect using KGO?
  a: Define a `KongVault` resource and associate it with your `KonnectGatewayControlPlane` to manage secrets using a configured backend.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongVault`

Use the `KongVault` resource to provision a Vault in {{site.konnect_short_name}}. The Vault defines a secure configuration backend. Your `KongVault` must be associated with a `KonnectGatewayControlPlane` object that you’ve created in your cluster.

<!-- vale off -->
{% konnect_crd %}
kind: KongVault
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: env-vault
spec:
  backend: env
  prefix: env-vault
  config:
    prefix: env-vault
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
      namespace: kong
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongVault
name: env-vault
{% endvalidation %}
<!-- vale on -->