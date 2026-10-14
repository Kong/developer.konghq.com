---
title: "Status Fields"
description: "How do I find out why my resources aren't being reconciled against {{ site.konnect_short_name }}?"
content_type: reference
layout: reference
search_aliases:
  - KGO status fields
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

---

## Status fields

Each Kubernetes resource that is mapped to a {{site.konnect_short_name}} entity has several fields that indicate its status in Konnect.

### {{site.konnect_short_name}} native objects

Objects that are native to {{site.konnect_short_name}},they exist only in {{site.konnect_short_name}} - have the following `status` fields:

- `id` is the unique identifier of the Konnect entity as assigned by {{site.konnect_short_name}} API. If it's unset (empty string), it means the {{site.konnect_short_name}} entity hasn't been created yet.
- `serverURL` is the URL of the {{site.konnect_short_name}} server in which the entity exists.
- `organizationID` is the ID of {{site.konnect_short_name}} Org that this entity has been created in.

To inspect these fields:

```bash
kubectl get <resource> <resource-name> -o yaml | yq '.status'
```

Example output:

```yaml
conditions:
  ...
id: 7dcf6756-b2e7-4067-a19b-111111111111
organizationID: 5ca26716-02f7-4430-9117-111111111111
serverURL: https://us.api.konghq.com
```

These objects are defined under the `konnect.konghq.com` API group.

### {{ site.base_gateway }} configuration objects

Resources like `KongConsumer`, `KongService`, `KongRoute`, and `KongPlugin` configure {{ site.base_gateway }} and are **not** native to {{ site.konnect_short_name }}. These are defined under the `configuration.konghq.com` API group and may be used with other controllers, such as {{ site.kic_product_name }}.

When managed by {{ site.operator_product_name }} for {{ site.konnect_short_name }}, Konnect-specific status fields appear under `.status.konnect`:

- `controlPlaneID`: The ID of the associated Konnect Control Plane.
- `id`: The unique ID assigned by the {{ site.konnect_short_name }} API. If empty, the entity hasn't been created.
- `serverURL`: The URL of the {{ site.konnect_short_name }} server where the entity resides.
- `organizationID`: The Org ID under which the entity was created.

To inspect these fields:


```bash
kubectl get <resource> <resource-name> -o yaml | yq '.status.konnect'
```

Example output:

```yaml
controlPlaneID: 7dcf6756-b2e7-4067-a19b-111111111111
id: 7dcf6756-b2e7-4067-a19b-111111111111
organizationID: 5ca26716-02f7-4430-9117-111111111111
serverURL: https://us.api.konghq.com
```

## Status conditions

Resources also report `status.conditions`, where each condition carries a `reason` that explains the current state.

### `ConfigStoreRefValid` on `KongVault` {% new_in 2.3 %}

The `KongVault` reports the outcome of the reference in the `ConfigStoreRefValid` condition:

```sh
kubectl get kongvault <vault_prefix> -o jsonpath-as-json="{.status.conditions[?(@.type=='ConfigStoreRefValid')]}"
```

{% table %}
columns:
  - title: Reason
    key: reason
  - title: Meaning
    key: meaning
rows:
  - reason: "`Valid`"
    meaning: |
      The referenced `KonnectConfigStore` is programmed and its ID was used as the `config_store_id`.
  - reason: "`NotProgrammed`"
    meaning: |
      The `KonnectConfigStore` exists but hasn't been created in {{site.konnect_short_name}} yet, so its ID is unknown. This resolves on its own once the Config Store is programmed.
  - reason: "`RefNotPermitted`"
    meaning: |
      No `KongReferenceGrant` in the Config Store's namespace allows the reference. Check that the grant's `from`
      entry names the `KongVault` kind with an empty namespace.
  - reason: "`Invalid`"
    meaning: |
      The reference can't be used at all, for example because the `KonnectConfigStore` doesn't exist, the vault
      backend isn't `konnect`, or `spec.config` also sets `config_store_id`. The condition message names the cause,
      and fixing it requires a spec change.
{% endtable %}

