---
title: "Config Store-backed Vaults"
description: "How does a KongVault reference a KonnectConfigStore, and where do the secrets it holds actually live?"
content_type: reference
layout: reference
products:
  - operator
works_on:
  - konnect
search_aliases:
  - kgo config store
  - KonnectConfigStore
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Key Concepts
related_resources:
  - text: Create a Vault
    url: /operator/konnect/crd/gateway/vault/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/
  - text: Store TLS certificate private keys in a {{site.konnect_short_name}} Config Store
    url: /operator/konnect/how-to/config-store-certificate-keys/
  - text: Status fields
    url: /operator/konnect/troubleshooting/status/
  - text: "{{site.konnect_short_name}} Config Store vault"
    url: /gateway/entities/vault/konnect-config-store/
min_version:
  operator: '2.3'

---

A `KongVault` with `backend: konnect` stores its secrets in a {{site.konnect_short_name}} Config Store, which is
identified by a `config_store_id`. Instead of creating the Config Store out-of-band and copying its ID into
`spec.config`, you can manage the Config Store with a `KonnectConfigStore` resource and reference it from
`spec.configStoreRef`.

## Resources involved

Four Kubernetes resources describe the setup:

{% table %}
columns:
  - title: Resource
    key: resource
  - title: Purpose
    key: purpose
rows:
  - resource: "`KonnectConfigStore`"
    purpose: |
      Creates the Config Store container in {{site.konnect_short_name}} that holds the secret entries. It manages the
      container only, never the secret values inside it.
  - resource: "`KongReferenceGrant`"
    purpose: |
      Authorizes the cluster-scoped `KongVault` to reference the namespaced `KonnectConfigStore`.
  - resource: "`KongVault`"
    purpose: |
      Creates a Vault with the `konnect` backend and resolves `spec.configStoreRef` into the `config_store_id` of the
      Vault configuration sent to {{site.konnect_short_name}}.
  - resource: "`KongCertificate`"
    purpose: |
      Holds the public certificate inline and a vault reference in place of the private key.
{% endtable %}

The secret value itself is the one step that isn't declarative: it's written straight to {{site.konnect_short_name}}, out-of-band, to avoid storing the secret value in etcd.

## Field behavior

* `spec.configStoreRef` is only supported with `backend: konnect`, and it's mutually exclusive with setting
  `config_store_id` under `spec.config`.
* `spec.prefix` is what you use in vault references later, and it's immutable after creation.
* `KongVault` is cluster-scoped and `KonnectConfigStore` is namespaced, so the reference always crosses a namespace
  boundary and requires a
  [`KongReferenceGrant`](/operator/konnect/cross-namespace-references/#vault-config-store-configuration).
* {{site.operator_product_name}} reports the outcome of the reference in the
  [`ConfigStoreRefValid`](/operator/konnect/troubleshooting/status/#configstorerefvalid-on-kongvault) condition.

## Security boundary

Referencing a secret from a Config Store moves it out of every place you manage with GitOps, but it doesn't remove it
from {{site.konnect_short_name}}:

{% table %}
columns:
  - title: Location
    key: location
  - title: Holds the secret?
    key: holds
rows:
  - location: Git repository and Kubernetes manifests
    holds: No, only the vault reference.
  - location: Kubernetes API and etcd
    holds: No, only the vault reference.
  - location: "{{site.konnect_short_name}} certificate object"
    holds: No, only the vault reference.
  - location: "{{site.konnect_short_name}} Config Store"
    holds: Yes. Access is controlled by {{site.konnect_short_name}} roles and permissions.
  - location: "{{site.base_gateway}} data plane memory"
    holds: |
      Yes, while the secret is in use. {{site.konnect_short_name}} resolves the reference after the data plane
      connects to the control plane.
{% endtable %}

Anyone who can write secrets into the Config Store can replace the key that your listener serves, so treat Config Store write access as equivalent to certificate issuance rights.

## Lifecycle and deletion

* Deleting the `KonnectConfigStore` deletes the Config Store in {{site.konnect_short_name}} along with every secret
  stored in it, including keys that other Vaults or certificates still reference. Delete it only when you're sure
  nothing depends on its contents.
* `spec.configStoreRef` is mutable. Removing it clears the `ConfigStoreRefValid` condition and leaves any
  `config_store_id` you set directly under `spec.config` untouched.
* Removing the `KongReferenceGrant` stops further updates to a programmed `KongVault`, but the Vault that already
  exists in {{site.konnect_short_name}}, including its `config_store_id`, isn't rolled back or removed.
* Rotating a key is a Config Store operation: update the secret value in place, and the vault reference keeps
  resolving without any change to your Kubernetes resources.
