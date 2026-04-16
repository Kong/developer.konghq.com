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
  Learn which {{site.ee_product_name}} features support cloud IAM authentication with AWS, Azure, and GCP, and which authentication methods are available for each provider.

related_resources:
  - text: Amazon RDS authentication with AWS IAM
    url: /gateway/amazon-rds-authentication-with-aws-iam/
  - text: Azure PostgreSQL authentication with managed identity
    url: /gateway/azure-pg-authentication-with-azure-managed-identity/
  - text: Azure PostgreSQL authentication with a service principal
    url: /gateway/azure-pg-authentication-with-azure-app-service-principal/
  - text: GCP PostgreSQL authentication
    url: /gateway/gcp-postgres-authentication/
  - text: Vault reference
    url: /gateway/entities/vault/
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
in place of static credentials. This allows you to use AWS IAM, Azure Microsoft Entra ID, or GCP IAM
to authenticate {{site.base_gateway}} with cloud-hosted backing services such as databases, caches,
secret stores, object storage, and serverless functions.

## Feature support

The following shows which {{site.base_gateway}} features support cloud provider IAM authentication.

* PostgreSQL database ([AWS](/gateway/amazon-rds-authentication-with-aws-iam/), [Azure](/gateway/azure-pg-authentication-with-azure-managed-identity/), [GCP](/gateway/gcp-postgres-authentication/))
* Redis ([see plugin docs](/plugins/rate-limiting-advanced/#using-cloud-authentication-with-redis))
* [Vault](/gateway/entities/vault/) ([AWS](/how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/), [GCP](/how-to/configure-google-cloud-secret-as-a-vault-backend/), and [Azure](/gateway/entities/vault/?tab=azure))
* [Data plane resilience](/gateway/cp-outage/)
* [AI plugins](/ai-gateway/)

  {:.info}
  > **Note:** AI plugins support more AI models and service providers beyond AWS, Azure, and GCP.
  > See the [{{site.ai_gateway_name}} overview](/ai-gateway/) for a full list of supported providers.

## Authentication methods support

Each cloud provider offers different IAM authentication mechanisms.
The following table lists which authentication methods {{site.base_gateway}} supports for each cloud provider.

Unless otherwise noted, each supported authentication method can be used with **any** {{site.base_gateway}} feature that integrates with that cloud provider, as listed in the [feature support matrix](#feature-support).

{:.warning}
> **Important:** Identity Federation isn't supported as an authentication method for any cloud provider.

{% table %}
columns:
  - title: Cloud provider
    key: provider
  - title: Supported authentication methods
    key: methods
rows:
  - provider: AWS
    methods: |
      * [Access Key + Secret Key pair](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
      * [EC2 IAM Role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
      * [ECS Task IAM Role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
      * [IAM Role for Service Account (IRSA in EKS)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
      * [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
      * [Assume Role](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html) (based on any of the above methods)
  - provider: GCP
    methods: |
      * [Static Service Account Key](https://cloud.google.com/iam/docs/keys-create-delete)
      * [Service Account Credential](https://docs.cloud.google.com/iam/docs/service-account-creds) (Compute Engine)
      * [Workload Identity](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) (GKE)
  - provider: Azure
    methods: |
      * [Client Secret Credential](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow) (Service Principal)
      * [Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview) (Virtual Machine, Service Fabric, AKS, etc.)
      * [Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview) (AKS)
{% endtable %}


## HashiCorp Vault cloud authentication

{% include /gateway/hashicorp-vault-authentication.md %}



