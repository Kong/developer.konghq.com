---
title: Vaults
content_type: reference
entities:
  - vault

description: |
  Vaults allow you to securely store and then reference secrets from within other entities,
  ensuring that secrets aren't visible in plaintext throughout the platform.

related_resources:
  - text: Secrets Management
    url: /gateway/secrets-management/
  - text: Create a custom vault backend
    url: /how-to/create-custom-vault/
  - text: Workspaces
    url: /gateway/entities/workspace/
  - text: RBAC
    url: /gateway/entities/rbac/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: Managing sensitive data with decK
    url: /deck/gateway/sensitive-data/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway/control-plane-resource-limits/
  - text: "Cloud provider integration support for {{site.ee_product_name}}"
    url: /gateway/cloud-provider-support-matrix/


faqs:
  - q: What types of fields can be used in Vaults?
    a: Vaults work with "referenceable" fields. All fields in `kong.conf` are referenceable and some fields within entities (for example, plugins, certificates) are also. Refer to the appropriate entity documentation to learn more.
  - q: Can Vaults be referenced during custom plugin development?
    a: Yes. The plugin development kit (PDK) offers a Vaults module (`kong.vault`) that can be used to resolve, parse, and verify Vault references.
  - q: What data types can I use when referencing a secret in a Vault?
    a: A secret reference points to a string value. No other data types are currently supported.
  - q: I have a secret with multiple versions, how do I specify an earlier version when I'm referencing the secret?
    a: |
      If you have a secret with multiple versions, you can access the current version or any previous version of the secret by specifying a version in the reference.

      In the following AWS example, `AWSCURRENT` refers to the latest secret version and `AWSPREVIOUS` refers to an older version:
      ```sh
      # For AWSCURRENT, not specifying version
      {vault://aws/secret-name/foo}

      # For AWSCURRENT, specifying version == 1
      {vault://aws/secret-name/foo#1}

      # For AWSPREVIOUS, specifying version == 2
      {vault://aws/secret-name/foo#2}
      ```
      This applies to all providers with versioned secrets.
  - q: My secret in AWS Secret Manager has a `/` backslash in the secret name. How do I reference this secret in {{site.base_gateway}}?
    a: |
      The slash symbol (`/`) is a valid character for the secret name in AWS Secrets Manager. If you want to reference a secret name that starts with a slash or has two consecutive slashes, transform one of the slashes in the name into URL-encoded format. For example:
      * A secret named `/secret/key` should be referenced as `{vault://aws/%2Fsecret/key}`
      * A secret named `secret/path//aaa/key` should be referenced as `{vault://aws/secret/path/%2Faaa/key}`
      
      Since {{site.base_gateway}} tries to resolve the secret reference as a valid URL, using a slash instead of a URL-encoded slash will result in unexpected secret name fetching.
  - q: I have secrets stored in multiple AWS Secret Manager regions, how do I reference those secrets in {{site.base_gateway}}?
    a: |
      You can create multiple Vault entities, one per region with the `config.region` parameter. You'd then reference the secret by the name of the Vault:
      ```sh
      {vault://aws-eu-central-vault/secret-name/foo}
      {vault://aws-us-west-vault/secret-name/snip}
      ```
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
  - q: How does {{site.base_gateway}} retrieve secrets from HashiCorp Vault?
    a: |
      {{site.base_gateway}} retrieves secrets from HashiCorp Vault's HTTP API through a two-step process: authentication and secret retrieval.

      **Step 1: Authentication**

      Depending on the authentication method defined in `config.auth_method`, {{site.base_gateway}} authenticates to HashiCorp Vault using one of the following methods:

      - If you're using the `token` auth method, {{site.base_gateway}} uses the `config.token` as the client token.
      - If you're using the `kubernetes` auth method, {{site.base_gateway}} uses the service account JWT token mounted in the pod (path defined in the `config.kube_api_token_file`) to call the login API for the Kubernetes auth path on the HashiCorp Vault server and retrieve a client token.
      - {% new_in 3.4 %} If you're using the `approle` auth method, {{site.base_gateway}} uses the AppRole credentials to retrieve a client token. The AppRole role ID is configured by field `config.approle_role_id`, and the secret ID is configured by field `config.approle_secret_id` or `config.approle_secret_id_file`. 
        - If you set `config.approle_response_wrapping` to `true`, then the secret ID configured by
        `config.approle_secret_id` or `config.approle_secret_id_file` will be a response wrapping token, 
        and {{site.base_gateway}} will call the unwrap API `/v1/sys/wrapping/unwrap` to unwrap the response wrapping token to fetch 
        the real secret ID. {{site.base_gateway}} will use the AppRole role ID and secret ID to call the login API for the AppRole auth path
        on the HashiCorp Vault server and retrieve a client token.
      - {% new_in 3.14 %} If you're using the `gcp_iam` auth method, {{site.base_gateway}} generates a signed JWT using the GCP service account configured in `config.gcp_service_account` and exchanges it for a HashiCorp Vault token via the GCP login path (`config.gcp_login_path`). The role is specified by `config.gcp_auth_role`.
      - {% new_in 3.14 %} If you're using the `gcp_gce` (GCP Compute Engine) auth method, {{site.base_gateway}} uses the instance identity token from the GCE metadata server and exchanges it for a HashiCorp Vault token via the GCP login path (`config.gcp_login_path`). The role is specified by `config.gcp_auth_role`.
      - {% new_in 3.14 %} If you're using the `azure` auth method, {{site.base_gateway}} uses the Azure Managed Identity token and exchanges it for a HashiCorp Vault token via the Azure login path (`config.azure_login_path`). The role is specified by `config.azure_auth_role`.
      - {% new_in 3.14 %} If you're using the `aws_ec2` auth method, {{site.base_gateway}} uses the EC2 instance identity document and a nonce (`config.aws_auth_nonce`) to authenticate with HashiCorp Vault via the AWS login path (`config.aws_login_path`). The role is specified by `config.aws_auth_role`.
      - {% new_in 3.14 %} If you're using the `aws_iam` auth method, {{site.base_gateway}} signs an AWS STS `GetCallerIdentity` request using IAM credentials (`config.aws_access_key_id` and `config.aws_secret_access_key`, or the default credential provider chain) and exchanges it for a HashiCorp Vault token via the AWS login path (`config.aws_login_path`). The role is specified by `config.aws_auth_role`.  For cross-account authentication, `config.aws_assume_role_arn` and `config.aws_role_session_name` are required to assume an IAM role in the target account before signing the request.
      
      By calling the login API, {{site.base_gateway}} will retrieve a client token and then use it in the next step as the value of `X-Vault-Token` header to retrieve a secret.

      **Step 2: Retrieving the secret**

      {{site.base_gateway}} uses the client token retrieved in the authentication step to call the Read Secret API and retrieve the secret value. The request varies depending on the secrets engine version you're using.
      {{site.base_gateway}} will parse the response of the read secret API automatically and return the secret value.
  - q: Can Azure Key Vault be used with a proxy?
    a: |
      {% new_in 3.12 %} Yes. Azure Key Vault supports proxy configuration using either environment variables or client constructor arguments.

      **Environment variables**

      ```sh
      export AZURE_HTTP_PROXY=http://proxy.example.com:8080
      export AZURE_HTTPS_PROXY=http://proxy.example.com:8080
      export AZURE_NO_PROXY=localhost,127.0.0.1,.local
      export AZURE_AUTH_USERNAME=proxyuser
      export AZURE_AUTH_PASSWORD=proxypass
      ```

      **Constructor arguments**

      ```lua
      local azure_client = require("resty.azure"):new({
        tenant_id = "tenant-uuid",
        client_id = "app-registration-client-id",
        client_secret = "app-registration-client-secret",
        http_proxy = "http://proxy.example.com:8080",
        https_proxy = "http://proxy.example.com:8080",
        no_proxy = "localhost,127.0.0.1,.local",
        auth_username = "proxyuser",
        auth_password = "proxypass",
      })
      ```

      {:.info}
      > **Notes:**
      > * Constructor arguments take precedence over environment variables.
      > * When `auth_username` and `auth_password` are provided, they will be automatically converted to a Basic authentication header for both HTTP and HTTPS proxy authorization.

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

