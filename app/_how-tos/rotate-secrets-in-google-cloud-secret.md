---
title: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Configure Google Cloud Secret as a vault backend
    url: /how-to/configure-google-cloud-secret-as-a-vault-backend/
  - text: Secret management
    url: /gateway/secrets-management/

products:
    - gateway

tier: enterprise

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I 
    a: placeholder

tools:
    - deck


prereqs:
  gateway:
    - name: GCP_SERVICE_ACCOUNT
  inline:
    - title: Google Cloud Secret Manager
      position: before
      content: |
        To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must create a project, service account key, and grant IAM permissions:
          1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
          1. In the [Service Account settings](https://console.cloud.google.com/iam-admin/serviceaccounts), click the `test-gateway-vault` project and then click the email address of the service account that you want to create a key for.
          1. From the Keys tab, create a new key from the add key menu and select JSON for the key type.
          1. Save the JSON file you downloaded.
          1. From the [IAM & Admin settings](https://console.cloud.google.com/iam-admin/), click the edit icon next to the service account to grant access to the [`Secret Manager Secret Accessor` role for your service account](https://cloud.google.com/secret-manager/docs/access-secret-version#required_roles).
      icon_url: /assets/icons/google-cloud.svg
    - title: Environment variables
      position: before
      content: |
          Set the environment variables needed to authenticate to Google Cloud:
          ```sh
          export GCP_SERVICE_ACCOUNT=$(cat /path/to/file/service-account.json)
          ```

          Note that both variables need to be passed when creating your data plane container.
      icon_url: /assets/icons/file.svg

faqs:
  - q: "How do I fix the `Error: could not get value from external vault (no value found (unable to retrieve secret from gcp secret manager (code : 403, status: PERMISSION_DENIED)))` error when I try to use my secret from the Google Cloud vault?"
    a: Verify that your [Google Cloud service account has the `Secret Manager Secret Accessor` role](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project). This role is required for {{site.base_gateway}} to access secrets in the vault.

cleanup:
  inline:
    - title: Google Cloud resources
      include_content: cleanup/third-party/google-cloud
      icon_url: /assets/icons/google-cloud.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Add a secret to Google Cloud Secret Manager

On the [Secret Manager page](https://console.cloud.google.com/security/secret-manager), create a secret called `test-secret` with the following JSON content:

```json
secret
```

## Configure Secret Manager as a vault with the Vault entity

To enable Secret Manager as your vault in {{site.base_gateway}}, you can use the [Vault entity](/gateway/entities/vault/).

First, we'll configure a Vault *without* a time-to-live (`ttl`) configuration to verify that {{site.base_gateway}} can correctly retrieve the secret.

{% entity_examples %}
entities:
  vaults:
    - name: gcp
      description: Stored secrets in Secret Manager
      prefix: gcp-sm-vault
      config:
        project_id: test-gateway-vault
{% endentity_examples %}

## 2. Validate

Now let's validate that the secret was stored correctly:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://gcp-sm-vault/test-secret}
```

If the vault was configured correctly, this command should return the value of the secret.

## Configure secret rotation in Google Cloud 

Move to prereqs
```
gcloud auth login
gcloud config set project test-gateway-vault

gcloud secrets update test-secret \
  --next-rotation-time "$(date -u -d '+5 minutes' +'%Y-%m-%dT%H:%M:%SZ')"
```

https://cloud.google.com/sdk/gcloud/reference/topic/datetimes

## 1. Configure Secret Manager as a vault with the Vault entity

Now, let's update our Vault configuration with the `ttl` value.

In this tutorial, we are configuring the time-to-live (`ttl`) as 60 seconds/1 minute. This tells {{site.base_gateway}} to check every minute with Google Cloud to get the rotated secret. We've configured this value so low so that we can quickly validate that the secret rotation is functioning as expected.

{% entity_examples %}
entities:
  vaults:
    - name: gcp
      description: Stored secrets in Secret Manager
      prefix: gcp-sm-vault
      config:
        project_id: test-gateway-vault
        ttl: 60
{% endentity_examples %}

## 2. Validate

To validate that the secret was stored correctly in Google Cloud, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://gcp-sm-vault/test-secret}
```

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://gcp-sm-vault/test-secret}` to reference the secret in any referenceable field.