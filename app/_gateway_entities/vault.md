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
  - q: How should I manage my Vault configuration with decK?
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
* Sensitive plugin configuration fields, generally used for authentication, hashing, signing, or encryption

## Vault use cases

The main use case for Vaults is that they allow you to securely store and then reference those secrets from other entities. This ensures that secrets aren't visible in plaintext throughout the platform, in places such as `kong.conf`,
in declarative configuration files, logs, or in the UI.

For example, you could store a certificate and a key in a Vault, then reference them from a [Certificate entity](/gateway/entities/certificate/). This way, the certificate and key are not stored in the entity directly and are more secure.

## How do I add secrets to a Vault?

Vaults store secrets, they don't create secrets. You must add secrets to the Vault in one of the following ways: 
* Environment variables
* {{site.konnect_short_name}} Config Store
* Supported third-party backend vault

The following table goes into detail about the different options you have:

| Backend                                                   | {{site.base_gateway}} OSS | {{site.base_gateway}} Enterprise | Uses Vault entity              | {{site.konnect_short_name}} supported |
| --------------------------------------------------------- | ------------------------ | -------------------------------- | ------------------------------ | ------------------------------------- |
| [Environment variable](/how-to/store-secrets-as-env-variables) | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/close.svg" alt="Cross icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">        |
| [{{site.konnect_short_name}} Config Store](/how-to/store-secrets-in-konnect-config-store) | <img src="/app/assets/icons/close.svg" alt="Cross icon"> | <img src="/app/assets/icons/close.svg" alt="Cross icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">        |
| [AWS Secrets Manager](/how-to/configure-aws-secrets-manager-as-a-vault-backend) | <img src="/app/assets/icons/close.svg" alt="Cross icon"> | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">        |
| [Azure Key Vaults](/how-to/configure-azure-key-vaults-as-a-vault-backend) | <img src="/app/assets/icons/close.svg" alt="Cross icon"> | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">        |
| [Google Cloud Secret](/how-to/configure-google-cloud-secret-as-a-vault-backend) | <img src="/app/assets/icons/close.svg" alt="Cross icon"> | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">        |
| [Hashicorp Vault](/how-to/configure-hashicorp-vault-as-a-vault-backend) | <img src="/app/assets/icons/close.svg" alt="Cross icon"> | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">   | <img src="/app/assets/icons/check.svg" alt="Check icon">        |


## How do I use secrets stored in a Vault?

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

## How do I manage secrets stored in a Vault?

Although {{site.base_gateway}} can't create or add secrets to a Vault, it can help you [manage your secrets](/secrets-management/). By default, {{site.base_gateway}} automatically rotates secrets *once every minute* in the background. You can also further configure how often {{site.base_gateway}} rotates secrets using the Vault entity configuration and if it rotates secrets on failure (such as a database authentication failure).

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




