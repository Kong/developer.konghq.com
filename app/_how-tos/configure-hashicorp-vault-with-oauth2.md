---
title: Configure HashiCorp Vault as a vault backend with OAuth2
content_type: how_to
description: "Learn how to configure HashiCorp Vault with OAuth2 and reference HashiCorp Vault secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Configure HashiCorp Vault as a vault backend with certificate authentication
    url: /how-to/configure-hashicorp-vault-with-cert-auth/
  - text: Store Keyring data in a HashiCorp Vault
    url: /how-to/store-keyring-in-hashicorp-vault/
  - text: Configure Hashicorp Vault with {{ site.kic_product_name }}
    url: "/kubernetes-ingress-controller/vault/hashicorp/"

works_on:
    - on-prem

min_version:
  gateway: '3.13'

entities: 
  - vault

tags:
    - secrets-management
    - security
    - hashicorp-vault
search_aliases:
  - Hashicorp Vault
tldr:
    q: ""
    a: ""

tools:
    - deck


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
    a: Configure your Vault entity to use HTTPS instead of HTTP. This can be done updating your config.hcl. You will need to set the address to include the `https` protocol and include the certificate/key in the `tls_cert_file` and `tls_key_file` parameters. 
  - q: "I'm getting an `unable to retrieve secret from vault: 18: self-signed certificate` error, how do I fix this?"
    a: Add the self-signed certificate in `kong.conf` to the parameter `lua_ssl_trusted_certificate`.
  - q: "I'm getting an `unable to retrieve secret from vault: certificate host mismatch` error, how do I fix this?"
    a: The hostname specified in your Vault entity does not match the cert presented by the Vault server. Confirm the Kong Vault `config.host` matches the name of the certificate presented by the Vault server certificate.
  - q: |
      I'm getting an `invalid response code 400 received when performing certificate-based authentication: {"errors":["auth methods cannot create root tokens"]}` error, how do I fix this?
    a: |
      The certificate is mapped to a policy that would allow creation of a root token, which Vault explicitly forbids. Check the policy associated with your certificate
      to ensure that it does not include `CREATE`, `UPDATE`, `READ` operations on the path `auth/token/root`
  - q: "I'm getting an `ailure performing certificate-based authentication: 21: unable to verify the first certificate` error, how do I fix this?"
    a: |
      This will usually occur for one of two reasons:
      * You have a certificate chain and only a portion of it was uploaded for {{site.base_gateway}} to use. Fix: Include the entire chain in `KONG_LUA_SSL_TRUSTED_CERTIFICATE`.
      * HashiCorp Vault was setup in dev mode. This **does not** allow you to provide your own CA and instead uses an ephemeral cert for SAN: “localhost, 127.0.0.1, 0.0.0.0.”
  - q: |
      I'm getting an `invalid response code 503 received when performing certificate-based authentication: {"errors":["Vault is sealed"]}` error, how do I fix this?
    a: To perform any operation on the Vault, it must be unsealed first. It was likely sealed intentionally or through a restart of the Vault process.

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret      

automated_tests: false
---

