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
    - konnect

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


prereqs:
  inline: 
    - title: Auth0
      content: |
        You'll need an [Auth0 account](https://auth0.com/) to complete this tutorial.
      icon_url: /assets/icons/third-party/auth0.svg

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

## Configure access to the Auth0 Management API

To use OAuth2 authentication for your HashiCorp Vault with Auth0 as the identity provider (IdP), there are two important configurations to prepare in Auth0. First, you must authorize an Auth0 application so {{site.base_gateway}} can use the Auth0 Management API on your behalf. Next, you will create an API audience that {{site.base_gateway}} applications will be granted access to.

{{site.base_gateway}} will use a client ID and secret from an Auth0 application that has been authorized to perform specific actions in the Auth0 Management API.

To get started configuring Auth0, log in to your Auth0 dashboard and complete the following:

1. From the sidebar, select **Applications > Applications**.

1. Click **Create Application**.

1. Give the application a memorable name, like "HashiCorp Vault OAuth2".

1. Select the application type **Machine to Machine Applications** and click **Create**.

1. Select **Auth0 Management API** from the drop-down list.

1. In the **Permissions** section, select the following permissions to grant access, then click **Authorize**:
   * `read:client_grants`
   * `create:client_grants`
   * `delete:client_grants`
   * `update:client_grants`
   * `read:clients`
   * `create:clients`
   * `delete:clients`
   * `update:clients`
   * `update:client_keys`
  
   {:.info}
   > **Note:** If you’re using Developer Managed Scopes, add `read:resource_servers` to the permissions for your initial client application.

1. Click **Authorize**.

1. On the application page, click the **Settings** tab, locate the values for **Domain**, **Client ID** and **Client Secret**, and export them as environment variables:

   ```sh
   export DECK_DOMAIN="YOUR AUTH0 DOMAIN"
   export DECK_CLIENT_ID="YOUR AUTH0 CLIENT ID"
   export DECK_CLIENT_SECRET="YOUR AUTH0 CLIENT SECRET"
   ```

## Configure your HashiCorp Vault

{:.warning}
> **Important:** This tutorial uses the literal `root` string as your token, which should only be used in testing and development environments.

1. [Install HashiCorp Vault](https://developer.hashicorp.com/vault/tutorials/get-started/install-binary#install-vault).
1. In a new terminal, start your Vault dev server with `root` as your token.
   ```
   vault server -dev -dev-root-token-id root
   ```

1. In the output from the previous command, copy the `VAULT_ADDR` to export.
1. In the terminal window where you exported your Auth0 variables, export your `VAULT_ADDR` as an environment variable.
1. Verify that your Vault is running correctly:
   ```
   vault status
   ```

1. Enable JWT and add the Auth0 JWKS URL:
   ```
   vault auth enable jwt
   vault write auth/jwt/config jwks_url="https://$DECK_DOMAIN/.well-known/jwks.json"
   ```

1. Configure a JWT role named `demo`:
   ```
   vault write auth/jwt/role/demo \
    role_type=jwt \
    user_claim=sub \
    token_type=batch \
    token_policies="default" \
    bound_subject="$DECK_CLIENT_ID@clients" \
    bound_audiences="https://$DECK_DOMAIN/api/v2/"
   ```
  
1. Add a secret:
   ```
   vault kv put -mount="secret" "password" pass=mypassword
   ```

1. Export the HashiCorp host and token to your environment:
   ```
   export DECK_HCV_HOST=host.docker.internal
   export DECK_HCV_TOKEN=root
   ```

   In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` variable that HashiCorp Vault uses by default. This is because if you used the quick-start script {{site.base_gateway}} is running in a Docker container and uses a different `localhost`. Because we are running HashiCorp Vault in dev mode, we are using `root` for our `token` value.

## Allow read access to your HashiCorpVault

1. Navigate to [](http://localhost:8200/) to access the HashiCorp Vault UI.

1. Enter "root" in the **Token** field and click **Sign in**.

1. Click **Policies**.

1. Click **_default**.

1. Click **Edit policy** and add the following to the policy file:
   ```
   path "secret/*" {
    capabilities = ["read"]
   }
   ```

1. Click **Save**

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
        mount: secret
        port: 8200
        protocol: http
        auth_method: oauth2
        oauth2_role_name: demo
        oauth2_token_endpoint: https://${domain}/oauth/token
        oauth2_client_id: ${client_id}
        oauth2_client_secret: ${client_secret}
        oauth2_audiences: https://${domain}/api/v2/

variables:
  hcv_host:
    value: $HCV_HOST
  hcv_token:
    value: $HCV_TOKEN
  domain:
    value: $DOMAIN
  client_id:
    value: $CLIENT_ID
  client_secret:
    value: $CLIENT_SECRET
{% endentity_examples %}


## Validate

To validate that the secret was stored correctly in HashiCorp Vault, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/password/pw1}'
value: 'mypassword'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://hashicorp-vault/password/pass1}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).  