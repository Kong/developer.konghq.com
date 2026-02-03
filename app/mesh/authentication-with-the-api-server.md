---
title: Authentication with the {{site.mesh_product_name}} API server
description: Authenticate users and automation tools to the control plane API server using user tokens, including token generation, rotation, and revocation.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Manage secrets
    url: /mesh/manage-secrets/
  - text: Mesh ports
    url: /mesh/use-kuma/#control-plane-ports
  - text: Zone Ingress
    url: /mesh/zone-ingress/
---

{{site.mesh_product_name}} exposes API server on [ports](/mesh/interact-with-control-plane/#control-plane-ports) `5681` and `5682` (protected by TLS).

An authenticated user can be authorized to execute administrative actions such as:
* Managing administrative resources like {{site.mesh_product_name}} secrets on Universal.
* Generating user tokens, data plane proxy tokens, zone ingress tokens, and zone tokens.

## User token

A user token is a signed JWT token that contains:
* The name of the user
* The list of groups that a user belongs to
* The expiration date of the token

### Groups

Groups in {{site.mesh_product_name}} allow you to manage API permissions for users. A user can be a part of multiple groups. 
{{site.mesh_product_name}} adds two groups to a user automatically:
* Authenticated users are added to `mesh-system:authenticated`.
* Unauthenticated users are added to `mesh-system:unauthenticated`.

### Admin user token

{{site.mesh_product_name}} creates an admin user token on the first start of the control plane.
The admin user token is a user token issued for users in. the `mesh-system:admin` group.
This group is authorized by default to execute all administrative operations.

#### Configure kumactl with an admin user token

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
1. Use `kubectl` to extract the admin token:

   ```sh
   kubectl get secret admin-user-token -n {{site.mesh_namespace}} {% raw %}--template={{.data.value}}{% endraw %} | base64 -d
   ```

1. Expose the {{site.mesh_product_name}} control plane to make it accessible from your machine using one of the following methods:
   * Port-forward port 5681.
   * Expose port 5681 and protect it with TLS or expose port 5682 with built-in via a load balancer.
   * Expose port 5681 using an `Ingress` (for example {{site.kic_product_name}}) and protect it with TLS.

1. Configure `kumactl` with the admin user token:
   ```sh
   kumactl config control-planes add \
     --name my-control-plane \
     --address https://$CONTROL_PLANE_ADDRESS:5682 \
     --auth-type=tokens \
     --auth-conf token=$GENERATED_TOKEN \
     --ca-cert-file=$CA_FILE_PATH
   ```

   {:.info}
   > If you are using the `5681` port, change the schema to `http://`. If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

{% endnavtab %}
{% navtab "Universal" %}
1. Run the following command on the machine where you deployed the control plane to generate the token:
   ```sh
   curl http://localhost:5681/global-secrets/admin-user-token | jq -r .data | base64 -d
   ```

1. Configure `kumactl` with admin user token
   ```sh
   kumactl config control-planes add \
     --name my-control-plane \
     --address https://$CONTROL_PLANE_ADDRESS:5682 \
     --auth-type=tokens \
     --auth-conf token=$GENERATED_TOKEN \
     --ca-cert-file=$CA_FILE_PATH
   ```

   {:.info}
   > If you are using the `5681` port, change the schema to `http://`. If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

1. Disable localhost as admin. By default, all requests originating from the localhost are authenticated as a `mesh-system:admin` user.
   After you retrieve and store the admin token, [configure a control plane](/mesh/control-plane-configuration/) with `KUMA_API_SERVER_AUTHN_LOCALHOST_IS_ADMIN` set to `false`.
{% endnavtab %}
{% endnavtabs %}

### Generate user tokens

To generate user tokens, you must provide the credentials of a user authorized to generate user tokens.
If you have configured `kumactl` with an admin user token, you can use the following command to create a user token:

```sh
kumactl generate user-token \
  --name john \
  --group team-a \
  --valid-for 24h
```

With the API, you must provide a token in the `Authorization` header:

```sh
curl localhost:5681/tokens/user \
  -H'authorization: Bearer eyJhbGc...' \
  -H'content-type: application/json' \
  --data '{"name": "john","groups": ["team-a"], "validFor": "24h"}' 
```

### Revoke user tokens

{{site.mesh_product_name}} doesn't keep a list of issued tokens. To invalidate a token, you must can add it to the revocation list.

Every token has its own ID under the `jti` key.
You can extract the ID from the token using jwt.io or the [`jwt-cli`](https://www.npmjs.com/package/jwt-cli) tool.

To revoke user tokens, specify a comma-separated list of revoked IDs in a global secret named `user-token-revocations`.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```sh
REVOCATIONS=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) && echo "apiVersion: v1
kind: Secret
metadata:
  name: user-token-revocations
  namespace: {{site.mesh_namespace}} 
data:
  value: $REVOCATIONS
type: system.kuma.io/global-secret" | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```sh
echo "
type: GlobalSecret
name: user-token-revocations
data: {{ revocations }}" | kumactl apply --var revocations=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) -f -
```
{% endnavtab %}
{% endnavtabs %}

### Rotate the signing key

A user token is signed by a signing key which is autogenerated on the first start of the control plane.

If the signing key is compromised, you must rotate it. You must also rotate all the tokens that were signed by it.

1. Generate a new signing key.
   The signing key is stored as a global secret named in the following format: `user-token-signing-key-<serial_number>`.

   When generating a new signing key, assign it a serial number greater than the current key's serial number.

{% capture navtabbed_content %}
{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
Get the current key's serial number:
```sh
kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/global-secret'
NAME                       TYPE                           DATA   AGE
user-token-signing-key-1   system.kuma.io/global-secret   1      25m
```

In this example, the highest serial number is `1`. 

Generate a new signing key with a serial number of `2`:
```sh
TOKEN="$(kumactl generate signing-key)" && echo "
apiVersion: v1
data:
  value: $TOKEN
kind: Secret
metadata:
  name: user-token-signing-key-2
  namespace: {{site.mesh_namespace}}
type: system.kuma.io/global-secret
" | kubectl apply -f - 
```

{% endnavtab %}
{% navtab "Universal" %}
Get the current key's serial number:
```sh
kumactl get global-secrets
NAME                       AGE
user-token-signing-key-1   36m
```

In this example, the highest serial number is `1`. 

Generate a new signing key with a serial number of `2`:
```sh
echo "
type: GlobalSecret
name: user-token-signing-key-2
data: {{ key }}" | kumactl apply --var key=$(kumactl generate signing-key) -f -
```
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}
{{ navtabbed_content | indent }}

2. [Generate new tokens](#generate-user-tokens).
   New tokens are generated with the signing key with the highest serial number.
   At this point, tokens signed by either the new or old signing key are valid.

3. Remove the old signing key:
{% capture navtabbed_content %}
{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```sh
kubectl delete secret user-token-signing-key-1 -n {{site.mesh_namespace}}
```
{% endnavtab %}
{% navtab "Universal" %}
```sh
kumactl delete global-secret user-token-signing-key-1
```
{% endnavtab %}
{% endnavtabs %}
All new connections to the control plane now require tokens signed with
the new signing key.
{% endcapture %}
{{ navtabbed_content | indent }}

### Disable the admin user token

You can remove the default admin user token from the storage and prevent it from being recreated.
Keep in mind that removing the admin user token doesn't remove the signing key.
A malicious actor that acquires the signing key, can generate an admin token.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
1. Delete `admin-user-token` Secret
```sh
kubectl delete secret admin-user-token -n kuma-namespace
```

2. Disable bootstrap of the token
   [Configure a control plane](/mesh/control-plane-configuration/) with `KUMA_API_SERVER_AUTHN_TOKENS_BOOTSTRAP_ADMIN_TOKEN` set to `false`.
   {% endnavtab %}
   {% navtab "Universal" %}
1. Delete `admin-user-token` Global Secret
```sh
kumactl delete global-secret admin-user-token
```

2. Disable bootstrap of the token
   [Configure a control plane](/mesh/control-plane-configuration/) with `KUMA_API_SERVER_AUTHN_TOKENS_BOOTSTRAP_ADMIN_TOKEN` set to `false`.
   {% endnavtab %}
   {% endnavtabs %}


### Offline token issuing

In addition to the regular flow of generating signing keys, storing them in secret, and using them to sign tokens on the control plane, Kuma also offers offline signing of tokens.
In this flow, you can generate a pair of public and private keys and configure the control plane only with public keys for token verification.
You can generate all the tokens without running the control plane.

The advantages of this mode are:
* easier, more reproducible deployments of the control plane, and more in line with GitOps.
* potentially more secure setup, because the control plane does not have access to the private keys.

Here's how to use offline issuing

1. Generate a pair of signing keys

   The following commands generate standard RSA key of 2048 bits and outputs it in PEM-encoded format.
   You can use any external tool to generate a pair of keys.

   ```sh
   kumactl generate signing-key --format=pem > /tmp/key-private.pem
   kumactl generate public-key --signing-key-path=/tmp/key-private.pem > /tmp/key-public.pem
   ```

   The result should be similar to this output
   ```sh
   cat /tmp/key-private.pem /tmp/key-public.pem 
   -----BEGIN RSA PRIVATE KEY-----
   MIIEpAIBAAKCAQEAsS61a79gC4mkr2Ltwi09ajakLyUR8YTkJWzZE805EtTkEn/r
   ...
   htKtzsYA7yGlt364IuDybrP+PlPMSK9cQAmWRRZIcBNsKOODkAgKFA==
   -----END RSA PRIVATE KEY-----
   -----BEGIN RSA PUBLIC KEY-----
   MIIBCgKCAQEAsS61a79gC4mkr2Ltwi09ajakLyUR8YTkJWzZE805EtTkEn/rL2u/
   ...
   se7sx2Pt/NPbWFFTMGVFm3A1ueTUoorW+wIDAQAB
   -----END RSA PUBLIC KEY----- 
   ```

2. Configure the control plane with public key

   [Configure a control plane](/mesh/control-plane-configuration/) with the following settings
   ```yaml
   apiServer:
     authn:
       type: tokens
       tokens:
         enableIssuer: false # disable control plane token issuer that uses secrets
         validator:
           useSecrets: false # do not use signing key stored in secrets to validate the token
           publicKeys:
           - kid: "key-1"
             key: |
               -----BEGIN RSA PUBLIC KEY-----
               MIIBCgKCAQEAsS61a79gC4mkr2Ltwi09ajakLyUR8YTkJWzZE805EtTkEn/rL2u/
               ...
               se7sx2Pt/NPbWFFTMGVFm3A1ueTUoorW+wIDAQAB
               -----END RSA PUBLIC KEY-----
   ```
   
3. Use the private key to issue tokens offline

   The command is the same as with online signing, but with two additional arguments:
   * `--kid` - ID of the key that should be used to validate the token. This should match `kid` specified in the control plane configuration.
   * `--signing-key-path` - path to a PEM-encoded private key.

   ```sh
   kumactl generate user-token \
     --name john.doe@example.com \
     --group users \
     --valid-for 24h \
     --signing-key-path /tmp/key-private.pem \
     --kid key-1
   ```
   
   You can also use any external system that can issue JWT tokens using `RS256` signing method with the following claims:
   * `Name` (string) - the name of the user
   * `Groups` ([]string) - list of user groups
   
#### Migration

You can use both offline and online issuing by keeping `apiServer.authn.tokens.enableIssuer` to true.
You can use both secrets and public key static config validators by keeping `apiServer.authn.tokens.validator.useSecrets` to true.

#### Management

Token revocation works the same when using both online and offline issuing.

Signing key rotation works similarly:
* generate another pair of signing keys
* configure a control plane with old and new public keys
* regenerate tokens for all existing users with the new private key
* remove the old public key from the configuration


## Admin client certificates

This section describes the alternative way of authenticating to API Server.

{:.warning}
> Admin client certificates are deprecated. If you are using it, please migrate to the user token in preceding section.

To use admin client certificates, set `KUMA_API_SERVER_AUTHN_TYPE` to `adminClientCerts`.

All users that provide client certificate are authenticated as a user with the name `mesh-system:admin` that belongs to group `mesh-system:admin`.

### Usage

1. Generate client certificates by using kumactl
   ```sh
   kumactl generate tls-certificate --type=client \
     --cert-file=/tmp/tls.crt \
     --key-file=/tmp/tls.key
   ```

2. Configure the control plane with client certificates
   {% capture tabs %}
   {% navtabs "Environment" %}
   {% navtab "Kubernetes (kumactl)" %}
   Create a secret in the namespace in which control plane is installed
   ```sh
   kubectl create secret generic api-server-client-certs -n {{site.mesh_namespace}} \
     --from-file=client1.pem=/tmp/tls.crt \
   ```
   You can provide as many client certificates as you want. Remember to only provide certificates without keys.

   Point to this secret when installing {{site.mesh_product_name}}
   ```sh
   kumactl install control-plane \
     --tls-api-server-client-certs-secret=api-server-client-certs
   ```
   {% endnavtab %}
   {% navtab "Kubernetes (Helm)" %}
   Create a secret in the namespace in which control plane is installed
   ```sh
   kubectl create secret generic api-server-client-certs -n {{site.mesh_namespace}} \
     --from-file=client1.pem=/tmp/tls.crt \
   ```
   You can provide as many client certificates as you want. Remember to only provide certificates without keys.

   Set `{{site.set_flag_values_prefix}}controlPlane.tls.apiServer.clientCertsSecretName` to `api-server-client-certs` via HELM
   {% endnavtab %}
   {% navtab "Universal" %}
   Put all the certificates in one directory
   ```sh
   mkdir /opt/client-certs
   cp /tmp/tls.crt /opt/client-certs/client1.pem 
   ```
   All client certificates must end with `.pem` extension. Remember to only provide certificates without keys.

   Configure control plane by pointing to this directory
   ```sh
   KUMA_API_SERVER_AUTH_CLIENT_CERTS_DIR=/opt/client-certs \
     kuma-cp run
   ```
   {% endnavtab %}
   {% endnavtabs %}
   {% endcapture %}
   {{ tabs | indent }}

3. Configure `kumactl` with valid client certificate
   ```sh
   kumactl config control-planes add \
     --name=<NAME>
     --address=https://<KUMA_CP_DNS_NAME>:5682 \
     --client-cert-file=/tmp/tls.crt \
     --client-key-file=/tmp/tls.key \
     --ca-cert-file=/tmp/ca.crt
   ```

   If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

## Multi-zone

In a multi-zone setup, users execute a majority of actions on the global control plane.
However, some actions like generating dataplane tokens are available on the zone control plane.
The global control plane doesn't propagate authentication credentials to the zone control plane.
You can set up consistent user tokens across the whole setup by manually copying signing key from global to zone control planes. 
