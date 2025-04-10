---
title: "ACM Private CA Policy"
description: "Track all user and system actions in {{site.mesh_product_name}} using the AccessAudit resource and configurable backends"
content_type: reference
layout: reference
products:
    - mesh

tags:
  - mesh-policy
  - certificates

related_resources:
  - text: "Mesh"
    url: /mesh/overview/
---

## Supported mTLS backends

The default mTLS policy in {{site.mesh_product_name}} supports the following Certificate Authority (CA) backends:

* `builtin`: {{site.mesh_product_name}} automatically generates the CA root certificate and key used to generate Data Plane certificates.
* `provided`: The CA root certificate and key can be provided by the user.
* `vault`: Uses a CA root certificate and key stored in a HashiCorp Vault server.
* `acmpca`: Uses [Amazon Certificate Manager Private CA](https://docs.aws.amazon.com/privateca/latest/userguide/PcaWelcome.html) to generate Data Plane certificates.
* `certmanager`: Uses the Kubernetes [cert-manager](https://cert-manager.io) certificate controller.

## How ACM Private CA works

In `acmpca` mTLS mode, {{site.mesh_product_name}} uses Amazon Certificate Manager to automatically generate Data Plane certificates. The private key of the CA is secured by AWS and never exposed.

You configure {{site.mesh_product_name}} to use the ACM resource and optionally specify AWS authentication credentials. 
The system uses the AWS default credential chain (environment variables, config files, roles).

Certificates are issued and rotated by the Zone Control Plane for each Data Plane proxy.

## Configuration

To configure ACM Private CA in {{site.mesh_product_name}}:

* Create an ACM Private CA in AWS. You can use a Root or Intermediate CA.
* Record the ARN and Root Certificate Chain of the CA.
* Apply a `Mesh` resource with an `acmpca` mTLS backend using either Kubernetes or Universal mode.

The `acmpca` backend can authenticate via:

* The default AWS credential chain (preferred)
* Inline credentials (for testing only)
* Mesh-scoped `secret` resources

For example:

{% navtabs "mesh config"%}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: acmpca-1
    backends:
      - name: acmpca-1
        type: acmpca
        dpCert:
          rotation:
            expiration: 1d
        conf:
          arn: "arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012" # AWS ARN of the Private CA
          commonName: {% raw %}'{{ tag "kuma.io/service" }}.mesh'{% endraw %} # optional. If set, then commonName is added to the certificate. You can use "tag" directive to pick a tag which will be base for commonName. If unset, a Subject Alternative Name may be duplicated as Common Name.
          caCert:             # caCert is used to verify the TLS certificate presented by ACM.
            secret: sec-1     # one of file, secret or inline.
          auth: # Optional AWS authentication keys. If unset, default credential chain locations are searched.
            awsCredentials:
              accessKey:
                secret: sec-2  # one of file, secret or inline.
              accessKeySecret:
                file: /tmp/accesss_key.txt # one of file, secret or inline.
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Mesh
name: default
mtls:
  enabledBackend: acmpca-1
  backends:
  - name: acmpca-1
    type: acmpca
    dpCert:
      rotation:
        expiration: 24h
    conf:
      arn: "arn:aws:acm-pca:region:account:certificate-authority/12345678-1234-1234-1234-123456789012" # AWS ARN of the Private CA
      commonName: {% raw %}'{{ tag "kuma.io/service" }}.mesh'{% endraw %} # optional. If set, then commonName is added to the certificate. You can use "tag" directive to pick a tag which will be base for commonName. If unset, a Subject Alternative Name may be duplicated as Common Name.
      caCert:              # caCert is used to verify the TLS certificate presented by ACM.
        secret: sec-1      # one of file, secret or inline.
      auth:  # Optional AWS authentication keys. If unset, default credential chain locations are searched.
        awsCredentials:
          accessKey:
            secret: sec-2  # one of file, secret or inline.
          accessKeySecret:
            file: /tmp/accesss_key.txt # one of file, secret or inline.
```

{% endnavtab %}
{% endnavtabs %}

These configurations can be applied with `kumactl apply -f [..]`.

## Multi-zone and ACM Private CA

In a multi-zone environment, the global Control Plane provides the `Mesh` to the zone Control Planes. 
However, you must make sure that each zone Control Plane can communicate with ACM Private CA. 
This is because certificates for Data Plane proxies are requested from ACM Private CA by the zone Control Plane, not the global Control Plane.