schema:
    api: gateway/admin-ee
    path: /schemas/Vault

next_steps:
  - text: Set up a {{site.konnect_short_name}} Config Store
    url: /how-to/configure-the-konnect-config-store/
  - text: Set up HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Keyring
    url: /gateway/keyring/


works_on:
  - on-prem
  - konnect

tags:
  - secrets-management
---

## What is a Vault?

Vaults allow you to securely store and then reference secrets from within other entities. This ensures that secrets aren't visible in plaintext throughout the platform, in places such as `kong.conf`,
declarative configuration files, logs, or the UI.

For example, you could store a certificate and a key in a Vault, then reference them from a [Certificate entity](/gateway/entities/certificate/). This way, the certificate and key are not stored in the entity directly and are more secure.

## How do I add secrets to a Vault?

You can add secrets to Vaults in one of the following ways:
* Environment variables
* {{site.konnect_short_name}} Config Store
* Supported third-party backend vault

## What can be stored as a secret?

You can store and reference the following as secrets in a Vault:

* All [values](/gateway/manage-kong-conf/)<sup>1</sup> set in `kong.conf` are referenceable. For example:
  * Data store usernames and passwords, used with PostgreSQL and Redis
  * Private X.509 certificates
* Certificates and keys stored in the [Certificate {{site.base_gateway}} entity](/gateway/entities/certificate/)
* [{{site.base_gateway}} license](/gateway/entities/license/)<sup>2</sup>
* Referenceable plugin fields, such as third-party API keys (see table below for all values)