While the reference is unresolved, {{site.operator_product_name}} doesn't push the `KongVault` to
{{site.konnect_short_name}}, so that a Vault is never created with a missing or wrong Config Store ID.

### `DeletionBlocked` on `KonnectConfigStore` {% new_in 2.4 %}

A `KonnectConfigStore` that still holds secrets isn't deleted from {{site.konnect_short_name}}. It stays in
`Terminating` and reports `Programmed=False` with reason `DeletionBlocked`:

```sh
kubectl get konnectconfigstore <name> -n <namespace> -o jsonpath-as-json="{.status.conditions[?(@.type=='Programmed')]}"
```

{{site.operator_product_name}} retries periodically, and the deletion proceeds once you remove the secrets from the
Config Store in {{site.konnect_short_name}}. For more information, see
[lifecycle and deletion](/operator/konnect/config-store/#lifecycle-and-deletion).

### `KonnectConfigStoreSync` conditions {% new_in 2.4 %}

A `KonnectConfigStoreSync` always reports four conditions:

* `ConfigStoreRefValid`: whether the referenced `KonnectConfigStore` exists, is programmed, and is allowed by a
  `KongReferenceGrant` if it's in another namespace.
* `SecretRefValid`: whether the referenced Secret exists and is allowed by a `KongReferenceGrant` if it's in another
  namespace. A Secret without the `konghq.com/secret: "true"` label is reported as `NotFound`.
* `PairValid`: whether the certificate and key in the Secret form a valid pair. It's always `NotApplicable` in `Split`
  mode.
* `Synced`: whether every entry is up to date in the Config Store.

To check why a sync isn't `Synced`:

```sh
kubectl get konnectconfigstoresync <name> -n <namespace> -o jsonpath-as-json="{.status.conditions[?(@.type=='Synced')]}"
```

{% table %}
columns:
  - title: Reason
    key: reason
  - title: Meaning
    key: meaning
rows:
  - reason: "`AllEntriesUpToDate`"
    meaning: |
      Every entry is synced. The condition status is `True`.
  - reason: "`WaitingForConfigStore`"
    meaning: |
      The referenced `KonnectConfigStore` doesn't exist, isn't programmed yet, or isn't allowed by a `KongReferenceGrant`.
      Check the `ConfigStoreRefValid` condition.
  - reason: "`SecretRefInvalid`"
    meaning: |
      The referenced Secret is missing, isn't allowed by a `KongReferenceGrant`, or lacks a mapped field. Check the
      `SecretRefValid` condition. The entries already in the Config Store are kept.
  - reason: "`PairMismatch`"
    meaning: |
      The certificate or key is malformed, or they don't match. Nothing is written until the Secret holds a valid pair.
  - reason: "`ValueTooLarge`"
    meaning: |
      An entry value exceeds 5120 bytes. In `Combined` mode, the limit applies to the JSON object that holds both PEM
      values.
  - reason: "`KeyTooLong`"
    meaning: |
      A store key exceeds 512 bytes. This can happen with a derived key built from a long namespace, name, or `Split`
      field name. Use shorter names, or set an explicit, shorter store key in a new `KonnectConfigStoreSync`, because
      store keys are immutable once set.
  - reason: "`KeyConflict`"
    meaning: |
      Another entry or another `KonnectConfigStoreSync` uses the same store key in the same Config Store. The oldest
      sync keeps the key. Use a different store key.
  - reason: "`PushFailed`"
    meaning: |
      The {{site.konnect_short_name}} API request failed. The condition message contains the error.
  - reason: "`EntryInUse`"
    meaning: |
      The sync is being deleted with `deletionPolicy: Delete`, but a `KongCertificate` still references one of its
      entries. Remove the reference, or set `deletionPolicy: Orphan` to keep the entries.
  - reason: "`ConfigStoreDeletionBlocked`"
    meaning: |
      The referenced `KonnectConfigStore` is being deleted, so the sync doesn't write or delete entries. Remove the
      secrets from the Config Store in {{site.konnect_short_name}} to let the deletion proceed.
{% endtable %}
