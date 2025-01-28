---
title: Configure Google Cloud Secret Manager as a Vault entity in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-google-cloud-secret/
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configure Google Cloud Secret Manager with Workload Identity in {{site.base_gateway}}
    url: /how-to/configure-google-cloud-secret-manager-with-workload-identity/

products:
    - gateway

tier: enterprise

works_on:
    - on-prem

min_version:
  gateway: '3.4'

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I use Google Cloud Secret Manager as a Vault in {{site.base_gateway}}?
    a: |
      Save a secret in [Google Cloud Secret Manager](https://console.cloud.google.com/security/secret-manager) and create a service account with the `Secret Manager Secret Accessor` role. Export your service account key JSON as an environment variable (`GCP_SERVICE_ACCOUNT`), set `lua_ssl_trusted_certificate=system` in your `kong.conf` file, then configure a Vault entity with your Secret Manager configuration. Reference secrets from your Secret Manager vault like the following: `{vault://gcp-sm-vault/test-secret}`

tools:
    - deck

prereqs:
  gateway:
    - name: GCP_SERVICE_ACCOUNT
    - name: KONG_LUA_SSL_TRUSTED_CERTIFICATE
  inline:
    - title: Google Cloud Secret Manager
      position: before
      content: |
        To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must configure the following:

        1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
        1. On the [Secret Manager page](https://console.cloud.google.com/security/secret-manager), create a secret called `test-secret` with the following JSON content:
            ```json
            secret
            ```
        1. Create a service account key:
            1. In the [Google Cloud console](https://console.cloud.google.com/), click the `test-gateway-vault` project.
            1. Click the email address of the service account that you want to create a key for.
            1. From the Keys tab, create a new key from the add key menu and select JSON for the key type.
            1. Save the JSON file you downloaded.
            1. From the [IAM page](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project), grant access to the [`Secret Manager Secret Accessor` role for your service account](https://cloud.google.com/secret-manager/docs/access-secret-version#required_roles).
      icon_url: /assets/icons/google-cloud.svg
    - title: Environment variables
      position: before
      content: |
          Set the environment variables needed to authenticate to Google Cloud:
          ```sh
          export GCP_SERVICE_ACCOUNT=$(cat /path/to/file/service-account.json)
          export KONG_LUA_SSL_TRUSTED_CERTIFICATE='system'
          ```

          Note that the both variables need to be passed when creating your Data Plane container.
      icon_url: /assets/icons/file.svg
cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Configure Secret Manager as a vault with the Vault entity

To enable Secret Manager as your vault in {{site.base_gateway}}, you can use the [Vault entity](/gateway/entities/vault).

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

To validate that the secret was stored correctly in Google Cloud, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. If the Docker container is named `kong-quickstart-gateway`, you can use the following command:

```sh
docker exec kong-quickstart-gateway kong vault get {vault://gcp-sm-vault/test-secret}
```

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://gcp-sm-vault/test-secret}` to reference the secret in any referenceable field.


    