{:.info}
> **{{site.konnect_short_name}} Config Store limitations:**
> * <sup>1</sup>: You can't reference secrets stored in a [{{site.konnect_short_name}} Config Store](/how-to/configure-the-konnect-config-store/) Vault in `kong.conf` because {{site.konnect_short_name}} resolves the secret after {{site.base_gateway}} connects to the Control Plane. For this same reason, you can't use {{site.konnect_short_name}} Config Store secrets directly in Lua code via the Kong PDK, for example.
> * <sup>2</sup>: In {{site.konnect_short_name}}, the {{site.base_gateway}} license is managed and stored by {{site.konnect_short_name}}, and doesn't need to be stored manually in any Vault.

### Referenceable plugin fields

The following plugin fields can be stored and referenced as secrets:

{% referenceable_fields %}

## Supported Vault backends

Each vault has its own required configuration. You can provide this configuration by creating a Vault entity, or by configuring specific environment variables before starting {{ site.base_gateway }}.

For more information, choose a vault backend below.

{% feature_table %}
item_title: Backend
columns:
  - title: {{site.base_gateway}} OSS
    key: oss
  - title: {{site.ee_product_name}}
    key: enterprise
  - title: {{site.konnect_short_name}} supported
    key: supports_konnect
  - title: How-to guide
    key: how_to

features:
  - title: Environment variable
    url: /gateway/entities/vault/environment-variable/
    oss: true
    enterprise: true
    supports_konnect: true
    how_to: "--"
  - title: Konnect (Konnect Config Store)
    url: /gateway/entities/vault/konnect-config-store/
    oss: false
    enterprise: false
    supports_konnect: true
    how_to: |
      * [Basic setup](/how-to/configure-the-konnect-config-store/)
      * [Store Mistral keys in a Konnect Config Store](/how-to/store-a-mistral-api-key-as-a-secret-in-konnect-config-store/)
  - title: AWS Secrets Manager
    url: /gateway/entities/vault/aws/
    oss: false
    enterprise: true
    supports_konnect: true
    how_to: |
      * [Basic setup](/how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/)
  - title: Azure Key Vaults
    url: /gateway/entities/vault/azure/
    oss: false
    enterprise: true
    supports_konnect: true
    how_to: "--"
  - title: |
      Azure Key Vaults (Certificates) {% new_in 3.15 %}
    url: /gateway/entities/vault/azure-certs/
    oss: false
    enterprise: true
    supports_konnect: true
    how_to: "--"
  - title: Google Cloud Secret
    url: /gateway/entities/vault/google/
    oss: false
    enterprise: true
    supports_konnect: true
    how_to: |
      * [Basic setup](/how-to/configure-google-cloud-secret-as-a-vault-backend/)
  - title: HashiCorp Vault
    url: /gateway/entities/vault/hashicorp/
    oss: false
    enterprise: true
    supports_konnect: true
    how_to: |
      * [Basic setup](/how-to/configure-hashicorp-vault-as-a-vault-backend/)
      * [All how-to guides](/how-to/?tags=hashicorp-vault)
  - title: |
      CyberArk Secrets Manager (Conjur)  {% new_in 3.11 %}
    url: /gateway/entities/vault/cyberark/
    oss: false
    enterprise: true
    supports_konnect: true
    how_to: |
      * [Basic setup](/how-to/configure-cyberark-as-a-vault-backend/)
  - title: |
      File system {% new_in 3.15 %}
    url: /gateway/entities/vault/file-system/
    oss: false
    enterprise: true
    supports_konnect: true
    how_to: |
      * [Basic setup](/how-to/configure-file-system-as-a-vault-backend/)
  - title: Custom vault backend
    url: /how-to/create-custom-vault/
    oss: true
    enterprise: true
    supports_konnect: false
{% endfeature_table %}

