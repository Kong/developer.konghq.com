---
title: 'Configuring Mutual TLS'
description: 'Reference for configuring mutual TLS in {{site.mesh_product_name}}, including CA backends and certificate rotation.'
products:
  - mesh
permalink: /mesh/policies/mutual-tls/
breadcrumbs:
  - /mesh/
content_type: reference
layout: reference
tags:
  - mtls
  - security
  - tls
  - certificates
min_version:
  mesh: '2.9'
---

{:.info}
> If you want to configure version, ciphers or per-service permissive/strict mode, see [`MeshTLS`](/mesh/policies/meshtls).

The Mutual TLS policy enables automatic encrypted mTLS traffic for all the services in a mesh, and allows you to assign an identity to every [data plane proxy](/mesh/data-plane-proxy/). {{site.mesh_product_name}} supports different types of CA backends as well as automatic certificate rotation.

{{site.mesh_product_name}} ships with the following CA (Certificate Authority) supported backends:

* [`builtin`](#using-a-builtin-ca): {{site.mesh_product_name}} automatically generates a CA root certificate and key, which are stored as a [Secret](/mesh/manage-secrets/).
* [`provided`](#using-a-provided-ca): The user provides the CA root certificate and key as a Secret.

Once you've specified a CA backend, {{site.mesh_product_name}} automatically generates a certificate for every data plane proxy in the mesh. The certificates that {{site.mesh_product_name}} generates are SPIFFE compatible and are used for AuthN/Z use cases in order to identify every workload in the system.


The certificates that {{site.mesh_product_name}} generates have a SAN set to `spiffe://<mesh name>/<service name>`. When {{site.mesh_product_name}} enforces policies that require an identity, like [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission), it will extract the SAN from the client certificate and use it to match the service identity.

{:.warning}
> By default mTLS **is not** enabled and needs to be explicitly enabled as described below. When mTLS is enabled all traffic is denied **unless** a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission) policy is configured to explicitly allow traffic across proxies.
> 
> Always make sure that a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission) resource is present before enabling mTLS in a mesh in order to avoid unexpected traffic interruptions caused by a lack of authorization between proxies.

To enable mTLS, configure the `mtls` property in a `Mesh` resource. You can have as many `backends` as you want, but only one at a time can be enabled via the `enabledBackend` property.

If `enabledBackend` is missing or empty, then mTLS will be disabled for the entire mesh.

## Using a builtin CA

A `builtin` CA is the fastest and simplest way to enable mTLS in {{site.mesh_product_name}}.

With a `builtin` CA backend type, {{site.mesh_product_name}} dynamically generates its own CA root certificate and key that it uses to automatically provision and rotate certificates for every replica of every service.

You can specify more than one `builtin` backend with different names, and each one is automatically provisioned with a unique certificate and key pair.

To enable a `builtin` mTLS for the entire mesh, apply the following configuration:

{:.warning}
> To prevent disruption of your traffic, we highly recommend adding a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission#allow-all) policy before enabling mTLS. This policy will allow communication between your applications.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
        dpCert:
          rotation:
            expiration: 1d
        conf:
          caCert:
            RSAbits: 2048
            expiration: 10y
```

Apply the configuration with `kubectl apply -f [..]`.
{% endnavtab %}

{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      dpCert:
        rotation:
          expiration: 1d
      conf:
        caCert:
          RSAbits: 2048
          expiration: 10y
```

Apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/mesh/interact-with-control-plane/).
{% endnavtab %}
{% endnavtabs %}

{:.info}
> * The `dpCert` configuration determines how often {{site.mesh_product_name}} should automatically rotate the certificates assigned to every data plane proxy.
> * The `caCert` configuration determines a few properties that {{site.mesh_product_name}} will use when auto-generating the CA root certificate.

### Storing Secrets

When using a `builtin` backend {{site.mesh_product_name}} automatically generates a root CA certificate and key that are stored as a {{site.mesh_product_name}} [Secret resource](/mesh/manage-secrets/) with the following name:

* `<mesh name>.ca-builtin-cert-<backend name>` for the certificate
* `<mesh name>.ca-builtin-key-<backend name>` for the key

