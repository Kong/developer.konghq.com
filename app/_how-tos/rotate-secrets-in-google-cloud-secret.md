---
title: Store and rotate Mistral API keys as secrets in Google Cloud Secret with {{site.base_gateway}} and the AI Proxy plugin
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
  - ai-proxy

entities: 
  - vault
  - service
  - route

tags:
    - security
    - secrets-management

tldr:
    q: How do I rotate secrets in Google Cloud Secret with {{site.base_gateway}}?
    a: placeholder

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
  inline:
    - title: Google Cloud Secret Manager
      position: before
      content: |
        To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must create a project, service account key, and grant IAM permissions. This tutorial also uses gcloud, so you need to install and configure that.
          1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
          1. In the [Service Account settings](https://console.cloud.google.com/iam-admin/serviceaccounts), click the `test-gateway-vault` project and then click the email address of the service account that you want to create a key for.
          1. From the Keys tab, create a new key from the add key menu and select JSON for the key type.
          1. Save the JSON file you downloaded.
          1. From the [IAM & Admin settings](https://console.cloud.google.com/iam-admin/), click the edit icon next to the service account to grant access to the [`Secret Manager Secret Accessor` role for your service account](https://cloud.google.com/secret-manager/docs/access-secret-version#required_roles).
          1. [Install gcloud](https://cloud.google.com/sdk/docs/install).
          1. Authenticate with gcloud and set your project to `test-gateway-vault`:
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
          export MISTRAL_API_KEY="Bearer <Mistral-API-key>"
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

## 1. Add an invalid API key as a secret in Google Cloud Secret Manager

In this tutorial, first we'll create a secret with an invalid API key in Google Cloud Secret Manager. Later, we'll add the correct API key as another secret version, but this allows us to test if {{site.base_gateway}} picks up the rotated secret correctly.

Create a secret called `test-secret` and then create a new secret version with the secret value of `Bearer invalid`:

```bash
gcloud secrets create test-secret \
    --replication-policy="automatic"

echo -n "Bearer invalid" | \
      gcloud secrets versions add test-secret --data-file=-
```

The first command is supported on Linux, macOS, and Cloud Shell. For other distributions, see [Create a secret](https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets#create-a-secret) in Google Cloud documentation.

## 2. Configure Secret Manager as a vault with the Vault entity

To enable Secret Manager as your vault in {{site.base_gateway}}, you can use the [Vault entity](/gateway/entities/vault/).

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

## 3. Enable the AI Proxy plugin

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

## 4. Validate that {{site.base_gateway}} uses the invalid API key from the secret

First, let's validate that the secret was stored correctly in Google Cloud by calling a secret from your vault using the `kong vault get` command within the data plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

Since {{site.konnect_short_name}} data plane container names can vary, set your container name as an environment variable:
{: data-deployment-topology="konnect" }
```sh
export KONNECT_DP_CONTAINER='your-dp-container-name'
```
{: data-deployment-topology="konnect" }

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

## 5. Rotate the secret in Secret Manager

We can now rotate the secret with the correct API key from Mistral. You can rotate a secret by creating a new secret version with the new secret value. {{site.base_gateway}} will fetch the new secret value based on the `ttl` setting we configured in the Vault entity.

Rotate the secret with the valid Mistral API key:

```bash
echo -n "$MISTRAL_API_KEY" | \
    gcloud secrets versions add test-secret --data-file=-
```

## 6. Validate that {{site.base_gateway}} uses the valid API key from the rotated secret

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