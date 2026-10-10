---
title: Sync a Kubernetes TLS Secret to a {{site.konnect_short_name}} Config Store
description: "Keep TLS private keys out of your {{site.konnect_short_name}} certificate objects by syncing a Kubernetes Secret into a Config Store with a KonnectConfigStoreSync."
content_type: how_to

permalink: /operator/konnect/how-to/config-store-secret-sync/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

search_aliases:
  - KonnectConfigStoreSync
  - kgo config store sync
  - cert-manager config store

tags:
  - konnect-crd
  - secrets-management
  - certificates

related_resources:
  - text: Config Store-backed Vaults
    url: /operator/konnect/config-store/
  - text: Store TLS certificate private keys in a {{site.konnect_short_name}} Config Store
    url: /operator/konnect/how-to/config-store-certificate-keys/
  - text: Create a Certificate and CA Certificate
    url: /operator/konnect/crd/gateway/certificate-ca-cert/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/
  - text: Status fields
    url: /operator/konnect/troubleshooting/status/

tldr:
  q: How do I keep a TLS private key from a Kubernetes Secret out of my {{site.konnect_short_name}} certificate objects?
  a: |
    Create a `KonnectConfigStoreSync` that points to the Secret and to a `KonnectConfigStore`. {{site.operator_product_name}}
    writes the certificate and key to a single Config Store entry. Then set `spec.cert` and `spec.key` of a
    `KongCertificate` to `{vault://PREFIX/STORE_KEY/certificate}` and `{vault://PREFIX/STORE_KEY/key}`. When the Secret
    changes, the entry is updated in place and the references stay the same.

min_version:
  operator: '2.4'

