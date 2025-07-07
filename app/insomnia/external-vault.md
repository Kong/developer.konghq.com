---
title: External vault integration
description: 'Learn how to configure external vault integrations in Insomnia using AWS, GCP, Azure, and HashiCorp vault providers.'
content_type: reference
layout: reference
tier: enterprise
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
    url: /insomnia/storage/#local-vault
  - text: Storage options
    url: /insomnia/storage/
  - text: Git sync
    url: /insomnia/storage/#git-sync
min_version:
  insomnia: '11'
---

Insomnia supports integrating with external vault service providers to retrieve secret values automatically when sending requests.

You can configure vault integration from the Insomnia UI, in **Preferences > Cloud Credentials**, and in [Inso CLI](/inso-cli/), using environment variables.

Insomnia supports the following vault services:

- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager?hl=en)
- [HashiCorp Vault](https://developer.hashicorp.com/vault)
- [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault)

## AWS Secrets Manager

{% navtabs "type" %}

{% navtab "Insomnia UI" %}

1. Navigate to **Preferences > Cloud Credentials**.
1. Click **Add Credentials**, select **AWS**, and enter your temporary security credentials.
1. Open **AWS Secrets Manager** from the context menu.
1. Fill in the required fields:
   - Secret name
   - Secret version
   - Secret type
{% endnavtab %}

{% navtab "Inso CLI" %}
There are three options to authenticate to your AWS vault from Inso CLI:

- [Temporary security credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html):
  ```sh
  export INSOMNIA_AWS_TYPE='temporary'
  export INSOMNIA_AWS_ACCESSKEYID='YOUR AWS ACCESS KEY ID'
  export INSOMNIA_AWS_SECRETACCESSKEY='YOUR AWS ACCESS SECRET ACCESS KEY'
  export INSOMNIA_AWS_SESSIONTOKEN = 'YOUR AWS SESSION TOKEN'
  export INSOMNIA_AWS_REGION = 'YOUR AWS REGION'
  ```
- [Credentials file](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-files.html):
  ```sh
  export INSOMNIA_AWS_TYPE='file'
  export INSOMNIA_AWS_SECTION='SECTION NAME IN YOUR AWS CREDENTIALS FILE'
  export INSOMNIA_AWS_FILEPATH='PATH TO YOUR AWS CREDENTIALS FILE'
  export INSOMNIA_AWS_ENABLECACHE='BOOLEAN, ENABLES FILE CACHE IF SET TO TRUE'
  export INSOMNIA_AWS_REGION = 'YOUR AWS REGION'
  ```
- [SSO credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html):
  ```sh
  export INSOMNIA_AWS_TYPE='file'
  export INSOMNIA_AWS_SECTION='SECTION NAME IN YOUR AWS CREDENTIALS FILE'
  export INSOMNIA_AWS_CONFIGFILEPATH='PATH TO THE AWS CONFIG FILE'
  export INSOMNIA_AWS_FILEPATH='PATH TO YOUR AWS CREDENTIALS FILE'
  export INSOMNIA_AWS_ENABLECACHE='BOOLEAN, ENABLES FILE CACHE IF SET TO TRUE'
  export INSOMNIA_AWS_REGION = 'YOUR AWS REGION'
  ```

{:.info}
> The `INSOMNIA_AWS_CONFIGFILEPATH`, `INSOMNIA_AWS_FILEPATH`, and `INSOMNIA_AWS_ENABLECACHE` variables are optional. If they aren't provided, Insomnia will use the default AWS CLI values. 

{% endnavtab %}

{% endnavtabs %}

## GCP Secret Manager

{% navtabs "type" %}

{% navtab "Insomnia UI" %}

1. Navigate to **Preferences > Cloud Credentials**.
1. Click **Add Credentials**, select **GCP**, and upload your [service account key](https://cloud.google.com/iam/docs/keys-create-delete).
1. Open **GCP Secrets Manager** from the context menu.
1. Fill in the required fields:
   - Secret name
   - Secret version
{% endnavtab %}

{% navtab "Inso CLI" %}
```sh
export INSOMNIA_GCP_SERVICEACCOUNTKEYFILEPATH = 'GCP SERVICE ACCOUNT KEY FILE PATH'
```
{% endnavtab %}

{% endnavtabs %}

## HashiCorp Vault

{% navtabs "type" %}

{% navtab "Insomnia UI" %}

1. Navigate to **Preferences > Cloud Credentials**.
1. Click **Add Credentials**, select **HashiCorp**, and choose your environment:
    * For HashiCorp Cloud Platform, select **Cloud** and provide credentials using a [service principal](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal#create-a-service-principal) client ID and client secret.
    * For HashiCorp Vault Server, select **On-Premises** and choose an authentication method:
        * With [**AppRole**](https://developer.hashicorp.com/vault/docs/auth/approle), enter the server address, role ID, and secret ID.
        * With [**Token**](https://developer.hashicorp.com/vault/docs/auth/token), enter the server address and authentication token.

{% endnavtab %}

{% navtab "Inso CLI" %}
For HashiCorp, the environment variables to define for Inso CLI depend on the platform and authentication method:
- HashiCorp Cloud Platform
  ```sh
  export INSOMNIA_HASHICORP_TYPE = 'cloud'
  export INSOMNIA_HASHICORP_CLIENT_ID = 'HASHICORP SERVICE PRINCIPAL CLIENT ID'
  export INSOMNIA_HASHICORP_CLIENT_SECRET = 'HASHICORP SERVICE PRINCIPAL CLIENT SECRET'
  ```
- HashiCorp Vault Server
  - [AppRole authentication](https://developer.hashicorp.com/vault/docs/auth/approle):
    ```sh
    export INSOMNIA_HASHICORP_TYPE = 'onPrem'
    export INSOMNIA_HASHICORP_AUTHMETHOD = 'appRole'
    export INSOMNIA_HASHICORP_SERVERADDRESS = 'HASHICORP VAULT SERVER ADDRESS'
    export INSOMNIA_HASHICORP_ROLE_ID = 'HASHICORP VAULT SERVER APP ROLE ID'
    export INSOMNIA_HASHICORP_SECRET_ID = 'HASHICORP VAULT SERVER APP ROLE SECRET ID'
    ```
  - [Token authentication](https://developer.hashicorp.com/vault/docs/auth/token):
    ```sh
    export INSOMNIA_HASHICORP_TYPE = 'onPrem'
    export INSOMNIA_HASHICORP_AUTHMETHOD = 'token'
    export INSOMNIA_HASHICORP_SERVERADDRESS = 'HASHICORP VAULT SERVER ADDRESS'
    export INSOMNIA_HASHICORP_ACCESS_TOKEN = 'HASHICORP VAULT SERVER ACCESS TOKEN'
    ```
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