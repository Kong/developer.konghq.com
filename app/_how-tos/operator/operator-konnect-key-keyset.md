---
title: Create a Key and Key Set
description: "Provision Keys and Key Sets in {{site.konnect_short_name}} using CRDs, and associate Keys with Key Sets."
content_type: how_to

permalink: /operator/konnect/crd/gateway/key-keyset/
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
  - kgo key
  - kgo keyset
tags:
  - konnect-crd
related_resources:
  - text: Key Sets
    url: /key-sets/
  - text: Keys
    url: /keys/
tldr:
  q: How can I manage Keys and Key Sets for {{site.konnect_short_name}} using Kubernetes?
  a: Create `KongKey` and `KongKeySet` resources and associate them using the `keySetRef` field.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true

---

## Create a `KongKey`

Use the `KongKey` resource to define a Key in {{site.konnect_short_name}}. You can create PEM or JWK keys.

<!-- vale off -->
{% konnect_crd %}
kind: KongKey
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: key
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
  kid: key-id
  name: key
  pem:
    private_key: |
      -----BEGIN PRIVATE KEY-----
      MIIBVQIBADANBgkqhkiG9w0BAQEFAASCAT8wggE7AgEAAkEA4f5Ur6EzZKsfu0ct
      QCmmbCkUohHp6lAgGGmVmQpj5Xrx5jrjGWWdDAF1ADFPh/XMC58iZFaX33UpGOUn
      tuWbJQIDAQABAkEAxqXvvL2+1iNRbiY/kWHLBtIJb/i9G5i4zZypwe+PJduIPRlH
      4bFHih8sHtYt5rEs4RnT0SJnZN1HKhJcisVLdQIhAPKboGS0dTprmMLrAXQh15p7
      xz4XUbZrNqPct+hqa5JXAiEA7nfrjPYm2UXKRzvFo9Zbd9K/Y3M0Xas9LsXdRaO8
      6OMCIAhkX8D8CQ4TSL59WJiGzyl13KeGMPppbQNwECCHBd+TAiB8dDOHprORsz2l
      PYmhPu8PsvpVkbtjo0nUDkmz3Ydq1wIhAIMCsZQ7A3H/kN88aYsqKeGg9c++yqIP
      /9xIOKHsjlB4
      -----END PRIVATE KEY-----
    public_key: |
      -----BEGIN PUBLIC KEY-----
      MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAOH+VK+hM2SrH7tHLUAppmwpFKIR6epQ
      IBhplZkKY+V68eY64xllnQwBdQAxT4f1zAufImRWl991KRjlJ7blmyUCAwEAAQ==
      -----END PUBLIC KEY-----
{% endkonnect_crd %}
<!-- vale on -->

## Create a `KongKeySet`

Provision a Key Set to logically group related keys.

<!-- vale off -->
{% konnect_crd %}
kind: KongKeySet
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: key-set
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
  name: key-set
{% endkonnect_crd %}
<!-- vale on -->


## Associate a Key with a Key Set

Update the `KongKey` with a reference to the `KongKeySet`.

<!-- vale off -->
{% konnect_crd %}
kind: KongKey
apiVersion: configuration.konghq.com/v1alpha1
metadata:
  name: key
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
  kid: key-id
  name: key
  pem:
    private_key: |
      -----BEGIN PRIVATE KEY-----
      MIIBVQIBADANBgkqhkiG9w0BAQEFAASCAT8wggE7AgEAAkEA4f5Ur6EzZKsfu0ct
      QCmmbCkUohHp6lAgGGmVmQpj5Xrx5jrjGWWdDAF1ADFPh/XMC58iZFaX33UpGOUn
      tuWbJQIDAQABAkEAxqXvvL2+1iNRbiY/kWHLBtIJb/i9G5i4zZypwe+PJduIPRlH
      4bFHih8sHtYt5rEs4RnT0SJnZN1HKhJcisVLdQIhAPKboGS0dTprmMLrAXQh15p7
      xz4XUbZrNqPct+hqa5JXAiEA7nfrjPYm2UXKRzvFo9Zbd9K/Y3M0Xas9LsXdRaO8
      6OMCIAhkX8D8CQ4TSL59WJiGzyl13KeGMPppbQNwECCHBd+TAiB8dDOHprORsz2l
      PYmhPu8PsvpVkbtjo0nUDkmz3Ydq1wIhAIMCsZQ7A3H/kN88aYsqKeGg9c++yqIP
      /9xIOKHsjlB4
      -----END PRIVATE KEY-----
    public_key: |
      -----BEGIN PUBLIC KEY-----
      MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAOH+VK+hM2SrH7tHLUAppmwpFKIR6epQ
      IBhplZkKY+V68eY64xllnQwBdQAxT4f1zAufImRWl991KRjlJ7blmyUCAwEAAQ==
      -----END PUBLIC KEY-----
  keySetRef:
    type: namespacedRef
    namespacedRef:
      name: key-set
{% endkonnect_crd %}
<!-- vale on -->

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KongKey
name: key
{% endvalidation %}

{% validation kubernetes-resource %}
kind: KongKeySet
name: key-set
{% endvalidation %}
<!-- vale on -->