---
title: Store TLS certificate private keys in a {{site.konnect_short_name}} Config Store
description: "Keep TLS private keys out of Kubernetes and out of your certificate objects by referencing them from a KonnectConfigStore-backed KongVault."
content_type: how_to

permalink: /operator/konnect/how-to/config-store-certificate-keys/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

search_aliases:
  - kgo config store
  - kgo vault certificate key
  - KonnectConfigStore

tags:
  - konnect-crd
  - secrets-management
  - certificates

related_resources:
  - text: Create a Vault
    url: /operator/konnect/crd/gateway/vault/
  - text: Create a Certificate and CA Certificate
    url: /operator/konnect/crd/gateway/certificate-ca-cert/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/
  - text: Configure the {{site.konnect_short_name}} Config Store vault
    url: /how-to/configure-the-konnect-config-store/

tldr:
  q: How do I keep a TLS private key out of my Kubernetes manifests and out of my certificate objects?
  a: |
    Create a `KonnectConfigStore`, point to a `KongVault` with `backend: konnect` at it using `spec.configStoreRef`,
    write the private key directly into the Config Store, and then set `KongCertificate.spec.key` to a
    `{vault://PREFIX/KEY}` reference instead of the key material.

min_version:
  operator: '2.3'

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

A `KongCertificate` normally carries the private key as PEM material in `spec.key`, which means the key is stored in
your Kubernetes manifests, in etcd, and in the {{site.konnect_short_name}} certificate object. Anyone who can read the
`KongCertificate` or the {{site.konnect_short_name}} certificate can read the key.

Instead, you can store the key in a [{{site.konnect_short_name}} Config Store](/how-to/configure-the-konnect-config-store/)
and reference it from `spec.key` with a Kong vault reference. The reference is passed through unchanged, so the key
material never enters your cluster and never appears in the certificate object.

## How the pieces fit together

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

The secret value itself is the one step that isn't declarative: it's written straight to {{site.konnect_short_name}},
out-of-band. That's deliberate. If the key were passed through a Kubernetes resource, it would be stored in etcd, which
is exactly what this setup avoids.

## Create a `KonnectConfigStore`

Use the `KonnectConfigStore` resource to create the Config Store container in {{site.konnect_short_name}}. It must
reference the `KonnectGatewayControlPlane` that owns the Config Store:

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
<!-- vale on -->

## Allow the `KongVault` to reference the Config Store

`KongVault` is cluster-scoped and `KonnectConfigStore` is namespaced, so the reference always crosses a namespace
boundary and the namespace that holds the Config Store must allow it with a `KongReferenceGrant`. Because a
`KongVault` has no namespace of its own, the grant must list `namespace: ""` in its `from` entry.

The same grant also covers the `KongVault` reference to the `KonnectGatewayControlPlane`, which crosses a namespace
boundary for the same reason:

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

Create a `KongVault` with `backend: konnect` and point `spec.configStoreRef` at the `KonnectConfigStore`. {{site.operator_product_name}}
resolves the reference into the `config_store_id` of the Vault configuration, so you never have to copy the
{{site.konnect_short_name}} Config Store ID by hand:

<!-- vale off -->
{% konnect_crd %}
kind: KongVault
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: certvault
spec:
  backend: konnect
  prefix: certvault
  description: TLS certificate private keys
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
<!-- vale on -->

`spec.prefix` is what you use in vault references later, and it's immutable after creation.

{:.info}
> **Note:** `spec.configStoreRef` is only supported with `backend: konnect`, and it's mutually exclusive with setting
> `config_store_id` under `spec.config`. Set one or the other, not both.

## Write the private key into the Config Store