On Kubernetes, {{site.mesh_product_name}} Secrets are stored in the `{{site.mesh_namespace}}` namespace, while on Universal they are stored in the underlying [store](/mesh/configuration#store) configured in `kuma-cp`.

Retrieve the secrets via `kumactl` on both Universal and Kubernetes, or via `kubectl` on Kubernetes only:

{% navtabs "tool" %}
{% navtab "kumactl" %}

The following command can be executed on any {{site.mesh_product_name}} backend:

```sh
kumactl get secrets [-m MESH]
# MESH      NAME                           AGE
# default   default.ca-builtin-cert-ca-1   1m
# default   default.ca-builtin-key-ca-1    1m
```

{% endnavtab %}
{% navtab "kubectl" %}

The following command can be executed only on Kubernetes:

```sh
kubectl get secrets \
    -n {{site.mesh_namespace}} \
    --field-selector='type=system.kuma.io/secret'
# NAME                             TYPE                                  DATA   AGE
# default.ca-builtin-cert-ca-1     system.kuma.io/secret                 1      1m
# default.ca-builtin-key-ca-1      system.kuma.io/secret                 1      1m
```

{% endnavtab %}
{% endnavtabs %}

## Using a provided CA

If you choose to provide your own CA root certificate and key, you can use the `provided` backend. With this option, you must also manage the certificate lifecycle yourself.

Unlike the `builtin` backend, with `provided` you first upload the certificate and key as [Secret resource](/mesh/manage-secrets/), and then reference the Secrets in the mTLS configuration.

{{site.mesh_product_name}} then provisions data plane proxy certificates for every replica of every service from the CA root certificate and key.

### Sample configuration

Here's an example of how to configure a `provided` CA:

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: provided
        dpCert:
          rotation:
            expiration: 1d
        conf:
          cert:
            secret: $SECRET_NAME
          key:
            secret: $SECRET_NAME
```

Apply the configuration with `kubectl apply -f [..]`.
{% endnavtab %}

{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: provided
      dpCert:
        rotation:
          expiration: 1d
      conf:
        cert:
          secret: $SECRET_NAME
        key:
          secret: $SECRET_NAME
```

Apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/mesh/interact-with-control-plane/).
{% endnavtab %}
{% endnavtabs %}


{:.info}
> * The `dpCert` configuration determines how often {{site.mesh_product_name}} should automatically rotate the certificates assigned to every data plane proxy.
> * The Secrets must exist before referencing them in a `provided` backend.

### Intermediate CA

You can also use an intermediate CA with a `provided` backend. Generate the certificate and place it first in certificate file, before the certificate from the root CA. The certificate from the root CA should start on a new line:

```text
-----BEGIN CERTIFICATE-----
<intermediate CA certificate content>
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
<root CA certificate content>
-----END CERTIFICATE-----
```
Then create the Secret to use in the `cert` section of the config. The secret for the `key` should contain only the private key for the certificate from the intermediate CA.

You can chain certificates from multiple intermediate CAs the same way. Place the certificate from the closest CA at the top of the cert file, followed by certificates in order up the certificate chain, then generate the Secret to hold the contents of the file.

### CA requirements

When using an arbitrary certificate and key for a `provided` backend, ensure compliance with the following requirements:

