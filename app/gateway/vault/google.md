---
title: "Google Cloud Secret Manager vault"
layout: reference
content_type: reference
description: "Use Google Cloud Secret Manager to store and reference secrets in {{site.base_gateway}}."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/google/

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
  - gcp-vault

min_version:
  gateway: '3.4'

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
      - gcp-vault
    description: true
    view_more: false
---

You can set up a [Google Cloud Secret Manager](https://cloud.google.com/secret-manager) vault in one of the following ways:

{% include_cached /gateway/vault-provider-intro.md %}

## GCP Secret Manager authentication

To configure GCP Secret Manager, the `GCP_SERVICE_ACCOUNT` environment variable must be set to the JSON document referring to the [credentials for your service account](https://cloud.google.com/iam/docs/creating-managing-service-account-keys):

```sh
export GCP_SERVICE_ACCOUNT=$(cat gcp-project-c61f2411f321.json)
```

{{site.base_gateway}} uses the key to automatically authenticate with the GCP API and grant you access.

To use GCP Secret Manager with [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) on a GKE cluster, update your pod spec so that the service account is attached to the pod. For configuration information, read the [Workload Identity configuration documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to).

{:.info}
> Notes:
> * With Workload Identity, setting the `GCP_SERVICE_ACCOUNT` isn't necessary.
> * When using GCP Vault as a backend, make sure you have configured system as part of the [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate) configuration directive so that the SSL certificates used by the official GCP API can be trusted by Kong.

## Create a Google Cloud Secret Manager vault

The following example creates a `gcp` Vault entity:

{% entity_example %}
type: vault
data:
  name: gcp
  prefix: gcp-sm-vault
  description: Stored secrets in Secret Manager
  config:
    project_id: test-gateway-vault
{% endentity_example %}

## Vault configuration options

The following table lists the available configuration parameters for a GCP Secret Manager Vault:

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
  - field: Google Project ID
    parameter: |
      * **Vault entity:** `vaults.config.project_id`
      * **kong.conf parameter:** `vault_gcp_project_id`
      * **Environment variable:** `KONG_VAULT_GCP_PROJECT_ID`
    description: |
      The project ID from your Google API Console. You can find it by visiting your Google API Console and selecting "Manage all projects" in the projects list.
  - field: TTL
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_gcp_ttl`
      * **Environment variable:** `KONG_VAULT_GCP_TTL`
    description: |
      Time-to-live (in seconds) for a cached secret. A value of 0 (default) disables rotation. For non-zero values, use a minimum of 60 seconds.
  - field: Negative TTL
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_gcp_neg_ttl`
      * **Environment variable:** `KONG_VAULT_GCP_NEG_TTL`
    description: |
      Time-to-live (in seconds) for caching failed secret lookups. A value of 0 (default) disables negative caching. Kong will retry fetching the secret after `neg_ttl` expires.
  - field: Resurrect TTL
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_gcp_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_GCP_RESURRECT_TTL`
    description: |
      Time (in seconds) that secrets remain in use after expiration (`config.ttl` ends). Useful if the vault is unreachable or the secret is deleted but not yet replaced. Kong continues to retry for `resurrect_ttl` seconds before giving up. The default is 1e8 seconds (~3 years) to support uninterrupted service during outages.
  - field: |
      Base64 Decode <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.base64_decode`
      * **kong.conf parameter:** `vault_gcp_decode_base64`
      * **Environment variable:** `KONG_VAULT_GCP_DECODE_BASE64`
    description: Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}
<!--vale on-->

## Tutorials

{% how_to_list page.how_to_list.config %}