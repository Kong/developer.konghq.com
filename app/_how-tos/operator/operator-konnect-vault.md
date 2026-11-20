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
  - text: Config Store-backed Vaults
    url: /operator/konnect/config-store/
tldr:
  q: How do I create and configure a Vault in Konnect using KGO?
  a: Define a `KongVault` resource and associate it with your `KonnectGatewayControlPlane` to manage secrets using a configured backend.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `KonnectGatewayControlPlane` also deletes the control plane the {{site.operator_product_name}} created in {{ site.konnect_short_name }}:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          kongvault/env-vault \
          kongreferencegrant/allow-kongvault-to-konnect-resources \
          konnectgatewaycontrolplane/gateway-control-plane \
          konnectapiauthconfiguration/konnect-api-auth
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

    - title: Delete the namespaces
      content: |
        ```bash
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kong kong-system
        ```
      icon_url: /assets/icons/kubernetes.svg

---

## Create a KongReferenceGrant

A `KongVault` is cluster-scoped, so it has no namespace of its own. Referencing the `KonnectGatewayControlPlane` in the `kong` namespace therefore crosses a namespace boundary, which a `KongReferenceGrant` must allow. Because the source has no namespace, the grant lists an empty namespace in its `from` entry:

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
      kind: KonnectGatewayControlPlane' | kubectl apply -f -
```
{: data-test-step="block" }

## Create a KongVault

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

To store secrets in a {{site.konnect_short_name}} Config Store that {{site.operator_product_name}} manages for you,
see [Store TLS certificate private keys in a {{site.konnect_short_name}} Config Store](/operator/konnect/how-to/config-store-certificate-keys/).

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongVault
name: env-vault
{% endvalidation %}
<!-- vale on -->
