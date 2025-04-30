---
title: Configure a GCP Secret Manager Vault
description: "Configure GCP Secret Manager Vault with {{ site.kic_product_name }} and the KongVault CRD"
content_type: how_to

permalink: /kubernetes-ingress-controller/vault/gcp/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - /gateway/secrets-management/

min_version:
  kic: '3.1'

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I configure Hashicorp Vault with {{ site.kic_product_name }}?
  a: Create a `KongVault` CRD and then use the `vault://` reference in your plugin configuration

prereqs:
  enterprise: true
  kubernetes:
    skip_proxy_ip: true
    gateway_env:
      LUA_SSL_TRUSTED_CERTIFICATE: system
    gateway_custom_env:
      GCP_SERVICE_ACCOUNT: $GCP_SERVICE_ACCOUNT
  inline:
    - title: Google Cloud Secret Manager
      position: before
      content: |
        To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must configure the following:

        1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
        2. On the [Secret Manager page](https://console.cloud.google.com/security/secret-manager), create a secret called `test-secret` with the following content:
            ```json
            secret
            ```
        3. Create a service account key and grant IAM permissions:
            1. In the [Service Account settings](https://console.cloud.google.com/iam-admin/serviceaccounts), click the `test-gateway-vault` project and then click the email address of the service account that you want to create a key for.
            2. From the Keys tab, create a new key from the add key menu and select JSON for the key type.
            3. Save the JSON file you downloaded.
            4. From the [IAM & Admin settings](https://console.cloud.google.com/iam-admin/), click the edit icon next to the service account to grant access to the [`Secret Manager Secret Accessor` role for your service account](https://cloud.google.com/secret-manager/docs/access-secret-version#required_roles).
      icon_url: /assets/icons/google-cloud.svg
    - title: Environment variables
      position: before
      content: |
          Set the environment variables needed to authenticate to Google Cloud:
          ```sh
          export GCP_SERVICE_ACCOUNT=$(cat /path/to/file/service-account.json | jq -c)
          ```

          These values will be populated in `values.yaml` when installing {{ site.kic_product_name }}
      icon_url: /assets/icons/file.svg

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/

tags:
  - secrets-management
  - security
---


## Create a KongVault entity

{{ site.kic_product_name }} uses the `KongVault` entity to configure the connection to a Vault. As we're running Hashicorp Vault in `dev` mode, we can use the `root` token to access the Vault:

{% entity_example %}
type: vault
data:
  name: gcp
  prefix: gcp-vault
  description: Storing secrets in GCP Secrets Manager
  config:
    project_id: summit-demo-2022
{% endentity_example %}

We can now access secrets in this vault using the `vault://gcp-vault/$KEY` syntax. The `gcp-vault` prefix matches the `prefix` field in the `KongVault` resource.

## Validate your configuration

To validate that the secret was stored correctly in AWS Secrets Manager, you can call a secret from your vault using the `kong vault get` command within the Data Plane Pod.

{% validation vault-secret %}
secret: '{vault://gcp-vault/test-secret}'
value: 'ACME Inc.'
command: kubectl exec -n kong -it deployment/kong-gateway -c proxy --
{% endvalidation %}

If the vault was configured correctly, this command should return the value of the secret. You can use `{vault://gcp-vault/test-secret}` to reference the secret in any referenceable field.