faqs:
  - q: How is this different from writing the key to the Config Store directly?
    a: |
      With a `KonnectConfigStoreSync`, the Kubernetes Secret stays the source of truth, so tools like cert-manager can keep
      issuing and rotating certificates as usual. The private key is still stored in the Kubernetes API and etcd. If the
      key must never enter your cluster, write it to the Config Store directly instead, as described in
      [Store TLS certificate private keys in a {{site.konnect_short_name}} Config Store](/operator/konnect/how-to/config-store-certificate-keys/).
  - q: "Why do I need `combined: {}` if `Combined` is the default mode?"
    a: |
      Validation requires the block that matches `spec.mode` to be set. Use `combined: {}` to accept the defaults, which
      read the certificate from `tls.crt` and the key from `tls.key`, and derive the store key from the namespace and
      name of the `KonnectConfigStoreSync`.
  - q: Can I sync the certificate and the key into separate entries?
    a: |
      `mode: Split` writes each Secret field to its own entry, but it's intended for single-field and non-TLS values.
      A two-entry rotation briefly exposes a mismatched certificate and key, so use `Combined` for TLS pairs.
  - q: What happens if the Secret is deleted or contains invalid data?
    a: |
      Nothing is written to the Config Store. If the Secret is missing, or the certificate and key are malformed or don't
      match, the `KonnectConfigStoreSync` reports `Synced=False` and the last value written to the Config Store keeps
      serving. For every condition reason, see [`KonnectConfigStoreSync` conditions](/operator/konnect/troubleshooting/status/#konnectconfigstoresync-conditions).
  - q: What happens to the Config Store entry when I delete the `KonnectConfigStoreSync`?
    a: |
      With the default `spec.deletionPolicy: Orphan`, the entry is kept. With `Delete`, {{site.operator_product_name}}
      deletes the entries that the sync owns, unless a `KongCertificate` still references them. For more information, see
      [lifecycle and deletion](/operator/konnect/config-store/#lifecycle-and-deletion).

next_steps:
  - text: Map hostnames to the certificate with SNIs
    url: /gateway/entities/sni/
  - text: Review what else can be stored as a secret
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
---

A `KongCertificate` that reads its certificate and key from a Kubernetes Secret sends the private key to
{{site.konnect_short_name}} as part of the certificate object. Anyone who can read certificates in
{{site.konnect_short_name}} can read the key.

A `KonnectConfigStoreSync` keeps the Secret as the source of truth but writes the certificate and key to a
{{site.konnect_short_name}} Config Store entry instead. The `KongCertificate` then references that entry through a
`KongVault`, so the {{site.konnect_short_name}} certificate object only holds vault references. When the Secret is
updated, for example by cert-manager, the entry is updated in place and the references don't change.

{:.warning}
> The private key is still stored in the Kubernetes Secret, and therefore in the Kubernetes API and etcd. Restrict access
> to the Secret and enable [encryption at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).

## Create a `KonnectConfigStore`

Create the Config Store container in {{site.konnect_short_name}}. It must reference the `KonnectGatewayControlPlane`
that owns the Config Store:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectConfigStore
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: cert-keys
spec:
  controlPlaneRef:
    type: namespacedRef
    namespacedRef:
      name: gateway-control-plane
  apiSpec:
    name: cert-keys
{% endkonnect_crd %}

{% validation kubernetes-resource %}
kind: KonnectConfigStore
name: cert-keys
{% endvalidation %}
<!-- vale on -->

## Allow the `KongVault` to reference the Config Store

`KongVault` is cluster-scoped, so its references to the `KonnectConfigStore` and to the `KonnectGatewayControlPlane`
cross a namespace boundary. Allow them with a `KongReferenceGrant` whose `from` entry sets `namespace: ""`:

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

## Create a `KongVault` backed by the Config Store

Create a `KongVault` with `backend: konnect` and point `spec.configStoreRef` to the `KonnectConfigStore`:

<!-- vale off -->
{% konnect_crd %}
kind: KongVault
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: certvault
spec:
  backend: konnect
  prefix: certvault
  description: TLS certificates synced from Kubernetes Secrets
  configStoreRef:
    kind: KonnectConfigStore
    name: cert-keys
    namespace: kong
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
      namespace: kong
{% endkonnect_crd %}

{% validation kubernetes-resource %}
kind: KongVault
name: certvault
{% endvalidation %}
<!-- vale on -->

## Create a TLS Secret

1. Generate a self-signed certificate and key:

   ```sh
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=example.localdomain.dev"
   ```

1. Store them in a TLS Secret:

   ```sh
   kubectl create secret tls example-tls -n kong --cert=tls.crt --key=tls.key
   ```

1. {{site.operator_product_name}} only reads Secrets that carry the `konghq.com/secret: "true"` label. Add the label so
   that {{site.operator_product_name}} can read the Secret:

   ```sh
   kubectl label secret example-tls -n kong konghq.com/secret="true"
   ```

## Sync the Secret to the Config Store

Create a `KonnectConfigStoreSync` that references the Secret and the `KonnectConfigStore`. In `Combined` mode,
{{site.operator_product_name}} checks that the certificate and key form a valid pair, then writes both to a single
Config Store entry as a JSON object with `certificate` and `key` fields:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectConfigStoreSync
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: example-tls
spec:
  configStoreRef:
    name: cert-keys
  secretRef:
    name: example-tls
  mode: Combined
  combined:
    storeKey: example-tls
{% endkonnect_crd %}
<!-- vale on -->

`spec.combined.storeKey` sets the name of the Config Store entry and is immutable. If you omit it,
{{site.operator_product_name}} derives the name from the namespace and name of the `KonnectConfigStoreSync`, in the
format `k8s-<len(namespace)>-<namespace>-<len(name)>-<name>`.

Confirm that the Secret is synced:

<!-- vale off -->
{% validation kubernetes-resource-property %}
kind: konnectconfigstoresync
name: example-tls
path: |
  .status.conditions[] | select(.type == "Synced") | .status
expected: "True"
{% endvalidation %}
<!-- vale on -->

The `KonnectConfigStoreSync` publishes the suffixes to use in vault references in `status.references`:

```sh
kubectl get konnectconfigstoresync example-tls -n kong -o jsonpath-as-json='{.status.references}'
```

```json
[
  {
    "subfield": "certificate",
    "suffix": "example-tls/certificate"
  },
  {
    "subfield": "key",
    "suffix": "example-tls/key"
  }
]
```
{:.no-copy-code}

## Create a `KongCertificate` that references the entry

Set `spec.cert` and `spec.key` to vault references of the form `{vault://PREFIX/SUFFIX}`, where `PREFIX` is the
`spec.prefix` of the `KongVault` and `SUFFIX` comes from `status.references`:

<!-- vale off -->
{% konnect_crd %}
kind: KongCertificate
apiVersion: configuration.konghq.com/{{ site.operator_kongcertificate_api_version }}
metadata:
  name: cert-from-secret-sync
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
  cert: '{vault://certvault/example-tls/certificate}'
  key: '{vault://certvault/example-tls/key}'
{% endkonnect_crd %}

{% validation kubernetes-resource %}
kind: KongCertificate
name: cert-from-secret-sync
{% endvalidation %}
<!-- vale on -->

Use the default `spec.type: inline`. With `spec.type: secretRef`, the `KongCertificate` reads the key from the Secret
and sends it to {{site.konnect_short_name}}.

## Validate

1. Fetch the {{site.konnect_short_name}} ID of the control plane:

   ```sh
   export CONTROL_PLANE_ID=$(kubectl get -n kong konnectgatewaycontrolplanes.konnect.konghq.com gateway-control-plane -o jsonpath='{.status.id}')
   ```

1. Confirm that the certificate stored in {{site.konnect_short_name}} holds the vault references rather than the
   certificate and key material:
{% capture request %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/certificates
status_code: 200
method: GET
indent: 3
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{request | indent}}

   The `cert` and `key` fields in the response are `{vault://certvault/example-tls/certificate}` and
   `{vault://certvault/example-tls/key}`.

1. Rotate the certificate by replacing the contents of the Secret:

   ```sh
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=example.localdomain.dev"
   kubectl create secret tls example-tls -n kong --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl apply -f -
   ```

1. Check the entry status. The `hash`, `notAfter`, and `lastPushTime` fields change once the new pair is synced, while
   the `KongCertificate` and its vault references stay the same:

   ```sh
   kubectl get konnectconfigstoresync example-tls -n kong -o jsonpath-as-json='{.status.entries}'
   ```

1. Delete the local copies of the certificate and key:

   ```sh
   rm tls.key tls.crt
   ```
