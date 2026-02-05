---
title: Configure HashiCorp Vault as a vault backend with OAuth2
permalink: /how-to/configure-hashicorp-vault-with-oauth2/
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
    - oauth2
search_aliases:
  - Hashicorp Vault
tldr:
    q: "How can I configure OAuth2 to authenticate to HashiCorp?"
    a: |
      1. Get your OAuth2 application domain, client ID, and client secret from your IdP.
      1. Create a HashiCorp vault with the [JWT role type](https://developer.hashicorp.com/vault/docs/auth/jwt).
      1. In {{site.base_gateway}}, create a Vault entity with the `config.auth_method` set to `oauth2`, and the requires HashiCorp and OAuth2 parameters.

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
  - q: |
      {% include /gateway/vaults-format-faq.md type='question' %}
    a: |
      {% include /gateway/vaults-format-faq.md type='answer' %}

automated_tests: false
---

## Configure access to the Auth0 Management API

To use OAuth2 authentication for your HashiCorp Vault with Auth0 as the identity provider (IdP), there are two important configurations to prepare in Auth0. First, you must authorize an Auth0 application so {{site.base_gateway}} can use the Auth0 Management API on your behalf. Next, you will create an API audience that {{site.base_gateway}} applications will be granted access to.

To get started configuring Auth0, log in to your [Auth0 dashboard](https://manage.auth0.com/dashboard/) and complete the following:

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
   vault kv put -mount="secret" "password" pass1=my-password
   ```

1. Export the HashiCorp host and token to your environment:
   ```
   export DECK_HCV_HOST=host.docker.internal
   export DECK_HCV_TOKEN=root
   ```

   In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` variable that HashiCorp Vault uses by default. This is because if you used the quick-start script {{site.base_gateway}} is running in a Docker container and uses a different `localhost`. Because we are running HashiCorp Vault in dev mode, we are using `root` for our `token` value.

## Allow read access to your HashiCorpVault

1. Navigate to [http://localhost:8200/](http://localhost:8200/) to access the HashiCorp Vault UI.

1. Enter "root" in the **Token** field and click **Sign in**.

1. Click **Policies**.

1. Click **default**.

1. Click **Edit policy** and append the following to the policy file:
   ```
   path "secret/*" {
    capabilities = ["read"]
   }
   ```

1. Click **Save**

## Create a Vault entity for HashiCorp Vault 

Create a Vault entity with the required parameters for HashiCorp Vault:

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

Since {{site.konnect_short_name}} data plane container names can vary, set your container name as an environment variable:
{: data-deployment-topology="konnect" }
```sh
export KONNECT_DP_CONTAINER='your-dp-container-name'
```
{: data-deployment-topology="konnect" }

To validate that the secret was stored correctly in HashiCorp Vault, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://hashicorp-vault/password/pass1}'
value: 'my-password'
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://hashicorp-vault/password/pass1}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).  