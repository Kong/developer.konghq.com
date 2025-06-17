---
title: Configure HashiCorp Vault as a vault backend with certificate authentication
content_type: how_to
description: "Learn how to configure HashiCorp Vault with certificate authentication and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Store Keyring data in a HashiCorp Vault
    url: /how-to/store-keyring-in-hashicorp-vault/
  - text: Configure Hashicorp Vault with {{ site.kic_product_name }}
    url: "/kubernetes-ingress-controller/vault/hashicorp/"

works_on:
    - on-prem

min_version:
  gateway: '3.11'

entities: 
  - vault

tags:
    - secrets-management
    - security
    - hashicorp-vault
search_aliases:
  - Hashicorp Vault
tldr:
    q: How can I configure HashiCorp Vault as a Vault backend with certificate authentication access Vault secrets in {{site.base_gateway}}? 
    a: |
      Start a HashiCorp Vault with a client certificates and a certificate that is served from HashiCorp Vault with a `subjectAltName` that matches the name requested by {{site.base_gateway}}. Configure HashiCorp Vault to use certificate-based authentication with `vault auth enable cert`. Set the `lua_ssl_trusted_certificate` parameter in `kong.conf` to use the certificate that is served from HashiCorp Vault. Configure a Vault entity in {{site.base_gateway}}, using the initial root token for your `config.token`, set the `config.auth_method` to `cert`, and set `config.cert_auth_cert_key` and `config.cert_auth_cert`. 

tools:
    - deck

prereqs:
  inline: 
    - title: Generate client certificates
      content: |
        To complete this tutorial, you need client certificates. If you don't have client certificates, you can use the following script and steps to generate them:

        1. Save this script as `gen_certs.sh` in your home directory:
           ```sh
           #!/bin/bash

           # Generate root CA private key
           openssl genrsa -out rootCA.key 4096

           # Create root CA certificate
           openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=Root CA"

           # Generate server private key
           openssl genrsa -out kong.example.com.key 2048

           # Create server CSR
           openssl req -new -key kong.example.com.key -out kong.example.com.csr -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=kong.example.com"

           # Create server.ext file for SANs
           cat > kong.example.com.ext <<EOF
           authorityKeyIdentifier=keyid,issuer
           basicConstraints=CA:FALSE
           keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
           subjectAltName = @alt_names

           [alt_names]
           DNS.1 = kong.example.com
           EOF

           # Sign server CSR with root CA
           openssl x509 -req -in kong.example.com.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out kong.example.com.crt -days 365 -sha256 -extfile kong.example.com.ext

           # Clean up
           rm kong.example.com.csr
           rm rootCA.srl

           echo "Root CA and server key pair generated successfully."
           ```
        
        1. Generate the certificates from the script:
           ```sh
           mkdir -p ~/vault/certs && cd ~/vault/certs
           bash ~/gen_certs.sh
           ```
      icon_url: /assets/icons/file.svg
    - title: Generate a certificate for HashiCorp Vault
      content: |
        To complete this tutorial, you need a certificate that is served by HashiCorp Vault. The `subjectAltName` **must** match the name requested by {{site.base_gateway}}. This is used in the `config.hcl` file.

        To generate the certificate, run the following from your home directory in terminal:
        ```bash
        openssl req -x509 -nodes -days 365 \
          -newkey rsa:2048 \
          -keyout ./vault/certs/vault.key \
          -out ./vault/certs/vault.crt \
          -subj "/CN=localhost" \
          -addext "subjectAltName = DNS:host.docker.internal, IP:127.0.0.1"
        ```
      icon_url: /assets/icons/file.svg

