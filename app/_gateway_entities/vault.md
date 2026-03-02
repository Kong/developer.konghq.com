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

For more information, choose a Vault below to see the specific configuration required.

{% feature_table %}
item_title: Backend
columns:
  - title: {{site.base_gateway}} OSS
    key: oss
  - title: {{site.ee_product_name}}
    key: enterprise
  - title: {{site.konnect_short_name}} supported
    key: supports_konnect

features:
  - title: Environment variable
    url: /gateway/entities/vault/#store-secrets-as-environment-variables
    oss: true
    enterprise: true
    supports_konnect: true
  - title: Konnect (Konnect Config Store)
    url: /how-to/configure-the-konnect-config-store/
    oss: false
    enterprise: false
    supports_konnect: true
  - title: AWS Secrets Manager
    url: /how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/
    oss: false
    enterprise: true
    supports_konnect: true
  - title: Azure Key Vaults
    <!--url: /how-to/configure-azure-key-vaults-as-a-vault-backend-with-vault-entity/-->
    oss: false
    enterprise: true
    supports_konnect: true
  - title: Google Cloud Secret
    url: /how-to/configure-google-cloud-secret-as-a-vault-backend/
    oss: false
    enterprise: true
    supports_konnect: true
  - title: HashiCorp Vault
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
    oss: false
    enterprise: true
    supports_konnect: true
  - title: |
      CyberArk Secrets Manager (Conjur)  {% new_in 3.11 %}
    url: /how-to/configure-cyberark-as-a-vault-backend/
    oss: false
    enterprise: true
    supports_konnect: true
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

## Secret rotation in Vaults

By default, {{site.base_gateway}} automatically refreshes secrets *once every minute* in the background. 
You can also configure how often {{site.base_gateway}} refreshes secrets using the Vault entity configuration.

There are two types of refresh configuration available:
* Refresh periodically using TTLs: For example, check for a new TLS certificate once per day.
* Refresh on failure: For example, on a database authentication failure, check if the secrets were updated, and try again.

For more information, see [Secret management](/gateway/secrets-management/).

## Schema

The Vault entity can only be used once the database is initialized. Secrets for values that are used before the database is initialized can’t make use of the Vaults entity.

{% entity_schema %}

## Vault provider-specific configuration parameters

When you set up a Vault, each provider has specific parameters that you can or must configure to integrate the Vault with a provider.

You can set up a Vault in one of the following ways:
* Using the Vault entity
* Using environment variables, set at {{site.base_gateway}} startup
* Using parameters in `kong.conf`, set at {{site.base_gateway}} startup

