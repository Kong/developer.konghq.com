---
title: "Environment variable vault"
layout: reference
content_type: reference
description: "Use environment variables on the {{site.base_gateway}} data plane to store and reference secrets."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/environment-variable/

works_on:
  - on-prem
  - konnect

products:
  - gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - secrets-management

related_resources:
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
  - text: "Supported {{site.base_gateway}} Vault backends"
    url: /gateway/entities/vault/#supported-vault-backends
  - text: Secrets management
    url: /gateway/secrets-management/
---

The environment variable vault is built into {{site.base_gateway}} and doesn't require any external services.
You can store secrets as environment variables on the data plane and reference them in any field that supports Vault references.

You can set up an environment variable vault in one of the following ways:
* Using the [Vault entity](/gateway/entities/vault/)
* Using [environment variables](/gateway/manage-kong-conf/#environment-variables), set at {{site.base_gateway}} startup
* Using parameters in [`kong.conf`](/gateway/configuration/), set at {{site.base_gateway}} startup

The Vault entity can only be used once the database is initialized.
Secrets for values that are used before the database is initialized can't make use of the Vaults entity.

## Create an environment variable vault

The following example creates an `env` Vault entity:

{% entity_example %}
type: vault
data:
  name: env
  prefix: env-vault
  description: Storing secrets in environment variables
  config:
    prefix: example-prefix
{% endentity_example %}

## Vault configuration options

<!--vale off-->
{% table %}
columns:
  - title: Field name
    key: field
  - title: Parameter format
    key: parameter
  - title: Description
    key: description
rows:
  - field: Environment Variable Prefix
    parameter: |
      * **Vault entity:** `vaults.config.prefix`
      * **kong.conf parameter:** `vault_env_prefix`
      * **Environment variable:** `KONG_VAULT_ENV_PREFIX`
    description: The prefix for the environment variable that the value will be stored in.
  - field: Base64 Decode <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.base64_decode`
      * **kong.conf parameter:** `vault_env_decode_base64`
      * **Environment variable:** `KONG_VAULT_ENV_DECODE_BASE64`
    description: Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}
<!--vale on-->
