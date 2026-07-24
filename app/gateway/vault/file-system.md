---
title: "File system vault"
layout: reference
content_type: reference
description: "Use the local file system on the {{site.base_gateway}} data plane to store and reference secrets."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/file-system/

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
  - file-system-vault

min_version:
  gateway: '3.15'

related_resources:
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
  - text: "Supported {{site.base_gateway}} Vault backends"
    url: /gateway/entities/vault/#supported-vault-backends
  - text: Secrets management
    url: /gateway/secrets-management/

how_to_list:
  config:
    products:
      - gateway
    tags:
      - file-system-vault
    description: true
    view_more: false
---

The file system vault reads secrets from files on the {{site.base_gateway}} data plane's local filesystem.
This vault type doesn't require any external services or credentials.

{% include_cached /gateway/file-system-vault-cloud-unsupported.md %}

Secrets can be plain text files or JSON files. Set `vaults.config.prefix` to the directory containing your secret files, then reference secrets relative to that directory:

<!--vale off-->
{% table %}
columns:
  - title: Format
    key: format
  - title: Example
    key: example
  - title: Reference format
    key: reference
rows:
  - format: "JSON file (multiple secrets)"
    example: |
      ```json
      {
        "client_id": "abc",
        "client_secret": "test123",
        "issuer": "https://your-idp/oauth"
      }
      ```
    reference: "`{vault://VAULT_PREFIX/filename.json/key}`"
  - format: "Plain text file (single secret)"
    example: |
      ```
      abc
      ```
    reference: "`{vault://VAULT_PREFIX/filename.txt}`"
{% endtable %}
<!--vale on-->

## Create a file system vault

The following example creates an `fs` Vault entity that looks for secrets in the directory `/tmp/kong/secrets`:

<!--vale off-->
{% entity_example %}
type: vault
data:
  name: fs
  prefix: fs-vault
  description: Storing secrets in local files
  config:
    prefix: "/tmp/kong/secrets"
{% endentity_example %}
<!--vale on-->

## Vault configuration options

The following table lists the available configuration parameters for a file system vault:

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
  - field: |
      Prefix <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.prefix`
      * **kong.conf parameter:** `vault_fs_prefix`
      * **Environment variable:** `KONG_VAULT_FS_PREFIX`
    description: |
      **Required.** The path to the directory containing the secret files. For example, `/tmp/kong/secrets`. All secrets will be read from this directory.
  - field: |
      TTL <br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_fs_ttl`
      * **Environment variable:** `KONG_VAULT_FS_TTL`
    description: |
      The time-to-live (in seconds) for cached secrets. A value of 0 (default) disables rotation. If non-zero, use at least 60 seconds.
  - field: |
      Negative TTL<br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_fs_neg_ttl`
      * **Environment variable:** `KONG_VAULT_FS_NEG_TTL`
    description: |
      The TTL (in seconds) for caching failed secret lookups (file not found or unreadable). If not set, uses the `ttl` value. A value of 0 disables negative caching.
  - field: |
      Resurrect TTL<br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_fs_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_FS_RESURRECT_TTL`
    description: |
      The duration (in seconds) for which expired secrets will continue to be used if the file is unreadable or missing. After this time, Kong stops retrying. The default is 1e8 seconds (~3 years).
  - field: |
      Base64 Decode<br>{% new_in 3.15 %}
    parameter: |
      * **Vault entity:** `vaults.config.base64_decode`
      * **kong.conf parameter:** `vault_fs_decode_base64`
      * **Environment variable:** `KONG_VAULT_FS_DECODE_BASE64`
    description: |
      Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}
<!--vale on-->

## Tutorials

{% how_to_list page.how_to_list.config %}