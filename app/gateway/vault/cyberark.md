---
title: "CyberArk Secrets Manager vault"
layout: reference
content_type: reference
description: "Use CyberArk Secrets Manager (Conjur) to store and reference secrets in {{site.base_gateway}}."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/cyberark/

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
  - cyberark-conjur

min_version:
  gateway: '3.11'

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
      - cyberark-conjur
    description: true
    view_more: false
---

You can set up a [CyberArk Secrets Manager](https://www.cyberark.com/products/secrets-manager-enterprise/) (Conjur) vault in one of the following ways:

{% include_cached /gateway/vault-provider-intro.md %}

## Create a CyberArk Secrets Manager vault

The following example creates a `conjur` Vault entity:

<!--vale off-->
{% entity_example %}
type: vault
data:
  name: conjur
  description: Storing secrets in CyberArk Secrets Manager Vault
  prefix: conjur-vault
  config:
    endpoint_url: https://conjur.example.com
    account: example-account
    login: example-login
    auth_method: api_key
    api_key: example-key
{% endentity_example %}
<!--vale on-->

## Vault configuration options

The following table lists the available configuration parameters for a CyberArk Secrets Manager Vault:

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
      Endpoint URL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.endpoint_url`
      * **kong.conf parameter:** `vault_conjur_endpoint_url`
      * **Environment variable:** `KONG_VAULT_CONJUR_ENDPOINT_URL`
    description: |
      The CyberArk Secrets Manager backend URL to connect with. Accepts `http` or `https` protocols.
  - field: |
      Authentication method <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.auth_method`
      * **kong.conf parameter:** `vault_conjur_auth_method`
      * **Environment variable:** `KONG_VAULT_CONJUR_AUTH_METHOD`
    description: "Defines the authentication mechanism for connecting to the CyberArk Secrets Manager Vault service. Accepted value: `api_key`."
  - field: |
      Account <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.account`
      * **kong.conf parameter:** `vault_conjur_account`
      * **Environment variable:** `KONG_VAULT_CONJUR_ACCOUNT`
    description: The CyberArk Secrets Manager organization account name.
  - field: |
      Login <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.login`
      * **kong.conf parameter:** `vault_conjur_login`
      * **Environment variable:** `KONG_VAULT_CONJUR_LOGIN`
    description: The login name of the workload identity.
  - field: |
      API Key <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.api_key`
      * **kong.conf parameter:** `vault_conjur_api_key`
      * **Environment variable:** `KONG_VAULT_CONJUR_API_KEY`
    description: The API key of the workload identity.
  - field: |
      TTL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_conjur_ttl`
      * **Environment variable:** `KONG_VAULT_CONJUR_TTL`
    description: Time-to-live (in seconds) for a cached secret. A value of 0 (default) disables rotation. For non-zero values, use at least 60 seconds.
  - field: |
      Negative TTL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_conjur_neg_ttl`
      * **Environment variable:** `KONG_VAULT_CONJUR_NEG_TTL`
    description: |
      Time-to-live (in seconds) for caching failed secret lookups. A value of 0 (default) disables negative caching.
      Kong retries after `neg_ttl` expires.
  - field: |
      Resurrect TTL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_conjur_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_CONJUR_RESURRECT_TTL`
    description: |
      Duration (in seconds) that secrets remain usable after expiration (`config.ttl` is over).
      Useful when the vault is unreachable or a secret is deleted but not yet replaced.
      Kong continues retrying for `resurrect_ttl` seconds, then stops. The default is 1e8 seconds (~3 years).
{% endtable %}
<!--vale on-->

## Tutorials

{% how_to_list page.how_to_list.config %}