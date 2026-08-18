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
  - text: Config Store-backed Vaults
    url: /operator/konnect/config-store/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/
  - text: Status fields
    url: /operator/konnect/troubleshooting/status/
  - text: Configure the {{site.konnect_short_name}} Config Store vault
    url: /how-to/configure-the-konnect-config-store/

tldr:
  q: How do I keep a TLS private key out of my Kubernetes manifests and out of my certificate objects?
  a: |
    Create a `KonnectConfigStore`, point a `KongVault` to it with `backend: konnect` using `spec.configStoreRef`,
    write the private key directly into the Config Store, and then set `KongCertificate.spec.key` to a
    `{vault://PREFIX/KEY}` reference instead of the key material.

min_version:
  operator: '2.3'

faqs:
  - q: Why isn't the secret value stored declaratively?
    a: |
      The purpose of this guide is to avoid storing the secret in etcd, which would be the case if the key was passed through a Kubernetes resource. Instead, we pass it directly to {{site.konnect_short_name}} using either the API or the UI.
  - q: Who can replace the private key once it's in the Config Store?
    a: |
      Anyone who can write secrets into the Config Store can replace the key that your listener serves, so treat
      Config Store write access as equivalent to certificate issuance rights. For a full breakdown of where the key
      does and doesn't exist, see the [security boundary](/operator/konnect/config-store/#security-boundary) of a
      Config Store-backed Vault.
  - q: What happens if I delete the `KonnectConfigStore`?
    a: |
      Deleting the `KonnectConfigStore` deletes the Config Store in {{site.konnect_short_name}} **along with every
      secret stored in it**, including keys that other Vaults or certificates still reference. Delete it only when
      you're sure nothing depends on its contents. For more information, see
      [lifecycle and deletion](/operator/konnect/config-store/#lifecycle-and-deletion).
  - q: How do I rotate a key that's stored in the Config Store?
    a: |
      Rotating a key is a Config Store operation: update the secret value in place, and the vault reference keeps
      resolving without any change to your Kubernetes resources.
  - q: "Can I use vault references with `spec.type: secretRef`?"
    a: |
      No. Vault references are only supported with the default `spec.type: inline`. `spec.type: secretRef` reads the
      certificate and key from a Kubernetes `Secret`, which stores the key in etcd.
  - q: Why isn't my `KongVault` programmed in {{site.konnect_short_name}}?
    a: |
      If the `KongVault` isn't programmed in {{site.konnect_short_name}}, check the `ConfigStoreRefValid` condition:

      ```sh
      kubectl get kongvault certvault -o jsonpath-as-json="{.status.conditions[?(@.type=='ConfigStoreRefValid')]}"
      ```

      For the meaning of each condition reason, see
      [`ConfigStoreRefValid` on `KongVault`](/operator/konnect/troubleshooting/status/#configstorerefvalid-on-kongvault).
  - q: The Vault is programmed, but {{site.base_gateway}} fails the TLS handshake. What should I check?
    a: |
      If the Vault is programmed but {{site.base_gateway}} fails the TLS handshake, the reference itself is usually
      fine and the secret entry is the problem. Confirm that the key exists in the Config Store and that its name
      matches the vault reference:

      <!--vale off-->
      {% konnect_api_request %}
      url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets
      status_code: 200
      method: GET
      {% endkonnect_api_request %}
      <!--vale on-->

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

For more information, see [Config Store-backed Vaults](/operator/konnect/config-store/).

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

{% validation kubernetes-resource %}
kind: KonnectConfigStore
name: cert-keys
{% endvalidation %}
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

Create a `KongVault` with `backend: konnect` and point `spec.configStoreRef` to the `KonnectConfigStore`. {{site.operator_product_name}}
resolves the reference into the `config_store_id` of the Vault configuration:

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

{% validation kubernetes-resource %}
kind: KongVault
name: certvault
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

For more information about `spec.configStoreRef` and `spec.prefix`, see
[Config Store-backed Vaults](/operator/konnect/config-store/#field-behavior).

## Generate a certificate

Generate a self-signed certificate and key to work with:

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=example.localdomain.dev"
```

## Write the private key into the Config Store

{% navtabs "store-certificate-key" %}
{% navtab "{{site.konnect_short_name}} API" %}
1. Fetch the {{site.konnect_short_name}} IDs of the control plane and of the Config Store that {{site.operator_product_name}}
   created. The Config Store ID is published on the `KonnectConfigStore` status, so you don't have to look it up in the
   {{site.konnect_short_name}} UI:

   ```sh
   export CONTROL_PLANE_ID=$(kubectl get -n kong konnectgatewaycontrolplanes.konnect.konghq.com gateway-control-plane -o jsonpath='{.status.id}')
   echo $CONTROL_PLANE_ID
   export CONFIG_STORE_ID=$(kubectl get -n kong konnectconfigstores.konnect.konghq.com cert-keys -o jsonpath='{.status.id}')
   echo $CONFIG_STORE_ID
   ```

1. Build the request body, using `jq` to embed the PEM file as a JSON string:

   ```sh
   jq -n --arg key example-tls-key --rawfile value tls.key '{key: $key, value: $value}' > secret.json
   ```

1. Store the private key as a secret entry in the Config Store:
{% capture command %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/config-stores/$CONFIG_STORE_ID/secrets
status_code: 201
method: POST
body_cmd: $(cat secret.json)
indent: 3
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{command | indent}}

{% capture delete %}
1. Delete the local copies of the key once it's stored:

   ```sh
   rm tls.key secret.json
   ```
{% endcapture %}
{{delete}}
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the sidebar.
1. Click your control plane.
1. Navigate to **Vaults** in the sidebar, then click the `certvault` Vault.
1. Click **Store new secret**.
1. Enter `example-tls-key` in the **Key** field and paste the contents of `tls.key` in the **Value** field.
1. Click **Save**.

{% endnavtab %}
{% endnavtabs %}

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

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongCertificate
name: cert-with-vault-key
{% endvalidation %}
<!-- vale on -->

For more information about which certificate fields accept vault references, see
[Can I reference certificate material from a Vault?](/operator/konnect/crd/gateway/certificate-ca-cert/#can-i-reference-certificate-material-from-a-vault).

## Validate

Confirm that the certificate stored in {{site.konnect_short_name}} holds the vault reference rather than the
key material:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/certificates
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

The value of the `key` field in the response is `{vault://certvault/example-tls-key}`. The reference is resolved after
{{site.base_gateway}} connects to the control plane, so the certificate object itself never contains the key.
