---
title: Configure HashiCorp Vault as a vault backend with certificate authentication
content_type: how_to
description: "Learn how to configure HashiCorp Vault with certificate authentication and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
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
      placeholder

tools:
    - deck

prereqs:
  inline: 
    - title: HashiCorp Vault
      include_content: prereqs/hashicorp
      icon_url: /assets/icons/hashicorp.svg

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

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## HCV 

```
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout ./vault/certs/vault.key \
  -out ./vault/certs/vault.crt \
  -subj "/CN=localhost" \
  -addext "subjectAltName = DNS:host.docker.internal, IP:127.0.0.1"




vault server -config=/vault/config.hcl

vault policy write rw-secrets ./vault/rw-secrets.hcl

vault auth enable cert

vault write auth/cert/config certificate=./vault/certs/rootCA.crt

vault write auth/cert/certs/gw311 \
  display_name="gw311" \
  policies="rw-secrets" \
  certificate=@./vault/certs/rootCA.crt \
  allow_subdomains=false

vault login -method=cert \
  -client-cert=./vault/certs/kong.example.com.crt \
  -client-key=./vault/certs/kong.example.com.key

vault secrets enable -path=kong kv

vault kv put kong/headers/request header="x-kong:test"

vault kv get kong/headers/request
```

## LUA trusted cert

in terminal
docker cp ./vault/certs/vault.crt kong-quickstart-gateway:./vault.crt

in container
```
cp /etc/kong/kong.conf.default /etc/kong/kong.conf
echo "lua_ssl_trusted_certificate = ./vault.crt" >> /etc/kong/kong.conf
kong reload -c /etc/kong/kong.conf
```


## Set env var

```
export DECK_HCV_HOST=host.docker.internal
export DECK_HCV_TOKEN='root'
export DECK_HCV_CERT_KEY=$(awk 'NR > 1 {printf "\\n"} {printf "%s", $0} END {printf ""}' ./vault/certs/kong.example.com.key)
export DECK_HCV_CERT=$(awk 'NR > 1 {printf "\\n"} {printf "%s", $0} END {printf ""}' ./vault/certs/kong.example.com.crt)
```

## Create a Vault entity for HashiCorp Vault 

Using decK, create a Vault entity in the `kong.yaml` file with the required parameters for HashiCorp Vault:

{% entity_examples %}
entities:
  vaults:
    - name: hcv
      prefix: hashicorp-vault
      description: Storing secrets in HashiCorp Vault
      config:
        host: ${hcv_host}
        token: ${hcv_token}
        kv: v2
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
value: 'ACME Inc.'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://hashicorp-vault/customer/acme/name}` to reference the secret in any referenceable field.