cleanup:
  inline:
    - title: Clean up HashiCorp Vault
      include_content: cleanup/third-party/hashicorp
      icon_url: /assets/icons/hashicorp.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: How do I rotate my secrets in HashiCorp Vault and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in HashiCorp Vault by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically.
  - q: How does {{site.base_gateway}} retrieve secrets from HashiCorp Vault?
    a: |
      {{site.base_gateway}} retrieves secrets from HashiCorp Vault's HTTP API through a two-step process: authentication and secret retrieval.

      **Step 1: Authentication**

      Depending on the authentication method defined in `config.auth_method`, {{site.base_gateway}} authenticates to HashiCorp Vault using one of the following methods:

      - If you're using the `token` auth method, {{site.base_gateway}} uses the `config.token` as the client token.
      - If you're using the `kubernetes` auth method, {{site.base_gateway}} uses the service account JWT token mounted in the pod (path defined in the `config.kube_api_token_file`) to call the login API for the Kubernetes auth path on the HashiCorp Vault server and retrieve a client token.
      - {% new_in 3.4 %} If you're using the `approle` auth method, {{site.base_gateway}} uses the AppRole credentials to retrieve a client token. The AppRole role ID is configured by field `config.approle_role_id`, and the secret ID is configured by field `config.approle_secret_id` or `config.approle_secret_id_file`. 
        - If you set `config.approle_response_wrapping` to `true`, then the secret ID configured by
        `config.approle_secret_id` or `config.approle_secret_id_file` will be a response wrapping token, 
        and {{site.base_gateway}} will call the unwrap API `/v1/sys/wrapping/unwrap` to unwrap the response wrapping token to fetch 
        the real secret ID. {{site.base_gateway}} will use the AppRole role ID and secret ID to call the login API for the AppRole auth path
        on the HashiCorp Vault server and retrieve a client token.
      - {% new_in 3.11 %} If you're using the `cert` auth method, {{site.base_gateway}} uses a client certificate and private key to retrieve a client token. The certificate must be previously configured in HashiCorp vault as a trusted certificate. Alternatively, the issuing CA certificate can be set as a trusted CA. The trusted certificate role name is configured by the field `config.cert_auth_role_name`. If one isn't provided, HashiCorp vault attempts to authenticate against all configured trusted certificates or trusted CAs. The certificate is configured with `config.cert_auth_cert` and the key with `cert_auth_cert_key`.
      
      By calling the login API, {{site.base_gateway}} will retrieve a client token and then use it in the next step as the value of `X-Vault-Token` header to retrieve a secret.

      **Step 2: Retrieving the secret**

      {{site.base_gateway}} uses the client token retrieved in the authentication step to call the Read Secret API and retrieve the secret value. The request varies depending on the secrets engine version you're using.
      {{site.base_gateway}} will parse the response of the read secret API automatically and return the secret value.
  - q: I get a `Client sent an HTTP request to an HTTPS server.` error when I try to retrieve my secret, how do I fix this?
    a: Configure your Vault entity to use HTTPS instead of HTTP by setting `config.protocol` to `https`.
  - q: "I'm getting an `unable to retrieve secret from vault: 18: self-signed certificate` error, how do I fix this?"
    a: Set the self-signed certificate in `kong.conf` with `KONG_LUA_SSL_TRUSTED_CERTIFICATE`.
  - q: "I'm getting an `unable to retrieve secret from vault: certificate host mismatch` error, how do I fix this?"
    a: "The hostname specified in your Vault entity does not match the cert presented by the Vault server (for example: `8200`)."
  - q: "I'm getting an `unable to retrieve secret from vault: no authentication mechanism worked for vault` error, how do I fix this?"
    a: |
      The certificate is mapped to a policy that would allow creation of a root token, which Vault explicitly forbids. Your vault server either:
      * Had a chain and only a portion of it was uploaded for {{site.base_gateway}} to use. Fix: Include the entire chain in `KONG_LUA_SSL_TRUSTED_CERTIFICATE`.
      * HashiCorp Vault was setup in dev mode. This **does not** allow you to provide your own CA and instead uses an ephemeral cert for SAN: “localhost, 127.0.0.1, 0.0.0.0.”

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## Configure HashiCorp Vault

Before you can configure the Vault entity in {{site.base_gateway}}, you must configure HashiCorp Vault to authenticate clients based on certificates signed by the provided root CA certificate and store a secret.

### Create configuration files

First, you need to create the primary configuration file `config.hcl` for HashiCorp Vault in the `./vault` directory:
```
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "./vault/certs/vault.crt"
  tls_key_file  = "./vault/certs/vault.key"
}

storage "file" {
  path = "./vault/data"
}

ui = true
```

Then, create the HashiCorp policy file `rw-secrets.hcl` in the `./vault` directory:
```
# Full access to everything — use with caution!
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
```

### Configure the Vault and store a secret

Now, you can configure HashiCorp Vault to use certificate-based authentication.

1. Start HashiCorp Vault:
   ```sh
   vault server -config=./vault/config.hcl
   ```
1. In a new terminal, configure HashiCorp Vault to trust the TLS certificate:
   ```sh
   export VAULT_CACERT=$HOME/vault/certs/vault.crt
   ```