{% navtabs "provider config" %}
{% navtab "Environment variable" %}

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
  - field: Environment Variable Prefix
    parameter: |
      * **Vault entity:** `vaults.config.prefix`
      * **kong.conf parameter:** `vault_env_prefix`
      * **Environment variable:** `KONG_VAULT_ENV_PREFIX`
    description: The prefix for the environment variable that the value will be stored in.
  - field: Base64 Decode <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.base64_decode`
      * **kong.conf parameter:** `vault_env_base64_decode`
      * **Environment variable:** `KONG_VAULT_ENV_BASE64_DECODE`
    description: Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% navtab "AWS" %}

{{site.base_gateway}} must have the required IAM roles to access any relevant secrets. 
Configure the following [AWS environment variables](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-envvars.html) on your {{site.base_gateway}} data plane:

```sh
export AWS_ACCESS_KEY_ID=your-access-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-access-key
export AWS_SESSION_TOKEN=your-session-token
```

For a complete tutorial on how to set up AWS as a Vault entity, see the following:
* [Set up AWS with {{ site.base_gateway }}](/how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/)
* [Set up AWS with {{ site.kic_product_name }}](/kubernetes-ingress-controller/vault/aws/)

The following table lists all of the available configuration parameters for an AWS Secrets Manager Vault:

{% table %}
columns:
  - title: Field name
    key: field
  - title: Parameter format
    key: parameter
  - title: Description
    key: description
rows:
  - field: AWS region
    parameter: |
      * **Vault entity:** `vaults.config.region`
      * **kong.conf parameter:** `vault_aws_region`
      * **Environment variable:** `KONG_VAULT_AWS_REGION`
    description: The AWS region where your vault is located.
  - field: |
      AWS Secrets Manager Endpoint URL <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.endpoint_url`
      * **kong.conf parameter:** `vault_aws_endpoint_url`
      * **Environment variable:** `KONG_VAULT_AWS_ENDPOINT_URL`
    description: The endpoint URL of the AWS Secrets Manager service. If not specified, the default is `https://secretsmanager.{region}.amazonaws.com`. You can override this by specifying a complete URL including the `http/https` scheme.
  - field: |
      Assume AWS IAM Role ARN <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.assume_role_arn`
      * **kong.conf parameter:** `vault_aws_assume_role_arn`
      * **Environment variable:** `KONG_VAULT_AWS_ASSUME_ROLE_ARN`
    description: The target IAM role ARN to assume when accessing AWS Secrets Manager. If specified, the backend will assume this role using your current runtime's IAM Role. Leave empty if not using an assumed role.
  - field: |
      Role Session Name <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.role_session_name`
      * **kong.conf parameter:** `vault_aws_role_session_name`
      * **Environment variable:** `KONG_VAULT_AWS_ROLE_SESSION_NAME`
    description: The session name used when assuming a role. Defaults to `KongVault`.
  - field: |
      AWS STS Endpoint URL <br>{% new_in 3.8 %}
    parameter: |
      * **Vault entity:** `vaults.config.sts_endpoint_url`
      * **kong.conf parameter:** `vault_aws_sts_endpoint_url`
      * **Environment variable:** `KONG_VAULT_AWS_STS_ENDPOINT_URL`
    description: A custom STS endpoint URL used for IAM role assumption. Overrides the default `https://sts.amazonaws.com` or regional variant `https://sts.<region>.amazonaws.com`. Include the full `http/https` scheme. Only specify this if using a private VPC endpoint for STS.
  - field: TTL
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_aws_ttl`
      * **Environment variable:** `KONG_VAULT_AWS_TTL`
    description: The time-to-live (in seconds) for cached secrets. A value of 0 (default) disables rotation. If non-zero, use at least 60 seconds.
  - field: Negative TTL
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_aws_neg_ttl`
      * **Environment variable:** `KONG_VAULT_AWS_NEG_TTL`
    description: The TTL (in seconds) for caching failed secret lookups. A value of 0 (default) disables negative caching. When the TTL expires, Kong will retry fetching the secret.
  - field: Resurrect TTL
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_aws_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_AWS_RESURRECT_TTL`
    description: The duration (in seconds) for which expired secrets will continue to be used if the vault is unreachable or the secret is deleted. After this time, Kong stops retrying. The default is 1e8 seconds (~3 years) to ensure resilience during unexpected issues.
  - field: |
      Base64 Decode <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.base64_decode`
      * **kong.conf parameter:** `vault_aws_base64_decode`
      * **Environment variable:** `KONG_VAULT_AWS_BASE64_DECODE`
    description: Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}
<!--vale on-->

{% endnavtab %}

{% navtab "Azure" %}