Generate a self-signed certificate and key to work with:

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=example.localdomain.dev"
```

Fetch the {{site.konnect_short_name}} IDs of the control plane and of the Config Store that {{site.operator_product_name}}
created. The Config Store ID is published on the `KonnectConfigStore` status, so you don't have to look it up in the
{{site.konnect_short_name}} UI:

```sh
export CONTROL_PLANE_ID=$(kubectl get -n kong konnectgatewaycontrolplanes.konnect.konghq.com gateway-control-plane -o jsonpath='{.status.id}')
export CONFIG_STORE_ID=$(kubectl get -n kong konnectconfigstores.konnect.konghq.com cert-keys -o jsonpath='{.status.id}')
```

Build the request body, using `jq` to embed the PEM file as a JSON string:

```sh
jq -n --arg key example-tls-key --rawfile value tls.key '{key: $key, value: $value}' > secret.json
```

Store the private key as a secret entry in the Config Store:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets
status_code: 201
method: POST
body_cmd: $(cat secret.json)
{% endkonnect_api_request %}
<!--vale on-->

You can also store the secret from the {{site.konnect_short_name}} UI:

1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the sidebar.
1. Click your control plane.
1. Navigate to **Vaults** in the sidebar, then click the `certvault` Vault.
1. Click **Store New Secret**.
1. Enter `example-tls-key` in the **Key** field and paste the contents of `tls.key` in the **Value** field.
1. Click **Save**.

Delete the local copies of the key once it's stored:

```sh
rm tls.key secret.json
```

## Create a `KongCertificate` that references the key

Set `spec.key` to a vault reference of the form `{vault://PREFIX/KEY}`, where `PREFIX` is the `spec.prefix` of the
`KongVault` and `KEY` is the Config Store entry you created. The public certificate isn't sensitive, so it stays
inline:

```sh
echo "
kind: KongCertificate
apiVersion: configuration.konghq.com/{{ site.operator_kongcertificate_api_version }}
metadata:
  name: cert-with-vault-key
  namespace: kong
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
  cert: |
$(sed 's/^/    /' tls.crt)
  key: '{vault://certvault/example-tls-key}'" | kubectl apply -f -
```

`spec.cert`, `spec.cert_alt`, `spec.key`, and `spec.key_alt` each independently accept either inline material or a
vault reference, so you can reference only the fields that are sensitive. Malformed references are rejected at
admission time, so a typo in a reference fails when you apply the resource rather than at TLS handshake time.

{:.warning}
> **Vault references and `type: secretRef`:** vault references are only supported with the default
> `spec.type: inline`. `spec.type: secretRef` reads the certificate and key from a Kubernetes `Secret`, which stores
> the key in etcd.

## Validate

Check that all three resources are programmed in {{site.konnect_short_name}}:

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectConfigStore
name: cert-keys
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KongVault
name: certvault
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KongCertificate
name: cert-with-vault-key
{% endvalidation %}
<!-- vale on -->

Confirm that the `KongVault` accepted the Config Store reference:

<!-- vale off -->
{% validation kubernetes-resource-property %}
kind: kongvault
name: certvault
path: |
  .status.conditions[] | select(.type == "ConfigStoreRefValid") | .status
expected: "True"
{% endvalidation %}
<!-- vale on -->

Finally, confirm that the certificate stored in {{site.konnect_short_name}} holds the vault reference rather than the
key material:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/certificates
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

The `key` field in the response is `{vault://certvault/example-tls-key}`. The reference is resolved after
{{site.base_gateway}} connects to the control plane, so the certificate object itself never contains the key.

## Security boundary

This setup moves the private key out of every place you manage with GitOps, but it doesn't remove it from
{{site.konnect_short_name}}:

{% table %}
columns:
  - title: Location
    key: location
  - title: Holds the private key?
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
      Yes, while the certificate is in use. {{site.konnect_short_name}} resolves the reference after the data plane
      connects to the control plane.
{% endtable %}

Anyone who can write secrets into the Config Store can replace the key that your listener serves, so treat Config
Store write access as equivalent to certificate issuance rights.

## Lifecycle and deletion

* Deleting the `KonnectConfigStore` deletes the Config Store in {{site.konnect_short_name}} **along with every secret
  stored in it**, including keys that other Vaults or certificates still reference. Delete it only when you're sure
  nothing depends on its contents.
* `spec.configStoreRef` is mutable. Removing it clears the `ConfigStoreRefValid` condition and leaves any
  `config_store_id` you set directly under `spec.config` untouched.
* Removing the `KongReferenceGrant` stops further updates to a programmed `KongVault`, but the Vault that already
  exists in {{site.konnect_short_name}}, including its `config_store_id`, isn't rolled back or removed.
* Rotating a key is a Config Store operation: update the secret value in place, and the vault reference keeps
  resolving without any change to your Kubernetes resources.

## Troubleshooting

The `KongVault` reports the outcome of the reference in the `ConfigStoreRefValid` condition:

```sh
kubectl get kongvault certvault -o jsonpath-as-json="{.status.conditions[?(@.type=='ConfigStoreRefValid')]}"
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
      The `KonnectConfigStore` exists but hasn't been created in {{site.konnect_short_name}} yet, so its ID isn't
      known. This resolves on its own once the Config Store is programmed.
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

If the Vault is programmed but {{site.base_gateway}} fails the TLS handshake, the reference itself is usually fine and
the secret entry is the problem. Confirm that the key exists in the Config Store and that its name matches the vault
reference:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
