---
title: External vault integration
description: 'Learn how to configure external vault integrations in Insomnia using AWS, GCP, Azure, and HashiCorp vault providers.'
content_type: reference
layout: reference
products:
  - insomnia
tags:
  - external-vaults
  - secret-management
breadcrumbs:
  - /insomnia/
search_aliases:
  - Amazon
  - GCP
  - HCV
related_resources:
  - text: Local vault storage in Insomnia
    url: /insomnia/local-vault/
  - text: Storage options
    url: /insomnia/storage-options/
  - text: Git sync
    url: /insomnia/git-sync/
---



Insomnia supports integrating with external vault service providers to retrieve secret values automatically when sending requests.

Supported vault services:

- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager?hl=en)
- [HashiCorp Vault](https://developer.hashicorp.com/vault)
- [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault)

## AWS Secrets Manager

1. Navigate to **Preferences > Cloud Credentials**.
1. Click **Add Credentials**, select **AWS**, and enter your temporary security credentials.
1. Open **AWS Secrets Manager** from the context menu.
1. Fill in the required fields:
   - Secret name
   - Secret version
   - Secret type

## GCP Secret Manager

1. Navigate to **Preferences > Cloud Credentials**.
1. Click **Add Credentials**, select **GCP**, and upload your [service account key](https://cloud.google.com/iam/docs/keys-create-delete).
1. Open **GCP Secrets Manager** from the context menu.
1. Fill in the required fields:
   - Secret name
   - Secret version

## HashiCorp Vault

1. Navigate to **Preferences > Cloud Credentials**.
1. Click **Add Credentials**, select **HashiCorp**, and choose your environment:

{% navtabs "hcv" %}
{% navtab "on-prem" %}

- Provide credentials using [AppRole](https://developer.hashicorp.com/vault/docs/auth/approle) or [Token](https://developer.hashicorp.com/vault/docs/auth/token).

{% endnavtab %}
{% navtab "Cloud" %}

Provide credentials using a [service principal](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal#create-a-service-principal) Client ID and Client Secret.

{% endnavtab %}
{% endnavtabs %}


Open **HashiCorp Vault** from the context menu and fill in the fields based on the environment:

{% navtabs "fields" %}
{% navtab "Cloud" %}

- Organization ID
- Project ID
- App name
- Version
- Secret name

{% endnavtab %}
{% navtab "Vault server" %}

- Choose secret engine version (v1 or v2)
- Fill in required secret values based on the selected engine

{% endnavtab %}
{% endnavtabs %}


## Azure Key Vault

1. Navigate to **Preferences > Cloud Credentials**.
1. Click **Add Credentials**, select **Azure**.
1. You will be redirected to authorize Insomnia in your browser.
1. After authorization, you'll return to Insomnia with your Azure account credential added.
1. Open **Azure Key Vault** from the context menu.
1. Enter the **Secret Identifier** for the secret you want to access.

## Vault secrets cache

Vault secret caching works like the following in Insomnia:
- Secrets retrieved from cloud vault services are cached in memory for 30 minutes by default.
- If the cache expires or is missing, Insomnia re-fetches the secret automatically.
- You can configure cache duration and reset the cache in **Preferences > Cloud Credentials**.