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
  - secrets-management
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

faqs:
  - q: What happens if I clear cloud credentials when I sign out of Insomnia?
    a: | 
      When you sign out of Insomnia, you can choose to clear all of your stored cloud credentials. This removes any saved credentials used by External Vault providers from your local Insomnia configuration.

      Clearing cloud credentials doesn't break External Vault integrations. Insomnia supports External Vault providers even when credential fields are empty. This allows you to sign out securely without losing your vault setup.

      After signing back in, you might need to re-authenticate or provide credentials again, depending on how the cloud provider handles authentication.
  - q: Do empty credential configurations work across all External Vault cloud providers?
    a: | 
      Yes. External Vault supports empty credential configurations across all supported cloud providers.

      This means that your external vault integrations continue to work even when credential fields are empty. Insomnia can operate without permanently storing cloud credentials in the configuration.
---

Insomnia supports integrating with external vault service providers to retrieve secret values automatically when sending requests.

You can configure vault integration from the Insomnia UI, in **Preferences > Credentials**, and in [Inso CLI](/inso-cli/), using environment variables.

Insomnia supports the following vault services:

- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager?hl=en)
- [HashiCorp Vault](https://developer.hashicorp.com/vault)
- [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault)

## AWS Secrets Manager

{% navtabs "type" %}

{% navtab "Insomnia UI" %}

1. Navigate to **Preferences > Credentials** {% new_in 12.3 %} or **Cloud Credentials**.
1. For Service Provider Credential List, click **Add Credentials**.
1. Select **AWS**.
1. Select a **Credential Type** and fill in the required fields.
    
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

{:.warning}
> Insomnia doesn't support spaces in the [SSO session name](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html#cli-configure-sso-configure). If you select the **SSO Credential** type, make sure your SSO session name contains only supported characters:
* Letters
* Numbers
* Hyphens (`-`)
* Underscores (`_`)

## GCP Secret Manager

{% navtabs "type" %}

{% navtab "Insomnia UI" %}

1. Navigate to **Preferences > Credentials** {% new_in 12.3 %} or **Cloud Credentials**.
1. For Service Provider Credential List, click **Add Credentials**.
1. Select **GCP**, and upload your [service account key](https://cloud.google.com/iam/docs/keys-create-delete).
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

1. Navigate to **Preferences > Credentials** {% new_in 12.3 %} or **Cloud Credentials**.
1. For Service Provider Credential List, click **Add Credentials**.
1. Select **HashiCorp**.
1. Choose your environment:
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

When you connect Insomnia to Azure Key Vault, Azure prompts for OAuth consent in a browser. The requested scopes define the permissions Insomnia uses to authenticate and access secrets.

Use the following required scopes:
- `openid`: Support sign-in with Microsoft Entra ID.
- `profile`: Provide basic account information that's required for authentication.
- `offline_access`: Allow authentication to persist without repeated sign-in.
- `user_impersonation`: Grant delegated access to Azure Key Vault and allow secret retrieval using the signed-in user’s existing permissions.

Azure enforces these permissions during consent and applies Key Vault access control based on the user’s assigned roles. For more information about required scopes, go to [Scopes and permissions](https://learn.microsoft.com/en-us/entra/identity-platform/scopes-oidc).

To choose Azure Key Vault:
1. In the Insomnia app, from your account settings, click **Preferences**.
1. Click the **Cloud Credentials** tab.
1. Click **Add Credentials**.
1. Click **Azure**.
1. You will be redirected to authorize Insomnia in your browser.
1. After authorization, you'll return to Insomnia with your Azure account credential added.

{:.info}
> Azure Key Vault access uses delegated permissions. The Azure account that you sign in with in Insomnia, the Azure app registration, and the Azure Key Vault must belong to the same Azure organization, unless cross-organization access is explicitly configured in Azure. If these are in different organizations, Azure can deny access even when the correct scopes are granted.


## Using secrets

External vault secrets can be referenced anywhere in Insomnia requests using [template tags](/insomnia/template-tags/). In the field of your choice:
1. Press `Control+Space`.
1. Select the external vault to use.
1. Fill in the details required to access the secret.

## Vault secrets cache

Vault secret caching works like the following in Insomnia:
- Secrets retrieved from cloud vault services are cached in memory for 30 minutes by default.
- If the cache expires or is missing, Insomnia re-fetches the secret automatically.
- You can configure cache duration and reset the cache in **Preferences > Credentials**.