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
  - text: Store TLS certificate private keys in a {{site.konnect_short_name}} Config Store
    url: /operator/konnect/how-to/config-store-certificate-keys/
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

## Create a {{site.konnect_short_name}} Config Store-backed `KongVault` {% new_in 2.3 %}

The `konnect` backend stores secrets in a {{site.konnect_short_name}} Config Store, which is identified by a
`config_store_id`. Instead of creating the Config Store out-of-band and copying its ID into `spec.config`, you can
manage the Config Store with a `KonnectConfigStore` resource and reference it from `spec.configStoreRef`:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectConfigStore
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-config-store
spec:
  controlPlaneRef:
    type: namespacedRef
    namespacedRef:
      name: gateway-control-plane
  apiSpec:
    name: konnect-config-store
{% endkonnect_crd %}
<!-- vale on -->

`KongVault` is cluster-scoped and `KonnectConfigStore` is namespaced, so the reference always crosses a namespace
boundary. The namespace holding the `KonnectConfigStore` must allow it with a
[`KongReferenceGrant`](/operator/konnect/cross-namespace-references/#vault-config-store-configuration), and because a
`KongVault` has no namespace of its own, the grant lists `namespace: ""` in its `from` entry:

```sh
echo '
apiVersion: configuration.konghq.com/{{ site.operator_kongreferencegrant_api_version }}
kind: KongReferenceGrant
metadata:
  name: allow-kongvault-to-konnect-resources
  namespace: kong
spec:
  from:
    - group: configuration.konghq.com
      kind: KongVault
      namespace: ""
  to:
    - group: konnect.konghq.com
      kind: KonnectConfigStore
    - group: konnect.konghq.com
      kind: KonnectGatewayControlPlane' | kubectl apply -f -
```

Now create the `KongVault`:

<!-- vale off -->
{% konnect_crd %}
kind: KongVault
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: konnect-vault
spec:
  backend: konnect
  prefix: konnect-vault
  configStoreRef:
    kind: KonnectConfigStore
    name: konnect-config-store
    namespace: kong
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
      namespace: kong
{% endkonnect_crd %}
<!-- vale on -->

{{ site.operator_product_name }} resolves the reference to the {{site.konnect_short_name}} ID of the
`KonnectConfigStore`, uses it as the `config_store_id` of the Vault configuration, and reports the outcome in the
`ConfigStoreRefValid` condition.

`spec.configStoreRef` is only supported with `backend: konnect`, and it's mutually exclusive with setting
`config_store_id` under `spec.config`.

For an end-to-end example that keeps TLS private keys out of Kubernetes entirely, see
[Store TLS certificate private keys in a {{site.konnect_short_name}} Config Store](/operator/konnect/how-to/config-store-certificate-keys/).

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongVault
name: env-vault
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KonnectConfigStore
name: konnect-config-store
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KongVault
name: konnect-vault
{% endvalidation %}
<!-- vale on -->
