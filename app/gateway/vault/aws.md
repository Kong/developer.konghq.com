---
title: "AWS Secrets Manager vault"
layout: reference
content_type: reference
description: "Use AWS Secrets Manager to store and reference secrets in {{site.base_gateway}}."
breadcrumbs:
  - /gateway/
  - /gateway/entities/
  - /gateway/entities/vault/

permalink: /gateway/entities/vault/aws/

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
  - aws-vault

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
      - aws-vault
    description: true
    view_more: false
---

You can set up an [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) vault in one of the following ways:

{% include_cached /gateway/vault-provider-intro.md %}

## AWS Secrets Manager credentials

To access secrets stored in AWS Secrets Manager, {{site.base_gateway}} needs an IAM Role that has sufficient permissions to read the required secret values.

{{site.base_gateway}} can automatically fetch IAM role credentials based on your AWS environment, using the following precedence order:
1. Fetch from credentials defined in environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
1. Fetch from profile and credential file, defined by `AWS_PROFILE` and `AWS_SHARED_CREDENTIALS_FILE`.
1. Fetch from an ECS [container credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html).
1. Fetch from an EKS [IAM roles for service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).
1. Fetch from EC2 IMDS metadata. Both v1 and v2 are supported.

{{site.base_gateway}} also supports role assuming using [`vaults.config.assume_role_arn` and `vaults.config.role_session_name`](#vault-configuration-options), which lets you use a different IAM role to fetch secrets from AWS Secrets Manager.
This is a common practice for permission division, governance, and cross-AWS account management.

{:.warning}
> **Note:** IAM Identity Center credential provider and process credential provider are not supported.

## Create an AWS Secrets Manager vault

The following example creates an `aws` Vault entity in the AWS region `us-east-1`.
The Vault name **must** be `aws`. The `vault.prefix` value can be your own custom prefix:

{% entity_example %}
type: vault
data:
  name: aws
  prefix: aws-vault
  description: Storing secrets in AWS Secrets Manager
  config:
    region: us-east-1
{% endentity_example %}


## Vault configuration options

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
      * **kong.conf parameter:** `vault_aws_decode_base64`
      * **Environment variable:** `KONG_VAULT_AWS_DECODE_BASE64`
    description: Decode all secrets in this vault as base64. Useful for binary data. If some of the secrets in the vault are not base64-encoded, an error will occur when using them. We recommend creating a separate vault for base64 secrets.
{% endtable %}

## Tutorials

{% how_to_list page.how_to_list.config %}