* It **must** have the basic constraint `CA` set to `true` (see [X509-SVID: 4.1. Basic Constraints](https://github.com/spiffe/spiffe/blob/main/standards/X509-SVID.md#41-basic-constraints))
* It **must** have the key usage extension `keyCertSign` set (see [X509-SVID: 4.3. Key Usage](https://github.com/spiffe/spiffe/blob/main/standards/X509-SVID.md#43-key-usage))
* It **must not** have the key usage extension `keyAgreement` set (see [X509-SVID: Appendix A. X.509 Field Reference](https://github.com/spiffe/spiffe/blob/main/standards/X509-SVID.md#appendix-a-x509-field-reference))
* It **should not** set the key usage extension `digitalSignature` and `keyEncipherment` to be SPIFFE compliant (see [X509-SVID: Appendix A. X.509 Field Reference](https://github.com/spiffe/spiffe/blob/main/standards/X509-SVID.md#appendix-a-x509-field-reference))

The following example generates a sample CA certificate and key:

{:.warning}
> Do not use this example in production, instead generate valid and compliant certificates. This example is intended for usage in a development environment.

The following command will generate a CA root certificate and key that can be uploaded to {{site.mesh_product_name}} as a Secret and then used in a `provided` mTLS backend:

```sh
SAMPLE_CA_CONFIG="
[req]
distinguished_name=dn
[ dn ]
[ ext ]
basicConstraints=CA:TRUE,pathlen:0
keyUsage=keyCertSign
"

openssl req -config <(echo "$SAMPLE_CA_CONFIG") -new -newkey rsa:2048 -nodes \
  -subj "/CN=Hello" -x509 -extensions ext -keyout key.pem -out crt.pem
```

The command generates a certificate at `crt.pem` and the key at `key.pem`. Generate the {{site.mesh_product_name}} Secret resources using the [Secret resource](/mesh/manage-secrets/).

### Development mode

In development mode, you can provide the `cert` and `key` properties of the `provided` backend using an inline value instead of a Secret resource.

{:.warning}
> Using the `inline` modes in production presents a security risk since it makes the CA root certificate and key more easily accessible to a malicious actor. Only use `inline` in development mode.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

Use the `inline` properties instead of `secret`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: provided
        conf:
          cert:
            inline: <base64-encoded certificate>
          key:
            inline: <base64-encoded key>
```

{% endnavtab %}

{% navtab "Universal" %}

Use the `inline` properties instead of `secret`:

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: provided
      conf:
        cert:
          inline: <base64-encoded certificate>
        key:
          inline: <base64-encoded key>
```

{% endnavtab %}
{% endnavtabs %}

## Permissive mTLS

{{site.mesh_product_name}} provides a `PERMISSIVE` mTLS mode to let you migrate existing workloads with zero downtime.

Permissive mTLS mode encrypts outbound connections the same way as strict mTLS mode, but inbound connections on the server-side accept both TLS and plaintext. 
This lets you migrate servers to an mTLS mesh before their clients. 
It also supports the case where the client and server already implement TLS.

{:.warning}
> `PERMISSIVE` mode is not secure. It's intended as a temporary utility. Make sure to set to `STRICT` mode after migration is complete.

{% navtabs "environment" %}

{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
        mode: PERMISSIVE
```

{% endnavtab %}

{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      mode: PERMISSIVE
```

{% endnavtab %}

{% endnavtabs %}

## Certificate rotation

Once a CA backend has been configured, {{site.mesh_product_name}} uses the CA root certificate and key to automatically provision a certificate for every data plane proxy that it connects to `kuma-cp`.

Unlike the CA certificate, data plane proxy certificates are not permanently stored, they reside only in memory. These certificates are designed to be short-lived and rotated often by {{site.mesh_product_name}}.

By default, the expiration time of a data plane proxy certificate is 30 days. {{site.mesh_product_name}} rotates these certificates automatically after 4/5th of the certificate validity time. For example: for the default 30-day expiration, {{site.mesh_product_name}} rotates the certificates every 24 days.

You can update the duration of the data plane proxy certificates by updating the `dpCert` property on every available mTLS backend.

You can inspect the certificate rotation statistics by executing the following command:

{% navtabs "method" %}
{% navtab "kumactl" %}

Use the {{site.mesh_product_name}} CLI:

```sh
kumactl inspect dataplanes
# MESH      NAME     TAGS          STATUS   LAST CONNECTED AGO   LAST UPDATED AGO   TOTAL UPDATES   TOTAL ERRORS   CERT REGENERATED AGO   CERT EXPIRATION       CERT REGENERATIONS
# default   web-01   service=web   Online   5s                   3s                 4               0              3s                     2020-05-11 16:01:34   2
```

See the `CERT REGENERATED AGO`, `CERT EXPIRATION`, `CERT REGENERATIONS` columns.

{% endnavtab %}
{% navtab "HTTP API" %}

Use the `/meshes/{mesh}/dataplanes+insights/{dataplane}` endpoint of the [{{site.mesh_product_name}} HTTP API](/mesh/interact-with-control-plane/) and inspect the `dataplaneInsight` object.

```json
...
dataplaneInsight": {
  ...
  "mTLS": {
    "certificateExpirationTime": "2020-05-14T20:15:23Z",
    "lastCertificateRegeneration": "2020-05-13T20:15:23.994549539Z",
    "certificateRegenerations": 1
  }
}
...
```

{% endnavtab %}
{% endnavtabs %}

A new data plane proxy certificate is automatically generated when:

* A data plane proxy is restarted.
* The control plane is restarted.
* The data plane proxy connects to a new control plane.
