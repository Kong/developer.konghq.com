---
title: "HashiCorp Vault"
layout: reference
content_type: reference
description: "Use HashiCorp Vault to store and reference secrets in {{site.base_gateway}}."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/hashicorp/

works_on:
  - on-prem
  - konnect

products:
  - gateway

tools:
  - admin-api
  - konnect-api
  - deck
  - kic
  - terraform

tags:
  - secrets-management
  - hashicorp-vault

min_version:
  gateway: '3.4'

related_resources:
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
  - text: "Supported {{site.base_gateway}} Vault backends"
    url: /gateway/entities/vault/#supported-vault-backends
  - text: Secrets management
    url: /gateway/secrets-management/

how_to_list:
  config:
    products:
      - gateway
    tags:
      - hashicorp-vault
    description: true
    view_more: false
---

You can set up a [HashiCorp Vault](https://www.vaultproject.io/) vault in one of the following ways:
* Using the [Vault entity](/gateway/entities/vault/)
* Using [environment variables](/gateway/manage-kong-conf/#environment-variables), set at {{site.base_gateway}} startup
* Using parameters in [`kong.conf`](/gateway/configuration/), set at {{site.base_gateway}} startup

The Vault entity can only be used once the database is initialized.
Secrets for values that are used before the database is initialized can't make use of the Vaults entity.

If you're configuring via a Vault entity, set `vaults.name` to `hcv`.

## HashiCorp Vault cloud authentication

{% include_cached /gateway/hashicorp-vault-authentication.md %}

## Create a HashiCorp Vault

The following example creates an `hcv` Vault entity:

{% entity_example %}
type: vault
data:
  name: hcv
  prefix: hashicorp-vault
  description: Storing secrets in HashiCorp Vault
  config:
    host: example-hcv-host
    token: example-hc-token
    kv: v2
    mount: secret
    port: 8200
    protocol: http
{% endentity_example %}

## Vault configuration options

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
      Defines the authentication mechanism for connecting to the HashiCorp Vault service. Accepts `token`, `kubernetes`, `approle`, `cert`, `jwt`, `gcp_iam`, `gcp_gce`, `azure`, `aws_ec2`, or `aws_iam`.

      For `jwt`, the IdP SSL certificate must be present in the Lua SSL trusted certificate when using HTTPS.
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
  - field: |
      GCP Auth Role <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.gcp_auth_role`
      * **kong.conf parameter:** `vault_hcv_gcp_auth_role`
      * **Environment variable:** `KONG_VAULT_HCV_GCP_AUTH_ROLE`
    description: |
      The configured role name in HashiCorp Vault for GCP auth. Required when `auth_method` is `gcp_iam` or `gcp_gce`.
  - field: |
      GCP Login Path <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.gcp_login_path`
      * **kong.conf parameter:** `vault_hcv_gcp_login_path`
      * **Environment variable:** `KONG_VAULT_HCV_GCP_LOGIN_PATH`
    description: |
      The login path for GCP auth in HashiCorp Vault. Used with both `gcp_iam` and `gcp_gce` auth methods. Defaults to `/v1/auth/gcp/login`.
  - field: |
      GCP Service Account <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.gcp_service_account`
      * **kong.conf parameter:** `vault_hcv_gcp_service_account`
      * **Environment variable:** `KONG_VAULT_HCV_GCP_SERVICE_ACCOUNT`
    description: |
      The GCP service account email or identifier used for authentication. Required when `auth_method` is `gcp_iam`.
  - field: |
      GCP JWT Expiration <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.gcp_jwt_exp`
      * **kong.conf parameter:** `vault_hcv_gcp_jwt_exp`
      * **Environment variable:** `KONG_VAULT_HCV_GCP_JWT_EXP`
    description: |
      The expiration time for the GCP JWT token in seconds. Must be between 0 and 900. Required when `auth_method` is `gcp_iam`.
  - field: |
      Azure Auth Role <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.azure_auth_role`
      * **kong.conf parameter:** `vault_hcv_azure_auth_role`
      * **Environment variable:** `KONG_VAULT_HCV_AZURE_AUTH_ROLE`
    description: |
      The configured role name in HashiCorp Vault for Azure auth. When creating the role in HashiCorp Vault, make sure that the `role_type` is `azure` and the `token_policies` have permissions to read the secrets. Required when `auth_method` is `azure`.
  - field: |
      Azure Login Path <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.azure_login_path`
      * **kong.conf parameter:** `vault_hcv_azure_login_path`
      * **Environment variable:** `KONG_VAULT_HCV_AZURE_LOGIN_PATH`
    description: |
      The login path for Azure auth in HashiCorp Vault. Defaults to `/v1/auth/azure/login`.
  - field: |
      AWS Auth Role <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_auth_role`
      * **kong.conf parameter:** `vault_hcv_aws_auth_role`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_AUTH_ROLE`
    description: |
      The configured role name in HashiCorp Vault for AWS auth. When creating the role in HashiCorp Vault, make sure that the `role_type` is `aws` and the `token_policies` have permissions to read the secrets. Required when `auth_method` is `aws_ec2` or `aws_iam`.
  - field: |
      AWS Login Path <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_login_path`
      * **kong.conf parameter:** `vault_hcv_aws_login_path`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_LOGIN_PATH`
    description: |
      The login path for AWS auth in HashiCorp Vault. Used with both `aws_ec2` and `aws_iam` auth methods. Defaults to `/v1/auth/aws/login`.
  - field: |
      AWS Auth Region <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_auth_region`
      * **kong.conf parameter:** `vault_hcv_aws_auth_region`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_AUTH_REGION`
    description: |
      The AWS region for the AWS auth method. Required when `auth_method` is `aws_iam`.
  - field: |
      AWS Auth Nonce <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_auth_nonce`
      * **kong.conf parameter:** `vault_hcv_aws_auth_nonce`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_AUTH_NONCE`
    description: |
      The nonce used for the AWS EC2 auth method. Required when `auth_method` is `aws_ec2`.
  - field: |
      AWS Access Key ID <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_access_key_id`
      * **kong.conf parameter:** `vault_hcv_aws_access_key_id`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_ACCESS_KEY_ID`
    description: |
      The AWS access key ID for AWS IAM authentication. If not provided, the default credentials provider chain is used. Must be set together with `aws_secret_access_key`.
  - field: |
      AWS Secret Access Key <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_secret_access_key`
      * **kong.conf parameter:** `vault_hcv_aws_secret_access_key`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_SECRET_ACCESS_KEY`
    description: |
      The AWS secret access key for AWS IAM authentication. If not provided, the default credentials provider chain is used. Must be set together with `aws_access_key_id`.
  - field: |
      AWS STS Endpoint URL <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_sts_endpoint_url`
      * **kong.conf parameter:** `vault_hcv_aws_sts_endpoint_url`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_STS_ENDPOINT_URL`
    description: |
      The AWS STS endpoint URL used by {{site.base_gateway}} when signing the `GetCallerIdentity` request for AWS IAM authentication. If not provided, defaults to the standard STS endpoint for the specified region. This setting only affects the STS endpoint that {{site.base_gateway}} itself contacts — it does not influence which STS endpoint HashiCorp Vault uses on its side.
  - field: |
      AWS Assume Role ARN <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_assume_role_arn`
      * **kong.conf parameter:** `vault_hcv_aws_assume_role_arn`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_ASSUME_ROLE_ARN`
    description: |
      The ARN of the AWS IAM role to assume for authentication. Must be set together with `aws_role_session_name`.
  - field: |
      AWS Role Session Name <br>{% new_in 3.14 %}
    parameter: |
      * **Vault entity:** `vaults.config.aws_role_session_name`
      * **kong.conf parameter:** `vault_hcv_aws_role_session_name`
      * **Environment variable:** `KONG_VAULT_HCV_AWS_ROLE_SESSION_NAME`
    description: |
      The session name to use when assuming an AWS IAM role. Defaults to `kong`. Must be set together with `aws_assume_role_arn`.
{% endtable %}
<!--vale on-->

## Tutorials

{% how_to_list page.how_to_list.config %}