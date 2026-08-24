---
title: "Kong Gateway: \"could not find cached values\" error with the environment variables vault backend"
content_type: support
description: "The \"could not find cached values\" error appears when a vault reference for the environment variables (`env`) vault backend can't resolve, often due to a mismatched `KONG_VAULT_ENV_PREFIX` or a lowercase environment variable name."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Store secrets as environment variables
    url: /gateway/entities/vault/#store-secrets-as-environment-variables
  - text: Secrets management referenceable fields
    url: /gateway/secrets-management/
  - text: How do I reference secrets stored in a vault?
    url: /gateway/entities/vault/#how-do-i-reference-secrets-stored-in-a-vault
tldr:
  q: How do I fix the "could not find cached values" error when using the environment variables vault backend?
  a: |
    The `env` vault backend requires the referenced environment variable name to be uppercase, and if `KONG_VAULT_ENV_PREFIX` is set, the vault's `config.prefix` must match it exactly. A lowercase variable name or a mismatched prefix causes Kong Gateway to log a `could not find cached values` error instead of resolving the secret. Use `kong vault get <vault name>/<variable>` from inside the Kong container to verify the reference resolves.
---

## Problem

When referencing a secret from the environment variables vault backend with a configured prefix, {{site.base_gateway}} logs a `could not find cached values` error instead of resolving the value.

```

2024/03/07 16:47:52 [notice] 2307#0: *69496 [kong] vault.lua:708 error updating secret reference {vault://env/clientsecret}: could not find cached values, client: 172.28.0.1, server: kong, request: "GET /check HTTP/1.1", host: "localhost:48000"
```

## Solution

There are different kinds of vault backends, one of which is environment variables.

When using this, we would reference the variable to be used, as an environment variable in the Kong configuration file and then the reference will be able to pick it up when executing the plugin.

Things to check:

1. The environment variable in the docker file should have these added: The variables that would be referenced with the vault and if you are using an environment variable prefix, then `KONG_VAULT_ENV_PREFIX` should be added. In my example below, my `KONG_VAULT_ENV_PREFIX=MY_` and hence all the variables that I want this vault to reference will also have this prefix:

```bash
-e "MY_CLIENTID=<Clientid>" \

-e "KONG_VAULT_ENV_PREFIX=MY_" \

-e "MY_CLIENTSECRET=<clientsecret>" \
```

2. Note that these environment variables should be specified in upper case. If specified in lower case, then they are not valid. More on this can be found here.

3. Vault configuration: The name of the vault is: `my-env-vault`, type: `env`, `config.prefix="MY_"`. The `config.prefix` advanced setting should match the env variable: `KONG_VAULT_ENV_PREFIX`

4. Check from inside Kong container if the reference is right. For this exec into the Kong container and execute the following command to view env variables and make sure the variables you created are showing up:

```bash
printenv | sort
```

Execute the below command to know if from Kong container, we are able to reference these variables through vault parameters:

```bash
kong vault get <Vault name/prefix>/environment_variable 
Eg: kong vault get my-env-vault/clientsecret
```

Note that the prefix (`MY_`) is not added here to the env variable name. If we add them (`my_clientid`) and check, we will get the error found here:

5. You could then reference as shown below in any of the supported referenceable fields in the plugin.

Here I am referencing these in the OIDC plugin `clientid` and `clientsecret` fields.

Syntax:

```
{vault://<vault name/prefix/<env variable name>}
```

I am getting redirected to the IDP since the client ID and secret is valid:
