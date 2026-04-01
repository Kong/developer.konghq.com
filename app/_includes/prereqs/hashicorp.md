This how-to requires you to have a dev mode or self-managed HashiCorp Vault. The following instructions will guide you through configuring a HashiCorp Vault in dev mode with the resources you need to integrate it with {{site.base_gateway}}.

{:.warning}
> **Important:** This tutorial uses the literal `root` string as your token, which should only be used in testing and development environments.

1. In a terminal, start your Vault dev server with `root` as your token.

   ```sh
   docker run -d --name vault -p 8200:8200 -e 'VAULT_DEV_ROOT_TOKEN_ID=root' hashicorp/vault
   ```
2. Export the `VAULT_ADDR` and `VAULT_TOKEN`:

   ```sh
   export VAULT_ADDR="http://host.docker.internal:8200"
   export VAULT_TOKEN="root"
   export VAULT_HOST="host.docker.internal"
   ```