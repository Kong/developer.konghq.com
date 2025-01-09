---
title: Vaults
content_type: reference
entities:
  - vault

description: A Vault is used to store secrets.

related_resources:
  - text: Vault CLI
    url: /
  - text: Secrets Management
    url: /secrets-management
  - text: Secret rotation
    url: /gateway/secret-management/secret-rotation
  

faqs:
  - q: I'm using declarative configuration for my Vault. Should I split my Vault configuration?
    a: |
        For larger teams with many contributors, or organizations with multiple teams, we recommend splitting Vault configuration and managing it separately. We recommend splitting the configuration for the following reasons:
        * Vault are closer to infrastructure than other {{site.base_gateway}} configurations.
        Separation of routing policies from infrastructure-specific configurations helps
        keep configuration organized.
        * Vaults may be shared across teams. In this case, one specific team shouldn't
        control the Vault's configuration. One team changing the Vault a can have
        disastrous impact on another team.
        * If a Vault is deleted while in use -- that is, if there are still references to
        secrets in a Vault in configuration -- it can lead to total loss of proxy capabilities.
        Those secrets would be unrecoverable.
  - q: What are general best practices for managing Vaults?
    a: |
        To keep your environment secure and avoid taking down your proxies by accident, make sure to:
        * Manage Vaults with distributed configuration via tags.
        * Use a separate [RBAC role, user, and token](/gateway/entities/rbac/)
        to manage Vaults. Don't use a generic admin user.
        * Set up a separate CI pipeline for Vaults.

tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform

api_specs:
    - gateway/admin-oss
    - gateway/admin-ee
    - konnect/control-planes-config

schema:
    api: gateway/admin-ee
    path: /schemas/Vault
---

## What is a Vault?
In {{site.base_gateway}}, the Vault object is used to store secrets. A secret is any sensitive piece of information required for API gateway
operations. Secrets can be used as part of the core {{site.base_gateway}} configuration, in plugins, or in configuration associated
with APIs serviced by the gateway.

Some of the most common types of secrets used by {{site.base_gateway}} include:

* Data store usernames and passwords, used with PostgreSQL and Redis
* Private X.509 certificates
* API keys
* Sensitive configuration fields, generally used for authentication, hashing, signing, or encryption

## Vault use cases

Vaults allow you to securely store and then reference secrets from within other entities. This ensures that secrets aren't visible in plaintext throughout the platform, in places such as `kong.conf`,
declarative configuration files, logs, or the UI.

For example, you could store a certificate and a key in a Vault, then reference them from a [Certificate entity](/gateway/entities/certificate/). This way, the certificate and key are not stored in the entity directly and are more secure.

## How do I add secrets to a Vault?

You can add secrets to Vaults in one of the following ways: 
* Environment variables
* {{site.konnect_short_name}} Config Store
* Supported third-party backend vault

The following table goes into detail about the different options you have:

{% feature_table %}
item_title: Backend
columns:
  - title: Kong Gateway OSS
    key: oss
  - title: Kong Gateway Enterprise
    key: enterprise
  - title: Uses Vault entity
    key: uses_vault
  - title: Konnect supported
    key: supports_konnect

features:
  - title: Environment variable
    url: /how-to/store-secrets-as-env-variables/
    oss: true
    enterprise: true
    uses_vault: false
    supports_konnect: true
  - title: Konnect Config Store
    url: /how-to/store-secrets-in-konnect-config-store/
    oss: false
    enterprise: false
    uses_vault: true
    supports_konnect: true
  - title: AWS Secrets Manager
    url: /how-to/configure-aws-secrets-manager-as-a-vault-backend/
    oss: false
    enterprise: true
    uses_vault: true
    supports_konnect: true
  - title: Azure Key Vaults
    url: /how-to/configure-azure-key-vaults-as-a-vault-backend/
    oss: false
    enterprise: true
    uses_vault: true
    supports_konnect: true
  - title: Google Cloud Secret
    url: /how-to/configure-google-cloud-secret-as-a-vault-backend/
    oss: false
    enterprise: true
    uses_vault: true
    supports_konnect: true
  - title: Hashicorp Vault
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
    oss: false
    enterprise: true
    uses_vault: true
    supports_konnect: true
{% endfeature_table %}

## How do I reference secrets stored in a Vault

When you want to use a secret stored in a Vault, you can reference the secret with a `vault` reference. You can use the `vault` reference in places such as `kong.conf`, declarative configuration files, logs, or in the UI.

A secret reference points to a string value. No other data types are currently supported.

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

## Secret rotation in Vault

By default, {{site.base_gateway}} automatically rotates secrets *once every minute* in the background. You can also configure how often {{site.base_gateway}} rotates secrets using the Vault entity configuration. 

There are two types of rotation configuration available: 
* Rotate periodically using TTLs (for example: check for a new TLS certificate once per day)
* Rotate on failure (for example: on a database authentication failure, check if the secrets were updated, and try again)

For more information, see [Secret rotation](/gateway/secrets-management/secret-rotation/).

## Schema

The Vault entity can only be used once the database is initialized. Secrets for values that are used before the database is initialized can’t make use of the Vaults entity.

{% entity_schema %}

## Set up a Vault

{% entity_example %}
type: vault
data:
  config:
    prefix: MY_SECRET_
  description: ENV vault for secrets
  name: env
  prefix: my-env-vault
{% endentity_example %}




