---
title: "Cloud provider integration support for {{site.ee_product_name}}"
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/

products:
  - gateway

works_on:
  - on-prem
  - konnect

tags:
  - aws
  - azure
  - google-cloud

description: |
  Review which {{site.ee_product_name}} features support cloud IAM authentication with AWS, Azure, and GCP, and which authentication methods are available for each provider.

related_resources:
  - text: Amazon RDS authentication with AWS IAM
    url: /gateway/amazon-rds-authentication-with-aws-iam/
  - text: Azure PostgreSQL authentication with managed identity
    url: /gateway/azure-pg-authentication-with-azure-managed-identity/
  - text: Azure PostgreSQL authentication with a service principal
    url: /gateway/azure-pg-authentication-with-azure-app-service-principal/
  - text: GCP PostgreSQL authentication
    url: /gateway/gcp-postgres-authentication/
  - text: AWS Lambda plugin
    url: /plugins/aws-lambda/
  - text: Azure Functions plugin
    url: /plugins/azure-functions/
  - text: Control plane outage management (data plane resilience)
    url: /gateway/cp-outage/
  - text: "{{site.ai_gateway_name}}"
    url: /ai-gateway/
  - text: Supported third-party dependencies
    url: /gateway/third-party-support/
---

{{site.ee_product_name}} integrates with major cloud providers to support cloud-native IAM authentication
in place of static credentials. This lets you use AWS IAM, Azure Microsoft Entra ID, or GCP IAM
to authenticate {{site.ee_product_name}} with cloud-hosted backing services such as databases, caches,
secret stores, object storage, and serverless functions.

## Feature support matrix

The following table shows which {{site.ee_product_name}} features support cloud provider IAM authentication.

<!--vale off-->
{% feature_table %}
item_title: Feature Support Matrix
columns:
  - title: AWS IAM
    key: aws
  - title: Azure Microsoft Entra
    key: azure
  - title: GCP IAM
    key: gcp
features:
  - title: "PostgreSQL database ([AWS](/gateway/amazon-rds-authentication-with-aws-iam/), [Azure](/gateway/azure-pg-authentication-with-azure-managed-identity/), [GCP](/gateway/gcp-postgres-authentication/))"
    aws: true
    azure: true
    gcp: true
  - title: "Redis ([see plugin docs](/plugins/rate-limiting-advanced/#using-cloud-authentication-with-redis))"
    aws: true
    azure: true
    gcp: true
  - title: "[AWS Secrets Manager vault](/how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/)"
    aws: true
    azure: "N/A"
    gcp: "N/A"
  - title: "[Google Cloud Secret Manager vault](/how-to/configure-google-cloud-secret-as-a-vault-backend/)"
    aws: "N/A"
    azure: "N/A"
    gcp: true
  - title: "[Azure Key Vault](/gateway/entities/vault/?tab=azure)"
    aws: "N/A"
    azure: true
    gcp: "N/A"
  - title: "[Data plane resilience](/gateway/cp-outage/)"
    aws: true
    azure: true
    gcp: true
  - title: "[AI plugins](/ai-gateway/)"
    aws: true
    azure: true
    gcp: true
{% endfeature_table %}
<!--vale on-->

{:.info}
> **Note:** AI plugins support many more AI models and service providers beyond AWS, Azure, and GCP.
> See the [{{site.ai_gateway_name}} overview](/ai-gateway/) for a full list of supported providers.

**N/A** indicates the feature is provider-specific and doesn't apply to the listed cloud provider.
For example, the AWS Secrets Manager vault backend is exclusive to AWS.

## Authentication methods support matrix

Each cloud provider offers different IAM authentication mechanisms.
The following tables list which authentication methods {{site.ee_product_name}} supports for each cloud provider.

Unless otherwise noted, each supported authentication method can be used with **any** {{site.ee_product_name}} feature that integrates with that cloud provider, as listed in the [feature support matrix](#feature-support-matrix) above.

### AWS IAM

<!--vale off-->
{% feature_table %}
item_title: Authentication method
columns:
  - title: Supported
    key: supported
features:
  - title: "[Access Key + Secret Key pair](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)"
    supported: true
  - title: "[EC2 IAM Role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)"
    supported: true
  - title: "[ECS Task IAM Role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)"
    supported: true
  - title: "[IAM Role for Service Account (IRSA in EKS)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)"
    supported: true
  - title: "[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)"
    supported: true
  - title: "[Assume Role](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html) (based on any of the above methods)"
    supported: true
  - title: "[Identity Federation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers.html)"
    supported: false
{% endfeature_table %}
<!--vale on-->

### GCP IAM

<!--vale off-->
{% feature_table %}
item_title: Authentication method
columns:
  - title: Supported
    key: supported
features:
  - title: "[Static Service Account Key](https://cloud.google.com/iam/docs/keys-create-delete)"
    supported: true
  - title: "[Service Account Credential](https://docs.cloud.google.com/iam/docs/service-account-creds) (Compute Engine)"
    supported: true
  - title: "[Workload Identity](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) (GKE)"
    supported: true
  - title: "[Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) / [Workforce Identity Federation](https://cloud.google.com/iam/docs/workforce-identity-federation)"
    supported: false
{% endfeature_table %}
<!--vale on-->

### Azure Microsoft Entra

<!--vale off-->
{% feature_table %}
item_title: Authentication method
columns:
  - title: Supported
    key: supported
features:
  - title: "[Client Secret Credential](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow) (Service Principal)"
    supported: true
  - title: "[Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview) (Virtual Machine, Service Fabric, AKS, etc.)"
    supported: true
  - title: "[Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview) (AKS)"
    supported: true
  - title: "[Workload Identity Federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)"
    supported: false
{% endfeature_table %}
<!--vale on-->
