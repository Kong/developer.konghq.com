* Using the [Vault entity](/gateway/entities/vault/)
* Using [environment variables](/gateway/entities/vault/#store-secrets-as-environment-variables), set at {{site.base_gateway}} startup
* Using parameters in [`kong.conf`](/gateway/configuration/), set at {{site.base_gateway}} startup

The Vault entity can only be used once the database is initialized. 
Secrets for values that are used before the database is initialized can’t make use of the Vaults entity.