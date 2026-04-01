{% assign type = include.type %}

{% if type == "zone" %}

{% assign issuer = "dpServer.authn.zoneProxy.zoneToken.enableIssuer" %}
{% assign secrets = "dpServer.authn.zoneProxy.zoneToken.validator.useSecrets" %}

{% capture conf %}
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
{% endcapture %}

{% capture kumactl %}
```sh
kumactl generate zone-token \
  --zone us-east \
  --scope egress \
  --valid-for 720h \
  --signing-key-path /tmp/key-private.pem \
  --kid key-1
```
{% endcapture %}

{% capture claims %}   
* `Zone`: The name of the zone.
* `Scope`: The list of scopes (`egress`, `ingress`).
{% endcapture %}

{% endif %}

{% if type == "user" %}

{% assign issuer = "apiServer.authn.tokens.enableIssuer" %}
{% assign secrets = "apiServer.authn.tokens.validator.useSecrets" %}

{% capture conf %}
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
{% endcapture %}

{% capture kumactl %}
```sh
kumactl generate user-token \
  --name john.doe@example.com \
  --group users \
  --valid-for 24h \
  --signing-key-path /tmp/key-private.pem \
  --kid key-1
```
{% endcapture %}

{% capture claims %}   
* `Name`: The name of the user.
* `Groups`: The list of user groups.
{% endcapture %}

{% endif %}

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

2. Configure the control plane with the public key.

   [Configure a control plane](/mesh/control-plane-configuration/) with the following settings:
{{conf | indent: 3}}

3. Use the private key to issue tokens offline:

   {{kumactl | indent: 3}}

   The command is the same as with online signing, but with two additional arguments:
   * `--kid`: The ID of the key that should be used to validate the token. This should match `kid` specified in the control plane configuration.
   * `--signing-key-path`: The path to a PEM-encoded private key.

   You can also use any external system that can issue JWT tokens using `RS256` signing method with the following claims:
   {{claims | indent: 3}}

### Migration

You can use both offline and online issuing by setting `{{issuer}}` to true.
You can use both secrets and public key static config validators by setting `{{secrets}}` to true.

### Management

Token revocation works the same when using both online and offline issuing.

Signing key rotation works similarly:
1. Generate another pair of signing keys.
1. Configure a control plane with old and new public keys.
1. Regenerate all tokens with the new private key.
1. Remove the old public key from the configuration.