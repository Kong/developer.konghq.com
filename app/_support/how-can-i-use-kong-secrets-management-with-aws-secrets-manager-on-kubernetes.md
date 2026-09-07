---
title: Using Kong Secrets Management with AWS Secrets Manager on Kubernetes
content_type: support
description: Configure the `aws` vault backend to use AWS Secrets Manager on Kubernetes with static access keys or an attached IAM role.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How can I use Kong Secrets Management with AWS Secrets Manager on Kubernetes?
  a: |
    Configure the `aws` vault backend by setting AWS credentials through the Helm chart's `customEnv` (`aws_access_key_id`, `aws_secret_access_key`), since these variables aren't prefixed with `KONG_` and can't go in the regular `env` section. Alternatively, rely on an attached IAM role (EKS IRSA/Pod Identity or an EC2 instance profile), optionally scoped with `config.assume_role_arn`. Set the AWS region with `vault_aws_region` under `env`, then reference secrets using the `{vault://aws/<secret-id>/<secret-key>}` format.
related_resources:
  - text: create a new vault entity to include the region
    url: /how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/
---

## Overview

Kong Gateway includes GA support for secrets management. How can this be configured to work with AWS Secrets Manager on Kubernetes?

## Steps

This article assumes you have already created your AWS Access Keys. If you have not, please refer to the AWS documentation to create these before moving forward.

To use AWS Secrets Manager two things will need to be configured, your AWS Access Keys and your AWS Region.

Setting Your Access Keys

To configure Secrets Management you will first need to configure your deployment to use your AWS Access Keys via the environment variables below.

As of Kong Gateway 3.14.0.0, the `aws` vault backend also supports IAM roles: if no static access keys are configured, Kong falls back to the AWS SDK's default credential provider chain, which auto-detects credentials from an attached IAM role (e.g. an EKS IRSA/Pod Identity role, or an EC2 instance profile). To assume a specific role, set the vault's `config.assume_role_arn` field (optionally with `config.role_session_name` and `config.sts_endpoint_url`) instead of/in addition to the static access keys below.

The required variables (for the static access-key approach) are:

```

aws_access_key_id
aws_secret_access_key
```

Because these variables are not prefixed with `KONG_` like our typical configuration settings they cannot simply be added to the `env` section of your helm values file. They instead will need to be configured in the `customEnv` section.

Note : customEnv first became available in chart 2.7.0. If you are unsure what version you are currently using you can confirm this by running:

```bash

helm show chart kong/kong
```

AWS Region

You will also need to define the AWS region where your secrets are stored. Setting this in your deployment will allow access to the secrets using the default `aws` entity, for example `{vault://aws/my-secret-name/key}`. If this is not set during deployment, it can be configured via the Kong Admin API or Kong Manager after startup.

To configure via environment variable, unlike the access keys, you will need to add `vault_aws_region` (not `aws_region`) to your env section — this is a genuine Kong configuration setting (`kong/enterprise_edition/conf_loader.lua`'s `EE_CONF_BASIC` table), which the Helm chart's `env:` block automatically renders as `KONG_VAULT_AWS_REGION`. Setting a plain `aws_region` key under `env:` (which would render as `KONG_AWS_REGION`) is silently ignored — it is not a recognized Kong configuration key.

Sample Config:

```yaml

env: 
  vault_aws_region: "us-east-1"
customEnv:
  aws_access_key_id: AKIAIOSFODNN7EXAMPLE
  aws_secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

If you exclude the region variable you will need to create a new vault entity to include the region.

Once setup is complete, the secrets can be referenced using the format:

```

{vault://<vault-backend|entity>/<secret-id>[/<secret-key][?query]}
```
