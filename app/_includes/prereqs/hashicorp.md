This how-to requires you to have a dev mode or self-managed HashiCorp Vault. The following instructions will guide you through configuring a HashiCorp Vault in dev mode with the resources you need to integrate it with {{site.base_gateway}}.

{:.warning}
> **Important:** This tutorial uses the literal `root` string as your token, which should only be used in testing and development environments.

1. [Install HashiCorp Vault](https://developer.hashicorp.com/vault/tutorials/get-started/install-binary#install-vault).
1. In a terminal, start your Vault dev server with `root` as your token.
   ```
   vault server -dev -dev-root-token-id root
   ```
1. In the output from the previous command, copy the `VAULT_ADDR` to export.
1. In a new terminal window, export your `VAULT_ADDR` as an environment variable.
1. Verify that your Vault is running correctly:
   ```
   vault status
   ```
1. Authenticate with Vault:
   ```
   vault login root
   ```
1. Verify that you are using the `v2` secrets engine:
   ```
   vault read sys/mounts/secret
   ```
   The `options` key should have the `map[version:2]` value.