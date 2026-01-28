---
title: Zone proxy authentication
description: Learn about authentication for zone proxies using service account tokens or zone tokens for secure control plane communication.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: Zone ingress
    url: /mesh/zone-ingress/
  - text: Zone egress
    url: /mesh/zone-egress/
---

To obtain a configuration from the control plane, a zone proxy ([zone ingress](/mesh/zone-ingress/) or [zone egress](/mesh/zone-egress/)) must authenticate itself.
You can do this using:

* A [service account token](#service-account-token) on Kubernetes
* A [zone token](#zone-token) on Universal

## Service account token

On Kubernetes, a zone proxy authenticates by leveraging the [`ServiceAccountToken`](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume) that is mounted in every Pod.

## Zone token

On Universal, a zone proxy must be explicitly configured with a unique security token with the appropriate scope (`egress` or `ingress`).

The zone token used to identify zone proxies is a [JWT token](https://jwt.io) that contains:
* The zone in which zone proxy operates
* The expiration date of the token (10 years by default)
* The scope as a list of proxies for which the token is valid (`egress` and `ingress` by default)

The zone token is signed using a key that the control plane autogenerates on first startup. Tokens themselves are never stored in the control plane. Only the signing keys are stored, and these are used to verify token validity. The signing algorithm is RS256.

You can use the following command to check for the signing key:
```sh
kumactl get global-secrets
```

You should get the following result:
```
NAME                       AGE
zone-token-signing-key-1   7s
```
{:.no-copy-code}

### Generate a zone token

{% navtabs "Tool" %}
{% navtab "kumactl" %}
Use the following command to generate a token with `kumactl`:
```bash
kumactl generate zone-token \
  --zone us-east \
  --scope egress \
  --valid-for 720h > /tmp/kuma-zone-proxy-token
```
{% endnavtab %}
{% navtab "REST API" %}
Use the following command to generate the token with the REST API:
```bash
curl -XPOST \
  -H "Content-Type: application/json" \
  --data '{"zone": "us-east", "validFor": "720h", "scope": ["egress", "ingress"]}' \
  http://localhost:5681/tokens/zone > /tmp/kuma-zone-proxy-token
```
{% endnavtab %}
{% endnavtabs %}

The token should be stored in a file and then passed when you start `kuma-dp`:
```bash
kuma-dp run \
  --proxy-type=ingress # or egress \
  --dataplane-file=zone-proxy-definition.yaml
  --cp-address=https://127.0.0.1:5678 \
  --dataplane-token-file=/tmp/kuma-zone-proxy-token
```

You can also pass the token as a `KUMA_DATAPLANE_RUNTIME_TOKEN` environment variable.

## Revoke a token

{{site.mesh_product_name}} doesn't keep a list of issued tokens. 
Whenever a single token is compromised, you can add it to the revocation list to invalidate it.

Every token has its own ID under `jti` key.
You can extract the ID from the token using jwt.io or the [`jwt-cli`](https://www.npmjs.com/package/jwt-cli) tool.

To revoke tokens, specify a comma-separated list of revoked IDs in a global secret named `zone-token-revocations`.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```sh
REVOCATIONS=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) && echo "apiVersion: v1
kind: Secret
metadata:
  name: zone-token-revocations
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
name: zone-token-revocations
data: {{ revocations }}" | kumactl apply --var revocations=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) -f -
```
{% endnavtab %}
{% endnavtabs %}

## Rotate a signing key

If the signing key is compromised, you must rotate it. You must also rotate all the tokens that were signed by it.

1. Generate a new signing key.
   The signing key is stored as a global secret named in the following format: `zone-token-signing-key-<serial_number>`.

   When generating a new signing key, assign it a serial number greater than the current key's serial number.

{% capture navtabbed_content %}
{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
Get the current key's serial number:
```sh
kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/global-secret'
NAME                       TYPE                           DATA   AGE
zone-token-signing-key-1   system.kuma.io/global-secret   1      25m
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
  name: zone-token-signing-key-2
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
zone-token-signing-key-1   36m
```

In this example, the highest serial number is `1`. 

Generate a new signing key with a serial number of `2`:
```sh
echo "
type: GlobalSecret
name: zone-token-signing-key-2
data: {{ key }}" | kumactl apply --var key=$(kumactl generate signing-key) -f -
```
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}
{{ navtabbed_content | indent }}

2. [Generate new tokens](#generate-a-zone-token).
   New tokens are generated with the signing key with the highest serial number.
   At this point, tokens signed by either the new or old signing key are valid.

3. Remove the old signing key:
{% capture navtabbed_content %}
{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```sh
kubectl delete secret zone-token-signing-key-1 -n {{site.mesh_namespace}}
```
{% endnavtab %}
{% navtab "Universal" %}
```sh
kumactl delete global-secret zone-token-signing-key-1
```
{% endnavtab %}
{% endnavtabs %}
All new connections to the control plane now require tokens signed with
the new signing key.
{% endcapture %}
{{ navtabbed_content | indent }}


## Offline token issuing

In addition to the regular flow of generating signing keys, storing them in a secret, and using them to sign tokens on the control plane, {{site.mesh_product_name}} also offers offline signing of tokens.

In this flow, you can generate a pair of public and private keys and configure the control plane only with public keys for token verification.
You can generate all the tokens without running the control plane.

The advantages of this mode are:
* It allows for easier and more reproducible deployments of the control plane, and it's more in line with GitOps.
* It's a potentially more secure setup, because the control plane doesn't have access to the private keys.

Here's how to use offline issuing:

1. Generate a pair of signing keys:

   ```sh
   kumactl generate signing-key --format=pem > /tmp/key-private.pem
   kumactl generate public-key --signing-key-path=/tmp/key-private.pem > /tmp/key-public.pem
   ```

   

   These commands generate standard RSA key of 2048 bits and outputs it in PEM-encoded format.
   You can use any external tool to generate a pair of keys.
   The result should look like this:
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
   {:.no-copy-code}

2. Configure the control plane with the public key

   [Configure a control plane](/mesh/control-plane-configuration/) with the following settings:
   ```yaml
   dpServer:
     authn:
       zoneProxy:
         type: zoneToken
         zoneToken:
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

3. Use the private key to issue tokens offline:

   ```sh
   kumactl generate zone-token \
     --zone us-east \
     --scope egress \
     --valid-for 720h \
     --signing-key-path /tmp/key-private.pem \
     --kid key-1
   ```

   The command is the same as with online signing, but with two additional arguments:
   * `--kid`: The ID of the key that should be used to validate the token. This should match `kid` specified in the control plane configuration.
   * `--signing-key-path`: The path to a PEM-encoded private key.

   You can also use any external system that can issue JWT tokens using `RS256` signing method with the following claims:
   * `Zone`: The name of the zone.
   * `Scope`: The list of scopes (`egress`, `ingress`).

### Migration

You can use both offline and online issuing by setting `dpServer.authn.zoneProxy.zoneToken.enableIssuer` to true.
You can use both secrets and public key static config validators by setting `dpServer.authn.zoneProxy.zoneToken.validator.useSecrets` to true.

### Management

Token revocation works the same when using both online and offline issuing.

Signing key rotation works similarly:
1. Generate another pair of signing keys.
1. Configure a control plane with old and new public keys.
1. Regenerate tokens for all existing zone proxies with the new private key.
1. Remove the old public key from the configuration.


## Multi-zone

When running in multi-zone mode, you can only generate zone tokens on the global control plane. 
The zone control plane only has a public key signing key to verify tokens.

## Disable zone proxy authentication
You can turn off authentication by setting `KUMA_DP_SERVER_AUTH_TYPE` to `none`.

{:.danger}
> Do not disable authentication between the control plane and data plane proxies in production. 
> Without authentication, any data plane proxy can impersonate any service, allowing unauthorized access to your mesh.