1. Initialize the Vault:
   ```sh
   vault operator init -key-shares=1 -key-threshold=1
   ```
   This will output your unseal key and your inital root token. Export them as environment variables:
   ```sh
   export HCV_UNSEAL_KEY='YOUR-UNSEAL-KEY'
   export DECK_HCV_TOKEN='YOUR-INITIAL-ROOT-TOKEN'
   ```
1. Unseal your Vault:
   ```sh
   vault operator unseal $HCV_UNSEAL_KEY
   ```
1. Login to your Vault:
   ```sh
   vault login $DECK_HCV_TOKEN
   ```
1. Write the policy for certificate authentication:
   ```sh
   vault policy write rw-secrets ./vault/rw-secrets.hcl
   ```
1. Enable cert-based authentication:
   ```sh
   vault auth enable cert
   ```
1. Configure Vault to authenticate clients based on certificates signed by the provided root CA certificate:
   ```sh
   vault write auth/cert/config certificate=./vault/certs/rootCA.crt
   ```
1. Write the configuration. This will set the display name `gw311`, associate it with the `rw-secrets` policy and load the certificate data:
   ```sh
   vault write auth/cert/certs/gw311 \
      display_name="gw311" \
      policies="rw-secrets" \
      certificate=@./vault/certs/rootCA.crt \
      allow_subdomains=false
  ```
1. Test the login using certificate authentication:
   ```sh
   vault login -method=cert \
     -client-cert=./vault/certs/kong.example.com.crt \
     -client-key=./vault/certs/kong.example.com.key
   ```
1. Enable the K/V secrets engine:
   ```sh
   vault secrets enable -path=kong kv
   ```
1. Create a secret:
   ```sh
   vault kv put kong/headers/request header="x-kong:test"
   ```
1. Confirm you can retrieve the secret through Vault:
   ```sh
   vault kv get kong/headers/request
   ```

## Configure the Lua SSL trusted certificate 

Because the certificates in this tutorial are self-signed, we must configure the [`lua_ssl_trusted_certificate` parameter](/gateway/configuration/#lua-ssl-trusted-certificate) in `kong.conf` to use the certificate that is served from HashiCorp Vault, `vault.crt`.

In terminal, copy your `vault.crt` file to your Docker container:
```
docker cp ./vault/certs/vault.crt kong-quickstart-gateway:./vault.crt
```

In your Docker container, make a copy of the default Kong configuration file:
```
cp /etc/kong/kong.conf.default /etc/kong/kong.conf
```

Open `kong.conf` in your Docker container, find `lua_ssl_trusted_certificate`, uncomment it and replace it with the following:
```
lua_ssl_trusted_certificate = ./vault.crt
```

Reload {{site.base_gateway}} in your Docker container to get the setting to take effect:
```
kong reload -c /etc/kong/kong.conf
```

## Set environment variables

Export the following environment variables:

```
export DECK_HCV_HOST=host.docker.internal
export DECK_HCV_CERT_KEY=$(awk 'NR > 1 {printf "\\n"} {printf "%s", $0} END {printf ""}' ./vault/certs/kong.example.com.key)
export DECK_HCV_CERT=$(awk 'NR > 1 {printf "\\n"} {printf "%s", $0} END {printf ""}' ./vault/certs/kong.example.com.crt)
```

In this tutorial, we’re using `host.docker.internal` as our host instead of the `localhost` variable that HashiCorp Vault is using. This is because if you used the quick-start script, {{site.base_gateway}} is running in a container and uses a different `localhost`.

## Create a Vault entity for HashiCorp Vault 

Using decK, create a [Vault entity](/gateway/entities/vault/) in the `kong.yaml` file with the required parameters for HashiCorp Vault:

{% entity_examples %}
entities:
  vaults:
    - name: hcv
      prefix: hashicorp-vault
      description: Storing secrets in HashiCorp Vault
      config:
        host: ${hcv_host}
        token: ${hcv_token}
        kv: v1
        mount: kong
        port: 8200
        protocol: https
        auth_method: cert
        cert_auth_cert_key: ${cert_key}
        cert_auth_cert: ${cert}

variables:
  hcv_host:
    value: $HCV_HOST
  hcv_token:
    value: $HCV_TOKEN
  cert_key:
    value: $HCV_CERT_KEY
  cert:
    value: $HCV_CERT
{% endentity_examples %}

## Validate

To validate that the secret was stored correctly in HashiCorp Vault, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/headers/request/header}'
value: 'x-kong:test'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://hashicorp-vault/headers/request/header}` to reference the secret in any referenceable field.
