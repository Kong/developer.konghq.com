---
title: Store and rotate Mistral API keys as secrets in Google Cloud
permalink: /how-to/rotate-secrets-in-google-cloud-secret/
content_type: how_to
related_resources:
  - text: Configure Google Cloud Secret as a vault backend
    url: /how-to/configure-google-cloud-secret-as-a-vault-backend/
  - text: Configure a GCP Secret Manager Vault with KIC
    url: /kubernetes-ingress-controller/vault/gcp/
  - text: Google Cloud Vault configuration parameters
    url: /gateway/entities/vault/?tab=google-cloud#vault-provider-specific-configuration-parameters
  - text: Secret management
    url: /gateway/secrets-management/
  - text: Google Secret Manager documentation
    url: https://cloud.google.com/secret-manager/docs
  - text: Mistral AI documentation
    url: https://docs.mistral.ai/
description: Learn how to store and rotate secrets in Google Cloud with {{site.base_gateway}}, Mistral, and the AI Proxy plugin.
products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - ai-proxy

entities:
  - vault
  - service
  - route

tags:
    - security
    - secrets-management
    - mistral

tldr:
    q: How do I rotate secrets in Google Cloud Secret with {{site.base_gateway}}?
    a: |
      Create a secret in [Google Cloud Secret Manager](https://console.cloud.google.com/security/secret-manager) and create a service account with the `Secret Manager Secret Accessor` role. Export your service account key JSON as an environment variable (`GCP_SERVICE_ACCOUNT`). Then configure a [Vault entity](/gateway/entities/vault/) with your Secret Manager configuration and `ttl` set to how many seconds {{site.base_gateway}} should wait before picking up the rotated secret. Reference secrets from your Secret Manager vault like the following in a referenceable field: `{vault://gcp-sm-vault/test-secret}`. Rotate your secret by creating a new secret version in Google Cloud.

tools:
    - deck


prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  gateway:
    - name: GCP_SERVICE_ACCOUNT
  konnect:
    - name: GCP_SERVICE_ACCOUNT
  inline:
    - title: Google Cloud Secret Manager
      position: before
      content: |
        To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must create a project, service account key, and grant IAM permissions. This tutorial also uses gcloud, so you need to install and configure that.
          1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
          2. In the <!--vale off-->[Service Account settings](https://console.cloud.google.com/iam-admin/serviceaccounts)<!--vale on-->, click the `test-gateway-vault` project and then click the email address of the service account that you want to create a key for.
          3. From the Keys tab, create a new key from the add key menu and select JSON for the key type.
          4. Save the JSON file you downloaded.
          5. From the [IAM & Admin settings](https://console.cloud.google.com/iam-admin/), click the edit icon next to the service account to grant access to the [`Secret Manager Secret Accessor` role for your service account](https://cloud.google.com/secret-manager/docs/access-secret-version#required_roles).
          6. [Install gcloud](https://cloud.google.com/sdk/docs/install).
          7. Authenticate with gcloud and set your project to `test-gateway-vault`:
             ```
             gcloud auth login
             gcloud config set project test-gateway-vault
             ```
      icon_url: /assets/icons/google-cloud.svg
    - title: Mistral AI API key
      position: before
      content: |
        In this tutorial, you'll be storing your Mistral AI API key as a secret in a {{site.konnect_short_name}} Vault.

        In the Mistral AI console, [create an API key](https://console.mistral.ai/api-keys/) and copy it. You'll add this API key as a secret to your vault.
      icon_url: /assets/icons/mistral.svg
    - title: Environment variables
      position: before
      content: |
          Set the environment variables needed to authenticate to Google Cloud:
          ```sh
          export GCP_SERVICE_ACCOUNT=$(cat /path/to/file/service-account.json)
          export MISTRAL_API_KEY="Bearer YOUR-MISTRAL-API-KEY"
          ```

          Note that the `GCP_SERVICE_ACCOUNT` variables **must** be passed when creating your data plane container.
      icon_url: /assets/icons/file.svg

faqs:
  - q: "How do I fix the `Error: could not get value from external vault (no value found (unable to retrieve secret from gcp secret manager (code : 403, status: PERMISSION_DENIED)))` error when I try to use my secret from the Google Cloud vault?"
    a: Verify that your [Google Cloud service account has the `Secret Manager Secret Accessor` role](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project). This role is required for {{site.base_gateway}} to access secrets in the vault.
  - q: I'm using Google Workload Identity, how do I configure a Vault?
    a: |
      To use GCP Secret Manager with
      [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
      on a GKE cluster, update your pod spec so that the service account (`GCP_SERVICE_ACCOUNT`) is
      attached to the pod. For configuration information, read the [Workload
      Identity configuration
      documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to).

      {:.info}
      > **Notes:**
      > * With Workload Identity, setting the `GCP_SERVICE_ACCOUNT` isn't necessary.
      > * When using GCP Vault as a backend, make sure you have configured `system` as part of the
      > [`lua_ssl_trusted_certificate` configuration directive](/gateway/configuration/#lua-ssl-trusted-certificate)
      so that the SSL certificates used by the official GCP API can be trusted by {{site.base_gateway}}.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Add an invalid API key as a secret in Google Cloud Secret Manager

In this tutorial, first we'll create a secret with an invalid API key in Google Cloud Secret Manager. Later, we'll add the correct API key as another secret version, but this allows us to test if {{site.base_gateway}} picks up the rotated secret correctly.

Create a secret called `test-secret` and then create a new secret version with the secret value of `Bearer invalid`:

```bash
gcloud secrets create test-secret \
    --replication-policy="automatic"

echo -n "Bearer invalid" | \
      gcloud secrets versions add test-secret --data-file=-
```

The first command is supported on Linux, macOS, and Cloud Shell. For other distributions, see [Create a secret](https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets#create-a-secret) in Google Cloud documentation.

## Configure Secret Manager as a vault with the Vault entity

To enable Secret Manager as your vault in {{site.base_gateway}}, you can use the [Vault entity](/gateway/entities/vault/).

In this tutorial, we are configuring the time-to-live (`ttl`) as 60 seconds/1 minute. This tells {{site.base_gateway}} to check every minute with Google Cloud to get the rotated secret. We've configured a low value so that we can quickly validate that the secret rotation is functioning as expected.

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

## Enable the AI Proxy plugin

In this tutorial, you'll use the Mistral API key you stored as a secret to generate an answer to a question using the [AI Proxy plugin](/plugins/ai-proxy/).

{% entity_examples %}
entities:
  plugins:
  - name: ai-proxy
    route: example-route
    config:
      route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: "{vault://gcp-sm-vault/test-secret}"
      model:
        provider: mistral
        name: mistral-tiny
        options:
          mistral_format: openai
          upstream_url: https://api.mistral.ai/v1/chat/completions
{% endentity_examples %}

## Validate that {{site.base_gateway}} uses the invalid API key from the secret

First, let's validate that the secret was stored correctly in Google Cloud by calling a secret from your vault using the `kong vault get` command within the Data Plane container.

{% validation vault-secret %}
secret: '{vault://gcp-sm-vault/test-secret}'
value: 'Bearer invalid'
{% endvalidation %}

If the vault was configured correctly, this command should return `Bearer invalid`.

Now, let's validate that when we make a call to the Route associated with the AI Proxy plugin, that it is using this invalid API key stored in our secret:

{% validation request-check %}
url: /anything
status_code: 401
message: Unauthorized
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}

You should get a `401` error with the message `Unauthorized` because we're currently using an invalid API key.

## Rotate the secret in Secret Manager

We can now rotate the secret with the correct API key from Mistral. You can rotate a secret by creating a new secret version with the new secret value. {{site.base_gateway}} will fetch the new secret value based on the `ttl` setting we configured in the Vault entity.

Rotate the secret with the valid Mistral API key:

```bash
echo -n "$MISTRAL_API_KEY" | \
    gcloud secrets versions add test-secret --data-file=-
```

## Validate that {{site.base_gateway}} uses the valid API key from the rotated secret

Now we can validate that {{site.base_gateway}} picks up the valid Mistral API key from the rotated secret. Since {{site.base_gateway}} is configured to pick up any rotated secrets every 60 seconds, the following command waits a minute before sending a request:

{% validation request-check %}
url: /anything
status_code: 200
method: POST
sleep: 60
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}

You should get a `200` error with an answer to the chat response because {{site.base_gateway}} picked up the rotated secret with the valid API key.