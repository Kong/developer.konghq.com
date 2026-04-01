---
title: Store Keyring data in a HashiCorp Vault
permalink: /how-to/store-keyring-in-hashicorp-vault/
content_type: how_to
related_resources:
  - text: Keyring
    url: /gateway/keyring/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: HashiCorp Vault configuration parameters
    url: "/gateway/entities/vault/?tab=hashicorp#vault-provider-specific-configuration-parameters"
description: Learn how to store Keyring data in a HashiCorp Vault.
products:
    - gateway

works_on:
    - on-prem

tags:
  - secrets-management
  - hashicorp-vault

search_aliases:
  - HCV

tldr:
    q: How do I store Keyring data in a HashiCorp Vault?
    a: Create a HashiCorp Vault and add a key and ID, then set the `kong_keyring_strategy` kong.conf parameter to `vault` and the required `keyring_vault_*` parameters in your configuration, either in `kong.conf` or with environment variables. Use the `/keyring/vault/sync` API to synchronize.
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
      
      By calling the login API, {{site.base_gateway}} will retrieve a client token and then use it in the next step as the value of `X-Vault-Token` header to retrieve a secret.

      **Step 2: Retrieving the secret**

      {{site.base_gateway}} uses the client token retrieved in the authentication step to call the Read Secret API and retrieve the secret value. The request varies depending on the secrets engine version you're using.
      {{site.base_gateway}} will parse the response of the read secret API automatically and return the secret value.
prereqs:
  skip_product: true
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

min_version:
    gateway: '3.4'

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## Create a key in the HashiCorp Vault

The Keyring integration with HashiCorp Vaults allows you to store and version Keyring data. {{site.base_gateway}} nodes can read the keys directly from the Vault to encrypt and decrypt sensitive data. 

First, we need to add a key and key ID to the Vault. Let's create a secret named `keyring`:
{% validation custom-command %}
command: |
  curl http://localhost:8200/v1/secret/data/keyring \
       -H "X-Vault-Token: $VAULT_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"data":{"id":"8zgITLQh","key":"t6NWgbj3g9cbNVC3/D6oZ2Md1Br5gWtRrqb1T2FZy44="}}'
expected:
  return_code: 0
render_output: false
{% endvalidation %}



## Start {{site.base_gateway}}

Set the environment variables that will be used by {{site.base_gateway}} to enable the Keyring and connect it to the HashiCorp Vault.
Since the Keyring feature requires a {{site.ee_product_name}} license, make sure to include it in the environment too.

Create the {{site.base_gateway}} container with the environment variables. In this example, we can use the quickstart:
{% validation custom-command %}
command: |
  curl -Ls https://get.konghq.com/quickstart | bash -s -- -r "" -e KONG_LICENSE_DATA \
      -e KONG_KEYRING_ENABLED=on \
      -e KONG_KEYRING_STRATEGY=vault \
      -e KONG_KEYRING_VAULT_HOST=$VAULT_ADDR \
      -e KONG_KEYRING_VAULT_MOUNT=secret  \
      -e KONG_KEYRING_VAULT_PATH=keyring \
      -e KONG_KEYRING_VAULT_AUTH_METHOD=token  \
      -e KONG_KEYRING_VAULT_TOKEN=$VAULT_TOKEN
expected:
  return_code: 0
render_output: false
{% endvalidation %}

## Synchronize the Vault with the Keyring

Once the container is created, use the following command to sync the Keyring data from the HashiCorp Vault to the {{site.base_gateway}} Keyring.

{% control_plane_request %}
url: /keyring/vault/sync
method: POST
status_code: 204
display_headers: true
{% endcontrol_plane_request %}



## Validate

Check that the Keyring contains the key that we created in the HashiCorp Vault:

{% control_plane_request %}
url: /keyring/
status_code: 200
display_headers: true
{% endcontrol_plane_request %}


The response should contain the ID of the key we created:
```json
{
   "ids":[
      "8zgITLQh"
   ],
   "active":"8zgITLQh"
}
```