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
{% table %}
columns:
  - title: Feature
    key: feature
  - title: AWS IAM
    key: aws
  - title: Azure Microsoft Entra
    key: azure
  - title: GCP IAM
    key: gcp
rows:
  - feature: "PostgreSQL database ([AWS](/gateway/amazon-rds-authentication-with-aws-iam/), [Azure](/gateway/azure-pg-authentication-with-azure-managed-identity/), [GCP](/gateway/gcp-postgres-authentication/))"
    aws: "✅"
    azure: "✅"
    gcp: "✅"
  - feature: "Redis ([see plugin docs](/plugins/rate-limiting-advanced/#using-cloud-authentication-with-redis))"
    aws: "✅"
    azure: "✅"
    gcp: "✅"
  - feature: "[AWS Secrets Manager vault](/how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/)"
    aws: "✅"
    azure: "N/A"
    gcp: "N/A"
  - feature: "[Google Cloud Secret Manager vault](/how-to/configure-google-cloud-secret-as-a-vault-backend/)"
    aws: "N/A"
    azure: "N/A"
    gcp: "✅"
  - feature: "[Azure Key Vault](/gateway/entities/vault/?tab=azure)"
    aws: "N/A"
    azure: "✅"
    gcp: "N/A"
  - feature: "[Data plane resilience](/gateway/cp-outage/)"
    aws: "✅ (also for S3-compatible interfaces)"
    azure: "✅ (Azure blob storage)"
    gcp: "✅ (Google Cloud Storage)"
  - feature: "[AI plugins](/ai-gateway/)"
    aws: "✅"
    azure: "✅"
    gcp: "✅"
{% endtable %}
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
{% table %}
columns:
  - title: Authentication method
    key: method
  - title: Supported
    key: supported
rows:
  - method: "[Access Key + Secret Key pair](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)"
    supported: "✅"
  - method: "[EC2 IAM Role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)"
    supported: "✅"
  - method: "[ECS Task IAM Role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)"
    supported: "✅"
  - method: "[IAM Role for Service Account (IRSA in EKS)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)"
    supported: "✅"
  - method: "[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)"
    supported: "✅"
  - method: "[Assume Role](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html) (based on any of the above methods)"
    supported: "✅"
  - method: "[Identity Federation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers.html)"
    supported: "❌"
{% endtable %}
<!--vale on-->

### GCP IAM

<!--vale off-->
{% table %}
columns:
  - title: Authentication method
    key: method
  - title: Supported
    key: supported
rows:
  - method: "[Static Service Account Key](https://cloud.google.com/iam/docs/keys-create-delete)"
    supported: "✅"
  - method: "[Service Account Credential](https://docs.cloud.google.com/iam/docs/service-account-creds) (Compute Engine)"
    supported: "✅"
  - method: "[Workload Identity](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) (GKE)"
    supported: "✅"
  - method: "[Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) / [Workforce Identity Federation](https://cloud.google.com/iam/docs/workforce-identity-federation)"
    supported: "❌"
{% endtable %}
<!--vale on-->

### Azure Microsoft Entra

<!--vale off-->
{% table %}
columns:
  - title: Authentication method
    key: method
  - title: Supported
    key: supported
rows:
  - method: "[Client Secret Credential](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow) (Service Principal)"
    supported: "✅"
  - method: "[Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview) (Virtual Machine, Service Fabric, AKS, etc.)"
    supported: "✅"
  - method: "[Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview) (AKS)"
    supported: "✅"
  - method: "[Workload Identity Federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)"
    supported: "❌"
{% endtable %}
<!--vale on-->