{{site.base_gateway}} uses a key to automatically authenticate
with the [Azure Key Vaults API](https://learn.microsoft.com/en-us/rest/api/keyvault/) and grant you access.
You must set the following environment variable on your data plane to connect with an Azure Key Vault:

```bash
export AZURE_CLIENT_SECRET=YOUR_CLIENT_SECRET
```

At minimum, you'll also need to set the following values on your data plane. 

{:.info}
> **Note**: If you're using an Instance Managed Identity Token, setting these environment variables isn't necessary.

```sh
export KONG_VAULT_AZURE_VAULT_URI=https://your-vault.vault.azure.com
export KONG_VAULT_AZURE_TENANT_ID=YOUR_TENANT_ID
export KONG_VAULT_AZURE_CLIENT_ID=YOUR_CLIENT_ID
```

The following table lists all of the available configuration parameters for an Azure Key Vault:

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
  - field: Vault URI
    parameter: |
      * **Vault entity:** `vaults.config.vault_uri`
      * **kong.conf parameter:** `vault_azure_vault_uri`
      * **Environment variable:** `KONG_VAULT_AZURE_VAULT_URI`
    description: |
      The URI from which the vault is reachable. This value can be found in your Azure Key Vault Dashboard under the Vault URI entry.
  - field: Client ID
    parameter: |
      * **Vault entity:** `vaults.config.client_id`
      * **kong.conf parameter:** `vault_azure_client_id`
      * **Environment variable:** `KONG_VAULT_AZURE_CLIENT_ID`
    description: |
      The client ID for your registered application. You can find this in the Azure Dashboard under App Registrations.
  - field: Tenant ID
    parameter: |
      * **Vault entity:** `vaults.config.tenant_id`
      * **kong.conf parameter:** `vault_azure_tenant_id`
      * **Environment variable:** `KONG_VAULT_AZURE_TENANT_ID`
    description: |
      The `DirectoryId` and `TenantId` are the same: both refer to the GUID representing your Azure Active Directory tenant. Microsoft documentation and products may use either term depending on context.
  - field: Location
    parameter: |
      * **Vault entity:** `vaults.config.location`
      * **kong.conf parameter:** `vault_azure_location`
      * **Environment variable:** `KONG_VAULT_AZURE_LOCATION`
    description: |
      Each Azure geography includes one or more regions that meet specific data residency and compliance requirements.
  - field: Type
    parameter: |
      * **Vault entity:** `vaults.config.type`
      * **kong.conf parameter:** `vault_azure_type`
      * **Environment variable:** `KONG_VAULT_AZURE_TYPE`
    description: |
      Azure Key Vault supports different data types such as keys, secrets, and certificates. Kong currently supports only `secrets`.
  - field: TTL
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_azure_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_TTL`
    description: |
      Time-to-live (in seconds) for a cached secret. A value of 0 (default) means no rotation. For non-zero values, it is recommended to use intervals of at least 60 seconds.
  - field: Negative TTL
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_azure_neg_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_NEG_TTL`
    description: |
      Time-to-live (in seconds) for caching failed secret lookups. A value of 0 (default) disables negative caching. After `neg_ttl` expires, Kong retries fetching the secret.
  - field: Resurrect TTL
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_azure_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_AZURE_RESURRECT_TTL`
    description: |
      Duration (in seconds) that secrets remain usable after expiration (`config.ttl` limit). Useful when the vault is unreachable or a secret is deleted. Kong retries refreshing the secret for this duration. Afterward, it stops. The default is 1e8 seconds (~3 years) to ensure resiliency during issues.
  - field: |
      Base64 Decode <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.base64_decode`
      * **kong.conf parameter:** `vault_azure_base64_decode`
      * **Environment variable:** `KONG_VAULT_AZURE_BASE64_DECODE`
    description: Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% navtab "Google" %}