## How do I reference secrets stored in a Vault?

When you want to use a secret stored in a Vault, you can reference the secret with a `vault` reference. You can use the `vault` reference in places such as `kong.conf`, declarative configuration files, logs, or in the UI.

The Vault backend may store multiple related secrets inside an object, but the reference
should always point to a key that resolves to a string value. For example, the following reference:

```
{vault://hcv/pg/username}
```

Would point to a secret object called `pg` inside a HashiCorp Vault, which may return the following value:

```json
{
  "username": "john",
  "password": "doe"
}
```

<!-- vale off -->
{{site.base_gateway}} receives the payload and extracts the `"username"` value of `"john"` for the secret reference of
`{vault://hcv/pg/username}`.
<!-- vale on -->

Vault references must be used for the whole referenced value. 
Imagine that you're calling a upstream service with the authentication token `ABC123`:

{% feature_table %}
item_title: Works
columns:
  - title: Configuration Value
    key: config
  - title: Vault Value
    key: vault
features:
  - title: No
    config: 'Bearer {vault://hcv/myservice-auth-token}'
    vault: ABC123
  - title: Yes
    config: '{vault://hcv/myservice-auth-token}'
    vault: Bearer ABC123
{% endfeature_table %}


{:.info}
>When using Vault references in plugin configs to **add headers**, ensure that the secret value stored in your Vault follows the **`key:value` format**. The entire header definition, both name and value, needs to be provided by the resolved secret.

{:.warning}
> Serverless plugins, like Pre-Function and Post-Function, are not supported with {{site.konnect_short_name}} Config Store Vaults.

## Secret rotation in Vaults

By default, {{site.base_gateway}} automatically refreshes secrets *once every minute* in the background. 
You can also configure how often {{site.base_gateway}} refreshes secrets using the Vault entity configuration.

There are two types of refresh configuration available:
* Refresh periodically using TTLs: For example, check for a new TLS certificate once per day.
* Refresh on failure: For example, on a database authentication failure, check if the secrets were updated, and try again.

For more information, see [Secret management](/gateway/secrets-management/).

## Store values as secrets

When you set up a Vault, each provider has specific parameters that you can or must configure to integrate the Vault with a provider. For the entire Vault configuration schema, see the [schema reference](#schema).

You can set up a Vault in one of the following ways:
* Using the Vault entity
* Using environment variables, set at {{site.base_gateway}} startup
* Using parameters in `kong.conf`, set at {{site.base_gateway}} startup

The Vault entity can only be used once the database is initialized. Secrets for values that are used before the database is initialized can’t make use of the Vaults entity.


### Set up a Vault entity

{% entity_example %}
type: vault
data:
  name: env
  description: ENV vault for secrets
  prefix: my-env-vault
  config:
    prefix: MY_SECRET_
{% endentity_example %}

### Store secrets as environment variables

You can store secrets as environment variables instead of configuring a Vault entity or third-party backend vault. 

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Environment variable example
    key: env_var_example
  - title: Secret reference example
    key: secret_ref_example
rows:
  - usecase: "Single secret value"
    env_var_example: |
      `export MY_SECRET_VALUE=example-secret`
    secret_ref_example: |
      `{vault://env/my-secret-value}`
  - usecase: "Multiple secrets (flat JSON string)"
    env_var_example: |
      `export PG_CREDS='{"username":"user", "password":"pass"}'`
    secret_ref_example: |
      `{vault://env/pg-creds/username}`
      <br><br>
      `{vault://env/pg-creds/password}`

{% endtable %}
<!--vale on-->

## Schema

{% entity_schema %}
