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
  - text: Sync a Kubernetes TLS Secret to a {{site.konnect_short_name}} Config Store
    url: /operator/konnect/how-to/config-store-secret-sync/
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

By default, the secret value itself is the one step that isn't declarative: it's written straight to
{{site.konnect_short_name}}, out-of-band, to avoid storing the secret value in etcd. If the secret value is already
stored in a Kubernetes Secret, you can [sync it to the Config Store](#sync-secrets-from-kubernetes) instead.

## Sync secrets from Kubernetes {% new_in 2.4 %}

A `KonnectConfigStoreSync` keeps entries of a `KonnectConfigStore` in sync with the data of a Kubernetes Secret. The
Secret stays the source of truth, so certificate rotation, for example by cert-manager, is only a change to the Secret
data: {{site.operator_product_name}} updates the entry in place and the vault references don't change. The sync uses the
control plane and authentication of the referenced `KonnectConfigStore`.

`spec.mode` controls how the Secret data is mapped to entries:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Behavior
    key: behavior
rows:
  - mode: "`Combined` (default)"
    behavior: |
      Validates that the certificate and key form a valid pair, then writes both to a single entry as a JSON object with
      `certificate` and `key` fields. By default, the certificate is read from `tls.crt` and the key from `tls.key`.
      Reference the fields with `{vault://PREFIX/STORE_KEY/certificate}` and `{vault://PREFIX/STORE_KEY/key}`.
      Use this mode for TLS certificates, because the pair is always updated at once.
  - mode: "`Split`"
    behavior: |
      Writes each listed Secret field to its own entry, referenced with `{vault://PREFIX/STORE_KEY}`. Use this mode for
      single-field and non-TLS values.
{% endtable %}

The following rules apply to a `KonnectConfigStoreSync`:

* The block that matches `spec.mode` must be set, so use `combined: {}` to accept the `Combined` defaults.
* If you don't set a store key, it's derived from the sync's namespace and name, in the format
  `k8s-<len(namespace)>-<namespace>-<len(name)>-<name>`. In `Split` mode, the field name is appended.
  `status.references` lists the suffix to use after the Vault prefix in each vault reference.
* `spec.mode`, `spec.configStoreRef`, and store keys are immutable once set. To change them, create a new
  `KonnectConfigStoreSync`, move your references to its entries, then delete the old one. `spec.secretRef` is mutable
  and doesn't change the entry names.
* Referencing a `KonnectConfigStore` or a Secret in another namespace requires a `KongReferenceGrant` in that namespace.
* Each entry value is limited to 5120 bytes and each store key to 512 bytes. In `Combined` mode, the limit applies to
  the JSON object that holds both PEM values.
* If the Secret is missing or its data is invalid, nothing is written and the last synced value keeps serving.
* Status, logs, and events never contain the secret value. `status.entries` only reports a hash, the size, the
  certificate expiry, and timestamps for each entry.

For a complete example, see
[Sync a Kubernetes TLS Secret to a {{site.konnect_short_name}} Config Store](/operator/konnect/how-to/config-store-secret-sync/).

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

If you [sync the secret from Kubernetes](#sync-secrets-from-kubernetes), the secret value is also stored in the
Kubernetes Secret, and therefore in the Kubernetes API and etcd. The {{site.konnect_short_name}} certificate object
still only holds the vault reference.

## Lifecycle and deletion

* {% new_in 2.4 %} {{site.operator_product_name}} doesn't delete a Config Store that still holds secrets, because a
  deleted key breaks every certificate that references it. The `KonnectConfigStore` stays in `Terminating`, which also
  blocks the deletion of its namespace, and reports `Programmed=False` with reason `DeletionBlocked`. Deletion proceeds
  automatically once you remove the secrets from the Config Store in {{site.konnect_short_name}}. To leave the Config
  Store and its secrets in {{site.konnect_short_name}} instead, remove the `gateway.konghq.com/konnect-cleanup`
  finalizer from the `KonnectConfigStore`.

  In {{site.operator_product_name}} 2.3, deleting the `KonnectConfigStore` deletes the Config Store in
  {{site.konnect_short_name}} along with every secret stored in it, including keys that other Vaults or certificates
  still reference.
* {% new_in 2.4 %} `spec.deletionPolicy` of a `KonnectConfigStoreSync` controls what happens to its entries when the
  sync is deleted. With `Orphan`, the default, the entries are kept. With `Delete`, the entries are deleted unless a
  `KongCertificate` still references them, in which case the sync reports `Synced=False` with reason `EntryInUse` and
  waits. This check only covers `KongCertificate` resources, so make sure that nothing else uses the entries. While the
  `KonnectConfigStore` is being deleted, the sync doesn't write or delete entries.
* `spec.configStoreRef` is mutable. Removing it clears the `ConfigStoreRefValid` condition and leaves any
  `config_store_id` you set directly under `spec.config` untouched.
* Removing the `KongReferenceGrant` stops further updates to a programmed `KongVault`, but the Vault that already
  exists in {{site.konnect_short_name}}, including its `config_store_id`, isn't rolled back or removed.
* Rotating a key is a Config Store operation: update the secret value in place, and the vault reference keeps
  resolving without any change to your Kubernetes resources. If the entry is managed by a `KonnectConfigStoreSync`,
  update the Kubernetes Secret instead.
