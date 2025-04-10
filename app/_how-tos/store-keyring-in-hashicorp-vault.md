---
title: Store Keyring data in a HashiCorp Vault
content_type: how_to
related_resources:
  - text: Keyring
    url: /gateway/keyring/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/

products:
    - gateway

works_on:
    - on-prem
    - konnect

tldr:
    q: How do I store Keyring data in a HashiCorp vault?
    a: Create a HashiCorp Vault and add a key and ID, then set the `kong_keyring_strategy` kong.conf parameter to `vault` and the required `keyring_vault_*` parameters in your configuration, either in `kong.conf` or with environment variables. Use the `/keyring/vault/sync` API to synchronize.

prereqs:
  skip_product: true
  inline: 
    - title: HashiCorp Vault
      content: |
        This how-to requires you to have a dev mode or self-managed HashiCorp Vault. The following instructions will guide you through configuring a HashiCorp Vault in dev mode with the resources you need to integrate it with {{site.base_gateway}}.

        {:.warning}
        > **Important:** This tutorial uses the literal `root` string as your token, which should only be used in testing and development environments.

        1. [Install HashiCorp Vault](https://developer.hashicorp.com/vault/tutorials/get-started/install-binary#install-vault).
        2. In a terminal, start your Vault dev server with `root` as your token.
          ```
          vault server -dev -dev-root-token-id root
          ```
        3. In the output from the previous command, copy the `VAULT_ADDR` to export.
        4. In a new terminal window, export your `VAULT_ADDR` as an environment variable.
        5. Verify that your Vault is running correctly:
          ```
          vault status
          ```
        6. Authenticate with Vault:
          ```
          vault login root
          ```
        7. [Create the `admin-policy.hcl` policy file](https://developer.hashicorp.com/vault/tutorials/policies/policies#write-a-policy). This contains the [permissions you need to create and use secrets](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv#policy-requirements).
        8. Upload the policy you just created:
          ```
          vault policy write admin admin-policy.hcl
          ```
        9. [Verify that you are using the `v2` secrets engine](https://developer.hashicorp.com/vault/tutorials/secrets-management/versioned-kv?variants=vault-deploy%3Aselfhosted#check-the-kv-secrets-engine-version):
          ```
          vault read sys/mounts/secret
          ```
          The `options` key should have the `map[version:2]` value.
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

## 1. Create a key in the HashiCorp vault

The Keyring integration with HashiCorp Vaults allows you to store and version Keyring data. {{site.base_gateway}} nodes can read the keys directly from the vault to encrypt and decrypt sensitive data. 

First, we need to add a key and key ID to the vault. Let's create a secret named `keyring`:
```sh
vault kv put -mount secret keyring id="8zgITLQh" key="t6NWgbj3g9cbNVC3/D6oZ2Md1Br5gWtRrqb1T2FZy44="
```

## 2. Set environment variables

Set the environment variables that will be used by {{site.base_gateway}} to enable the Keyring and connect it to the HashiCorp Vault. Since the Keyring feature requires a {{site.ee_product_name}} license, make sure to include it in the environment too.
```sh
export KONG_LICENSE_DATA="<license-contents-go-here>"
export KONG_KEYRING_ENABLED="on"
export KONG_KEYRING_STRATEGY="vault"
export KONG_KEYRING_VAULT_HOST="http://host.docker.internal:8200"
export KONG_KEYRING_VAULT_MOUNT="secret"
export KONG_KEYRING_VAULT_PATH="keyring"
export KONG_KEYRING_VAULT_AUTH_METHOD="token"
export KONG_KEYRING_VAULT_TOKEN="root"
```

## 3. Start {{site.base_gateway}}

Create the {{site.base_gateway}} container with the environment variables. In this example, we can use the quickstart:
```sh
curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA \
    -e KONG_KEYRING_ENABLED \
    -e KONG_KEYRING_STRATEGY \
    -e KONG_KEYRING_VAULT_HOST \
    -e KONG_KEYRING_VAULT_MOUNT  \
    -e KONG_KEYRING_VAULT_PATH \
    -e KONG_KEYRING_VAULT_AUTH_METHOD  \
    -e KONG_KEYRING_VAULT_TOKEN
```

## 4. Synchronize the vault with the Keyring

Once the container is created, use the following command to sync the keyring data from the HashiCorp Vault to the {{site.base_gateway}} Keyring.
```sh
curl -i -X POST http://localhost:8001/keyring/vault/sync
```

## 5. Validate

Check that the Keyring contains the key that we created in the HashiCorp Vault:
```sh
curl -i http://localhost:8001/keyring
```

The response should contain the ID of the key we created:
```json
{
   "ids":[
      "8zgITLQh"
   ],
   "active":"8zgITLQh"
}
```