---
title: "HashiCorp Vault CA"
description: "Configure {{site.mesh_product_name}} to use HashiCorp Vault as a Certificate Authority for mTLS, including setup steps and authentication options."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
  - /mesh/enterprise/

tags:
  - mtls
  - vault
  - certificates
  - hashicorp

search_aliases:
  - HashiCorp Vault

works_on:
  - on-prem

related_resources:
  - text: "{{site.mesh_product_name}} enterprise features"
    url: /mesh/enterprise/
  - text: "Kubernetes cert-manager CA policy"
    url: /mesh/cert-manager/
  - text: "ACM Private CA Policy"
    url: /mesh/acm-private-ca-policy/
  - text: Certificate Authority rotation
    url: /mesh/ca-rotation/
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
---

You can configure {{site.mesh_product_name}} to communicate with a Vault. 

## Vault CA Backend

The default [mTLS policy in {{site.mesh_product_name}}](/mesh/policies/meshtls/)
supports the following backends:

* `builtin`: {{site.mesh_product_name}} automatically generates the Certificate
Authority (CA) root certificate and key that will be used to generate the data
plane certificates.
* `provided`: the CA root certificate and key can be provided by the user.

{{site.mesh_product_name}} adds:

* `vault`: {{site.mesh_product_name}} generates Data Plane certificates
using a CA root certificate and key stored in a HashiCorp Vault
server.
* [`acmpca`](/mesh/acm-private-ca-policy/): {{site.mesh_product_name}} generates Data Plane certificates
using Amazon Certificate Manager Private CA.
* [`certmanager`](/mesh/cert-manager/): {{site.mesh_product_name}} generates Data Plane certificates
using Kubernetes [cert-manager](https://cert-manager.io) certificate controller.

## Vault mode

In `vault` mTLS mode, {{site.mesh_product_name}} communicates with the HashiCorp Vault PKI,
which generates the Data Plane proxy certificates automatically.
{{site.mesh_product_name}} does not retrieve private key of the CA to generate Data Plane proxy certificates,
which means that private key of the CA is secured by Vault and not exposed to third parties.

In `vault` mode, you point {{site.mesh_product_name}} to the
Vault server and provide the appropriate credentials. {{site.mesh_product_name}}
uses these parameters to authenticate the Control Plane and generate the
Data Plane certificates.

When {{site.mesh_product_name}} is running in `vault` mode, the backend communicates with Vault and ensures
that Vault's PKI automatically issues Data Plane certificates and rotates them for
each proxy.

If {{site.mesh_product_name}} is configured to authenticate to Vault using a renewable token,
it will handle keeping the token renewed.

## Configure Vault

The `vault` mTLS backend expects a configured PKI and role for generating Data Plane proxy certificates.

The following steps show how to configure Vault for {{site.mesh_product_name}} with a mesh named
`default`. For your environment, replace `default` with the appropriate mesh name.

### Configure the Certificate Authority

{{site.mesh_product_name}} works with a Root CA or an Intermediate CA.

{% navtabs "CA" %}
{% navtab "Root CA" %}

Create a new PKI for the `default` Mesh called `kmesh-pki-default`:

```sh
vault secrets enable -path=kmesh-pki-default pki
```

Generate a new Root Certificate Authority for the `default` Mesh:

```sh
vault secrets tune -max-lease-ttl=87600h kmesh-pki-default
```

```sh
vault write -field=certificate kmesh-pki-default/root/generate/internal \
  common_name="{{site.mesh_product_name}} Default" \
  uri_sans="spiffe://default" \
  ttl=87600h
```

{% endnavtab %}
{% navtab "Intermediate CA" %}

Create a new Root Certificate Authority and save it to a file called `ca.pem`:

```sh
vault secrets enable pki
```

```sh
vault secrets tune -max-lease-ttl=87600h pki
```

```sh
vault write -field=certificate pki/root/generate/internal \
  common_name="Organization CA" \
  ttl=87600h > ca.pem
```

You can also use your current Root CA, retrieve the PEM-encoded certificate, and save it to `ca.pem`.

Create a new PKI for the `default` Mesh:

```sh
vault secrets enable -path=kmesh-pki-default pki
```

Generate the Intermediate CA for the `default` Mesh:

```sh
vault write -format=json kmesh-pki-default/intermediate/generate/internal \
    common_name="{{site.mesh_product_name}} Mesh Default" \
    uri_sans="spiffe://default" \
    | jq -r '.data.csr' > pki_intermediate.csr
```

Sign the Intermediate CA with the Root CA. Make sure to pass the right path for the PKI that has the Root CA.
In this example, the path  value is `pki`:

```sh
vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
  format=pem_bundle \
  ttl="43800h" \
  | jq -r '.data.certificate' > intermediate.cert.pem
```

Set the certificate of signed Intermediate CA to the `default` Mesh PKI. You must include the public certificate of the Root CA
so that Data Plane proxies can verify the certificates:

```sh
cat intermediate.cert.pem > bundle.pem
echo "" >> bundle.pem
cat ca.pem >> bundle.pem
vault write kmesh-pki-default/intermediate/set-signed certificate=@bundle.pem
```

{% endnavtab %}
{% endnavtabs %}

### Create a role for generating Data Plane proxy certificates

Run the following to create a role for generating Data Plane proxy certificates:

```sh
vault write kmesh-pki-default/roles/dataplane-proxies \
  allowed_uri_sans="spiffe://default/*,kuma://*" \
  key_usage="KeyUsageKeyEncipherment,KeyUsageKeyAgreement,KeyUsageDigitalSignature" \
  ext_key_usage="ExtKeyUsageServerAuth,ExtKeyUsageClientAuth" \
  client_flag=true \
  require_cn=false \
  allowed_domains="mesh" \
  allow_subdomains=true \
  basic_constraints_valid_for_non_ca=true \
  max_ttl="720h" \
  ttl="720h"
```

{:.info}
> **Note:** Use the `allowed_domains` and `allow_subdomains` parameters
**only** when `commonName` is set in the mTLS Vault backend.

### Create a policy to use the new role

Run the following to create a policy to use the new role:

```sh
cat > kmesh-default-dataplane-proxies.hcl <<- EOM
path "/kmesh-pki-default/issue/dataplane-proxies"
{
  capabilities = ["create", "update"]
}
EOM
vault policy write kmesh-default-dataplane-proxies kmesh-default-dataplane-proxies.hcl
```

### Configure authentication method

To authorize {{site.mesh_product_name}} to access Vault using a token, generate the following orphan token and pass it to the mesh:

```sh
vault token create -type=service -orphan -format=json -policy="kmesh-default-dataplane-proxies" | jq -r ".auth.client_token"
```

We suggest using an [orphan token to avoid surprising behavior around expiration in token hierarchies](https://developer.hashicorp.com/vault/docs/concepts/tokens#token-hierarchies-and-orphan-tokens).
You need root/sudo permissions to execute the previous command.
The output should print a Vault token that you then provide as the `conf.fromCp.auth.token` value of the `Mesh` object.

{:.info}
> **Note:** There are some failure modes where the `vault` CLI still returns a token
even though an error was encountered and the token is invalid. For example, if the
policy creation fails in the previous step, then the `vault token create` command
both returns a token and exposes an error. In such situations, using `jq` to parse
the output hides the error message provided in the `vault` CLI output. Manually
parse the output instead of using `jq` so that the full output of the `vault` CLI
command is available.

{{site.mesh_product_name}} also supports AWS Instance Role authentication to Vault. Vault must be configured to accept EC2 or IAM role authentication. See [Vault documentation](https://developer.hashicorp.com/vault/docs/auth/aws) for details.  With Vault configured, select AWS authentication in the `Mesh` object by setting `conf.fromCp.auth.aws`. {{site.mesh_product_name}} will authenticate using the instance or IRSA role available within the environment.

### Configure Mesh

`kuma-cp` communicates directly with Vault. To connect to
Vault, you must provide credentials in the configuration of the `mesh` object of `kuma-cp`.

You can authenticate with the `token`, with client certificates by providing `clientKey` and `clientCert`, or by AWS role-based authentication.

You can provide these values inline for testing purposes only, as a path to a file on the
same host as `kuma-cp`, or contained in a `secret`. When using a `secret`, it should be a
[mesh-scoped secret][secrets].
On Kubernetes, this mesh-scoped secret should be stored
in the system namespace (`kong-mesh-system` by default) and should be configured as `type: system.kuma.io/secret`.

Here's an example of a configuration with a `vault`-backed CA:

{% navtabs "backend-ca" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: vault-1
    backends:
      - name: vault-1
        type: vault
        dpCert:
          rotation:
            expiration: 1d # must be lower than max_ttl in Vault role
        conf:
          fromCp:
            address: https://vault.8200
            agentAddress: "" # optional
            namespace: "" # optional
            pki: kmesh-pki-default # name of the configured PKI
            role: dataplane-proxies # name of the role that will be used to generate Data Plane proxy certificates
            commonName: {% raw %}'{{ tag "kuma.io/service" }}.mesh'{% endraw %} # optional. If set, then commonName is added to the certificate. You can use "tag" directive to pick a tag which will be base for commonName.

            tls: # options for connecting to Vault via TLS
              skipVerify: false   # if set to true, caCert is optional, should only be used in development
              caCert:             # caCert is used to verify the TLS certificate presented by Vault
                secret: sec-1     # one of secret, inline, or inlineString
              serverName: ""      # optional. The SNI to use when connecting to Vault

            auth: # how to authenticate Kong Mesh when connecting to Vault
              token:
                secret: token-1  # one of secret, inline, or inlineString
              tls:
                clientKey:
                  secret: sec-2  # can be file, secret or inline
                clientCert:
                  file: /tmp/cert.pem # can be file, secret or inlineString
              aws: # AWS role-based authentication. May be empty to use defaults.
                type: "IAM" or "EC2" # Optional AWS authentication type. Default is IAM.
                role: role-name # Optional role name to use for IAM authentication
                iamServerIdHeader: example.com # Optional server ID header value
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: vault-1
  backends:
  - name: vault-1
    type: vault
    dpCert:
      rotation:
        expiration: 24h # must be lower than max_ttl in Vault role
    conf:
      fromCp:
        address: https://vault.8200
        agentAddress: "" # optional
        namespace: "" # optional
        pki: kmesh-pki-default # name of the configured PKI
        role: dataplane-proxies # name of the role that will be used to generate Data Plane proxy certificates
        commonName: {% raw %}'{{ tag "kuma.io/service" }}.mesh'{% endraw %} # optional. If set, then commonName is added to the certificate. You can use "tag" directive to pick a tag which will be base for commonName.
        tls:
          caCert:
            secret: sec-1
          skipVerify: false # if set to true, caCert is optional. Set to true only for development
          serverName: "" # verify sever name
        auth: # how to authenticate Kong Mesh when connecting to Vault
          token:
            secret: token-1  # can be file, secret or inlineString
          tls:
            clientKey:
              secret: sec-2  # can be file, secret or inlineString
            clientCert:
              file: /tmp/cert.pem # can be file, secret or inline
            aws: # AWS role-based authentication. May be empty to use defaults.
              type: "IAM" or "EC2" # Optional AWS authentication type. Default is IAM.
              role: role-name # Optional role name to use for IAM authentication
              iamServerIdHeader: example.com # Optional server ID header value
```

{% endnavtab %}
{% endnavtabs %}

Apply the configuration with `kumactl apply -f [..]`.

If you're running in Universal mode, you can also use the [HTTP API][http-api] to apply configuration.

## Common name

{{site.mesh_product_name}} uses Service Alternative Name with `spiffe://` format to verify secure connection between Services. In this case, the common name in the certificate is not used.
You may need to set a common name in the certificate, for compliance reasons. To do this, set the `commonName` field in the Vault mTLS backend configuration.
The value contains the template that will be used to generate the name.

For example, assuming that the template is `{% raw %}'{{ tag "kuma.io/service" }}.mesh'{% endraw %}`, a Data Plane proxy with `kuma.io/service: backend` tag will receive a certificate with the `backend.mesh` common name.

You can also use the `replace` function to replace `_` with `-`. For example, `{% raw %}'{{ tag "kuma.io/service" | replace "_" "-" }}.mesh'{% endraw %}` changes the common name of `kuma.io/service: my_backend` from `my_backend.mesh` to `my-backend.mesh`.

## Multi-zone and Vault

In a multi-zone environment, the global Control Plane provides the `Mesh` to the zone Control Planes. However, you must make sure that each zone Control Plane communicates with Vault over the same address. This is because certificates for Data Plane proxies are issued from the zone Control Plane, not from the global Control Plane.