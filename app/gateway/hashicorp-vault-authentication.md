---
title: "HashiCorp Vault authentication support for {{site.ee_product_name}}"
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
  - vault
  - hashicorp

description: |
  Review which authentication methods {{site.ee_product_name}} supports when connecting to HashiCorp Vault as a secrets backend.

related_resources:
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
  - text: Cloud provider support matrix
    url: /gateway/cloud-provider-support-matrix/
  - text: Vault entity reference
    url: /gateway/entities/vault/
---

{{site.ee_product_name}} integrates with [HashiCorp Vault](https://www.vaultproject.io/) as a secrets backend
for storing and managing sensitive data such as certificates, API keys, and other credentials.
To securely connect to a HashiCorp Vault instance, {{site.ee_product_name}} supports multiple
authentication methods across generic, infrastructure, and cloud categories.

## Supported authentication methods

<!--vale off-->
{% table %}
columns:
  - title: Category
    key: category
  - title: Method
    key: method
  - title: Description
    key: description
  - title: "{{site.ee_product_name}}"
    key: ee
  - title: Konnect
    key: konnect
  - title: Type
    key: type
rows:
  - category: Generic
    method: "[Token](https://developer.hashicorp.com/vault/docs/auth/token)"
    description: Authenticate with a Vault token.
    ee: "✅"
    konnect: "✅"
    type: Internal
  - category: Generic
    method: "[TLS Certificate](https://developer.hashicorp.com/vault/docs/auth/cert)"
    description: Authenticate using SSL/TLS client certificates.
    ee: "✅"
    konnect: "✅"
    type: Internal
  - category: Generic
    method: "[AppRole](https://developer.hashicorp.com/vault/docs/auth/approle)"
    description: Authenticate with HashiCorp Vault-defined roles.
    ee: "✅"
    konnect: "✅"
    type: Internal
  - category: Generic
    method: "[JWT](https://developer.hashicorp.com/vault/docs/auth/jwt)"
    description: Authenticate with a JWT from an OIDC provider.
    ee: "✅ (3.13+)"
    konnect: "✅ (3.13+)"
    type: External
  - category: Infrastructure
    method: "[Kubernetes](https://developer.hashicorp.com/vault/docs/auth/kubernetes)"
    description: Authenticate using a Kubernetes Service Account token.
    ee: "✅"
    konnect: "✅"
    type: External
  - category: Cloud
    method: "[AWS](https://developer.hashicorp.com/vault/docs/auth/aws)"
    description: Authenticate using AWS IAM credentials, including the AWS EC2/IAM auth method supported by Hashicorp Vault.
    ee: "✅ (3.14+)"
    konnect: "✅ (3.14+)"
    type: External
  - category: Cloud
    method: "[Azure](https://developer.hashicorp.com/vault/docs/auth/azure)"
    description: Authenticate using Azure Microsoft Entra credentials.
    ee: "✅ (3.14+)"
    konnect: "✅ (3.14+)"
    type: External
  - category: Cloud
    method: "[GCP](https://developer.hashicorp.com/vault/docs/auth/gcp)"
    description: Authenticate using GCP IAM credentials.
    ee: "✅ (3.14+)"
    konnect: "✅ (3.14+)"
    type: External
{% endtable %}
<!--vale on-->

### Authentication method types

* **Internal**: Authentication is handled entirely within HashiCorp Vault using credentials
  specific to Vault itself, such as a Vault token or an AppRole.
* **External**: Authentication relies on an identity managed by an external provider or
  infrastructure platform, such as Kubernetes, AWS IAM, or Azure Microsoft Entra ID.

### Generic methods

**Token**, **TLS Certificate**, and **AppRole** are built-in HashiCorp Vault authentication
methods that don't require any specific infrastructure or cloud platform.

**JWT** authentication lets {{site.ee_product_name}} authenticate with HashiCorp Vault using a
JSON Web Token issued by an OIDC provider, enabling integration with external identity systems.

### Infrastructure methods

**Kubernetes** authentication lets {{site.ee_product_name}} authenticate with HashiCorp Vault
using a Kubernetes Service Account token. This method is suitable when {{site.ee_product_name}}
runs inside a Kubernetes cluster.

### Cloud IAM methods

{{site.ee_product_name}} supports authenticating with HashiCorp Vault using cloud provider IAM
credentials from **AWS**, **Azure**, and **GCP**. This lets you leverage your existing cloud
IAM infrastructure to securely access secrets stored in HashiCorp Vault.

For details on which specific cloud IAM authentication mechanisms are supported, see the
[cloud provider support matrix](/gateway/cloud-provider-support-matrix/).