To configure GCP Secret Manager, the `GCP_SERVICE_ACCOUNT` environment variable must be set to the JSON document referring to the [credentials for your service account](https://cloud.google.com/iam/docs/creating-managing-service-account-keys):

```sh
export GCP_SERVICE_ACCOUNT=$(cat gcp-project-c61f2411f321.json)
```

{{site.base_gateway}} uses the key to automatically authenticate with the GCP API and grant you access.

To use GCP Secret Manager with [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) on a GKE cluster, update your pod spec so that the service account is attached to the pod. For configuration information, read the [Workload Identity configuration documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to).

{:.info}
> Notes:
> * With Workload Identity, setting the `GCP_SERVICE_ACCOUNT` isn’t necessary.
> * When using GCP Vault as a backend, make sure you have configured system as part of the [`lua_ssl_trusted_certificate`](/gateway/configuration/#lua-ssl-trusted-certificate) configuration directive so that the SSL certificates used by the official GCP API can be trusted by Kong.

For a complete tutorial on how to set up Google Cloud as a Vault entity, see the following:
* [Set up Google Cloud with {{ site.base_gateway }}](/how-to/configure-google-cloud-secret-as-a-vault-backend/)
* [Set up Google Cloud with {{ site.kic_product_name }}](/kubernetes-ingress-controller/vault/gcp/)

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
      * **kong.conf parameter:** `vault_gcp_base64_decode`
      * **Environment variable:** `KONG_VAULT_GCP_BASE64_DECODE`
    description: Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% navtab "HashiCorp" %}
For a complete tutorial on how to set up HashiCorp Vault as a Kong Vault backend, see the following:
* [Set up HashiCorp Vault with {{ site.base_gateway }}](/how-to/configure-hashicorp-vault-as-a-vault-backend/)
* [Set up HashiCorp Vault with {{ site.base_gateway }} and certificate authentication](/how-to/configure-hashicorp-vault-with-cert-auth/)
* [Set up HashiCorp Vault with {{ site.kic_product_name }}](/kubernetes-ingress-controller/vault/hashicorp/)
* [Set up HashiCorp Vault with {{ site.base_gateway }} and OAuth2](/how-to/configure-hashicorp-vault-with-oauth2/)

The following table lists the available configuration parameters for a HashiCorp Vault:

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
  - field: Protocol
    parameter: |
      * **Vault entity:** `vaults.config.protocol`
      * **kong.conf parameter:** `vault_hcv_protocol`
      * **Environment variable:** `KONG_VAULT_HCV_PROTOCOL`
    description: |
      The protocol to connect with. Accepts one of `http` or `https`.
  - field: Host
    parameter: |
      * **Vault entity:** `vaults.config.host`
      * **kong.conf parameter:** `vault_hcv_host`
      * **Environment variable:** `KONG_VAULT_HCV_HOST`
    description: The hostname of your HashiCorp vault.
  - field: Port
    parameter: |
      * **Vault entity:** `vaults.config.port`
      * **kong.conf parameter:** `vault_hcv_port`
      * **Environment variable:** `KONG_VAULT_HCV_PORT`
    description: The port number of your HashiCorp vault.
  - field: Mount
    parameter: |
      * **Vault entity:** `vaults.config.mount`
      * **kong.conf parameter:** `vault_hcv_mount`
      * **Environment variable:** `KONG_VAULT_HCV_MOUNT`
    description: The mount point.
  - field: Kv
    parameter: |
      * **Vault entity:** `vaults.config.kv`
      * **kong.conf parameter:** `vault_hcv_kv`
      * **Environment variable:** `KONG_VAULT_HCV_KV`
    description: |
      The secrets engine version. Accepts `v1` or `v2`.
  - field: Token
    parameter: |
      * **Vault entity:** `vaults.config.token`
      * **kong.conf parameter:** `vault_hcv_token`
      * **Environment variable:** `KONG_VAULT_HCV_TOKEN`
    description: A token string.
  - field: TTL
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_hcv_ttl`
      * **Environment variable:** `KONG_VAULT_HCV_TTL`
    description: |
      Time-to-live (in seconds) for a cached secret. A value of 0 (default) disables rotation. For non-zero values, use at least 60 seconds.
  - field: Negative TTL
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_hcv_neg_ttl`
      * **Environment variable:** `KONG_VAULT_HCV_NEG_TTL`
    description: |
      Time-to-live (in seconds) for caching failed secret lookups. A value of 0 (default) disables negative caching. Kong retries after `neg_ttl` expires.
  - field: Resurrect TTL
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_hcv_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_HCV_RESURRECT_TTL`
    description: |
      Time (in seconds) that secrets remain in use after expiration (`config.ttl` is over). Useful if the vault is unreachable or a secret is deleted. Kong continues retrying for `resurrect_ttl` seconds, then stops. Default is 1e8 seconds (~3 years).
  - field: |
      Namespace <br>{% new_in 3.1 %}
    parameter: |
      * **Vault entity:** `vaults.config.namespace`
      * **kong.conf parameter:** `vault_hcv_namespace`
      * **Environment variable:** `KONG_VAULT_HCV_NAMESPACE`
    description: Namespace for the Vault. Vault Enterprise requires a namespace to connect successfully.
  - field: |
      Authentication Method <br>{% new_in 3.1 %}
    parameter: |
      * **Vault entity:** `vaults.config.auth_method`
      * **kong.conf parameter:** `vault_hcv_auth_method`
      * **Environment variable:** `KONG_VAULT_HCV_AUTH_METHOD`
    description: |
      Defines the authentication mechanism for connecting to the HashiCorp Vault service. Accepts `token`, `kubernetes`, `approle`, or `oauth2`.

      For OAuth2, the IdP SSL certificate must be present in the Lua SSL trusted certificate when using HTTPS.
  - field: |
      Kubernetes Role <br>{% new_in 3.1 %}
    parameter: |
      * **Vault entity:** `vaults.config.kube_role`
      * **kong.conf parameter:** `vault_hcv_kube_role`
      * **Environment variable:** `KONG_VAULT_HCV_KUBE_ROLE`
    description: |
      Role assigned to the Kubernetes service account. Only used when `keyring_vault_auth_method` is set to `kubernetes`.
  - field: |
      Kubernetes API Token File <br>{% new_in 3.1 %}
    parameter: |
      * **Vault entity:** `vaults.config.kube_api_token_file`
      * **kong.conf parameter:** `vault_hcv_kube_api_token_file`
      * **Environment variable:** `KONG_VAULT_HCV_KUBE_API_TOKEN_FILE`
    description: |
      Path to the Kubernetes service account token file. Defaults to `/run/secrets/kubernetes.io/serviceaccount/token` if unspecified.
  - field: |
      Kubernetes Auth Path <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.kube_auth_path`
      * **kong.conf parameter:** `vault_hcv_kube_auth_path`
      * **Environment variable:** `KONG_VAULT_HCV_KUBE_AUTH_PATH`
    description: |
      Path for enabling the Kubernetes auth method. Defaults to `kubernetes`. Single leading/trailing slashes are trimmed.
  - field: |
      App Role Auth Path <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.approle_auth_path`
      * **kong.conf parameter:** `vault_hcv_approle_auth_path`
      * **Environment variable:** `KONG_VAULT_HCV_APPROLE_AUTH_PATH`
    description: |
      Path for enabling the AppRole auth method. Defaults to `AppRole`. Single leading/trailing slashes are trimmed.
  - field: |
      App Role Role ID <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.approle_role_id`
      * **kong.conf parameter:** `vault_hcv_approle_role_id`
      * **Environment variable:** `KONG_VAULT_HCV_APPROLE_ROLE_ID`
    description: Specifies the AppRole role ID in HashiCorp Vault.
  - field: |
      App Role Secret ID <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.approle_secret_id`
      * **kong.conf parameter:** `vault_hcv_approle_secret_id`
      * **Environment variable:** `KONG_VAULT_HCV_APPROLE_SECRET_ID`
    description: Defines the AppRole's secret ID in HashiCorp Vault.
  - field: |
      App Role Secret ID File <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.approle_secret_id_file`
      * **kong.conf parameter:** `vault_hcv_approle_secret_id_file`
      * **Environment variable:** `KONG_VAULT_HCV_APPROLE_SECRET_ID_FILE`
    description: Path to a file containing the AppRole secret ID.
  - field: |
      App Role Response Wrapping <br>{% new_in 3.4 %}
    parameter: |
      * **Vault entity:** `vaults.config.approle_response_wrapping`
      * **kong.conf parameter:** `vault_hcv_approle_response_wrapping`
      * **Environment variable:** `KONG_VAULT_HCV_APPROLE_RESPONSE_WRAPPING`
    description: |
      Whether the secret ID is a response-wrapping token. Defaults to `false`. When `true`, Kong unwraps the token to get the actual secret ID. Note: tokens can only be unwrapped once; distribute them individually to Kong nodes.
  - field: |
      Cert Key <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.cert_auth_cert_key`
      * **kong.conf parameter:** `vault_hcv_cert_auth_cert_key`
      * **Environment variable:** `KONG_VAULT_HCV_CERT_AUTH_CERT_KEY`
    description: |
      The key file for the client certificate.
  - field: |
      Cert <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.cert_auth_cert`
      * **kong.conf parameter:** `vault_hcv_cert_auth_cert`
      * **Environment variable:** `KONG_VAULT_HCV_CERT_AUTH_CERT`
    description: |
      The client certificate file.
  - field: |
      Role Name <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.cert_auth_role_name`
      * **kong.conf parameter:** `vault_hcv_cert_auth_role_name`
      * **Environment variable:** `KONG_VAULT_HCV_CERT_AUTH_ROLE_NAME`
    description: |
      The trusted certificate role name.
  - field: |
      OAuth2 Role Name <br>{% new_in 3.13 %}
    parameter: |
      * **Vault entity:** `vaults.config.oauth2_role_name`
      * **kong.conf parameter:** `vault_hcv_oauth2_role_name`
      * **Environment variable:** `KONG_VAULT_HCV_OAUTH2_ROLE_NAME`
    description: |
      The configured role name in HashiCorp Vault for OAuth2 auth. When creating the role in HashiCorp Vault, make sure that the `role_type` is `jwt` and the `token_policies` have permissions to read the secrets.
  - field: |
      OAuth2 Token Endpoint <br>{% new_in 3.13 %}
    parameter: |
      * **Vault entity:** `vaults.config.oauth2_token_endpoint`
      * **kong.conf parameter:** `vault_hcv_oauth2_token_endpoint`
      * **Environment variable:** `KONG_VAULT_HCV_OAUTH2_TOKEN_ENDPOINT`
    description: |
      The OAuth2 token endpoint for Hashicorp Vault's OAuth2 auth method.
  - field: |
      OAuth2 Client ID <br>{% new_in 3.13 %}
    parameter: |
      * **Vault entity:** `vaults.config.oauth2_client_id`
      * **kong.conf parameter:** `vault_hcv_oauth2_client_id`
      * **Environment variable:** `KONG_VAULT_HCV_OAUTH2_CLIENT_ID`
    description: |
      The OAuth2 client ID.
  - field: |
      OAuth2 Client Secret <br>{% new_in 3.13 %}
    parameter: |
      * **Vault entity:** `vaults.config.oauth2_client_secret`
      * **kong.conf parameter:** `vault_hcv_oauth2_client_secret`
      * **Environment variable:** `KONG_VAULT_HCV_OAUTH2_CLIENT_SECRET`
    description: |
      The OAuth2 client secret.
  - field: |
      OAuth2 Audiences <br>{% new_in 3.13 %}
    parameter: |
      * **Vault entity:** `vaults.config.oauth2_audiences`
      * **kong.conf parameter:** `vault_hcv_oauth2_audiences`
      * **Environment variable:** `KONG_VAULT_HCV_OAUTH2_AUDIENCES`
    description: |
      Comma-separated list of OAuth2 audiences.
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% navtab "CyberArk Secrets Manager" %}

See a tutorial about how to [set up CyberArk Secrets Manager (Conjur) as a Kong Vault backend in {{site.base_gateway}}](/how-to/configure-cyberark-as-a-vault-backend/).

The following table lists the available configuration parameters for a CyberArk Secrets Manager Vault:

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
  - field: |
      Endpoint URL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.endpoint_url`
      * **kong.conf parameter:** `vault_conjur_endpoint_url`
      * **Environment variable:** `KONG_VAULT_CONJUR_ENDPOINT_URL`
    description: |
      The CyberArk Secrets Manager backend URL to connect with. Accepts `http` or `https` protocols.
  - field: |
      Authentication method <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.auth_method`
      * **kong.conf parameter:** `vault_conjur_auth_method`
      * **Environment variable:** `KONG_VAULT_CONJUR_AUTH_METHOD`
    description: "Defines the authentication mechanism for connecting to the CyberArk Secrets Manager Vault service. Accepted value: `api_key`."
  - field: |
      Account <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.account`
      * **kong.conf parameter:** `vault_conjur_account`
      * **Environment variable:** `KONG_VAULT_CONJUR_ACCOUNT`
    description: The CyberArk Secrets Manager organization account name.
  - field: |
      Login <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.login`
      * **kong.conf parameter:** `vault_conjur_login`
      * **Environment variable:** `KONG_VAULT_CONJUR_LOGIN`
    description: The login name of the workload identity.
  - field: |
      API Key <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.api_key`
      * **kong.conf parameter:** `vault_conjur_api_key`
      * **Environment variable:** `KONG_VAULT_CONJUR_API_KEY`
    description: The API key of the workload identity.
  - field: |
      TTL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.ttl`
      * **kong.conf parameter:** `vault_conjur_ttl`
      * **Environment variable:** `KONG_VAULT_CONJUR_TTL`
    description: Time-to-live (in seconds) for a cached secret. A value of 0 (default) disables rotation. For non-zero values, use at least 60 seconds.
  - field: |
      Negative TTL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.neg_ttl`
      * **kong.conf parameter:** `vault_conjur_neg_ttl`
      * **Environment variable:** `KONG_VAULT_CONJUR_NEG_TTL`
    description: |
      Time-to-live (in seconds) for caching failed secret lookups. A value of 0 (default) disables negative caching. 
      Kong retries after `neg_ttl` expires.
  - field: |
      Resurrect TTL <br>{% new_in 3.11 %}
    parameter: |
      * **Vault entity:** `vaults.config.resurrect_ttl`
      * **kong.conf parameter:** `vault_conjur_resurrect_ttl`
      * **Environment variable:** `KONG_VAULT_CONJUR_RESURRECT_TTL`
    description: |
      Duration (in seconds) that secrets remain usable after expiration (`config.ttl` is over). 
      Useful when the vault is unreachable or a secret is deleted but not yet replaced. 
      Kong continues retrying for `resurrect_ttl` seconds, then stops. The default is 1e8 seconds (~3 years).
{% endtable %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}

### AWS Secrets Manager credentials

To access secrets stored in the AWS Secrets Manager, {{site.base_gateway}} needs to be configured with an IAM Role that has sufficient permissions to read the required secret values.

{{site.base_gateway}} can automatically fetch IAM role credentials based on your AWS environment, observing the following precedence order:
- Fetch from credentials defined in environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
- Fetch from profile and credential file, defined by `AWS_PROFILE` and `AWS_SHARED_CREDENTIALS_FILE`.
- Fetch from an ECS [container credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html).
- Fetch from an EKS [IAM roles for service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).
- Fetch from EC2 IMDS metadata. Both v1 and v2 are supported

{{site.base_gateway}} also supports role assuming (with [`vaults.config.assume_role_arn` and `vaults.config.role_session_name`](/gateway/entities/vault/?tab=aws#vault-provider-specific-configuration-parameters)) which allows you to use a different IAM role to fetch secrets from AWS Secrets Manager. This is a common practice in permission division and governance and cross-AWS account management.

{:.info}
> **Note:** IAM Identity Center credential provider and process credential provider are not supported.

## Set up a Vault

{% entity_example %}
type: vault
data:
  name: env
  description: ENV vault for secrets
  prefix: my-env-vault
  config:
    prefix: MY_SECRET_
{% endentity_example %}

## Store secrets as environment variables

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
