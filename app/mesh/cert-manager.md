---
title: "Kubernetes cert-manager CA policy"
description: "Use Kubernetes cert-manager as an mTLS backend for issuing Data Plane certificates in {{site.mesh_product_name}}"
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - cert-manager
  - mtls
  - certificates

search_aliases:
  - Kubernetes cert-manager

works_on:
  - on-prem
  - konnect

related_resources:
  - text: "mTLS Policy"
    url: /mesh/overview/
  - text: "HashiCorp Vault CA"
    url: /mesh/vault/
  - text: "ACM Private CA Policy"
    url: /mesh/acm-private-ca-policy/
  - text: Certificate Authority rotation
    url: /mesh/ca-rotation/
  - text: "{{site.mesh_product_name}} enterprise features"
    url: /mesh/enterprise/
---

You can use Kubernetes cert-manager as an mTLS backend for issuing Data Plane certificates in {{site.mesh_product_name}}.

## Supported mTLS backends

The default mTLS policy in {{site.mesh_product_name}} supports the following Certificate Authority (CA) backends:

* `builtin`: {{site.mesh_product_name}} automatically generates the CA root certificate and key used to generate Data Plane certificates.
* `provided`: The CA root certificate and key can be provided by the user.
* `vault`: Uses a CA root certificate and key stored in a HashiCorp Vault server.
* `acmpca`: Uses [Amazon Certificate Manager Private CA](/mesh/acm-private-ca-policy/) to generate Data Plane certificates.
* `certmanager`: Uses the Kubernetes [cert-manager](https://cert-manager.io) certificate controller.

## How Kubernetes cert-manager works

In `certmanager` mTLS mode, {{site.mesh_product_name}} communicates with a locally installed cert-manager `Issuer` or `ClusterIssuer`, which issues and rotates Data Plane certificates. The CA private key is never exposed to {{site.mesh_product_name}}.

You configure {{site.mesh_product_name}} to reference the `Issuer` using standard Kubernetes resources.
The backend communicates with cert-manager within the Kubernetes cluster.

## Kubernetes cert-manager configuration

To configure cert-manager in {{site.mesh_product_name}}:

* Install cert-manager and configure an `Issuer` or `ClusterIssuer`.
* Ensure the issuer is accessible to the {{site.mesh_product_name}} system namespace (`kong-mesh-system` by default).
* Apply a `Mesh` resource with an mTLS backend referencing the issuer.


Here's an example of mTLS configuration with `certmanager` backend which references an `Issuer` named `my-ca-issuer`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: certmanager-1
    backends:
    - name: certmanager-1
      type: certmanager
      dpCert:
        rotation:
          expiration: 24h
      conf:
        issuerRef:
          name: my-ca-issuer
          kind: Issuer
          group: cert-manager.io
        caCert: # can be used to specify the root CA
          inlineString: | # or secret
            -----BEGIN CERTIFICATE-----
            ...
```
In `issuerRef`, only `name` is strictly required.
`group` and `kind` will default to cert-manager default values. 
See `issuerRef` in the [cert-manager API](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateRequestSpec) for more information.

If `caCert` is not provided, {{site.mesh_product_name}} assumes that the issuer sets `status.CA` on `CertificateRequests`.

If `secret` is used, it must be a {{site.mesh_product_name}} Secret.


Apply the configuration with `kubectl apply -f [..]`.
