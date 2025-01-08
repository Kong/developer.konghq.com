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
  - q: 
    a: 

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
    path: /schemas/Vaults
---

what is a vault + why
schema
best practices
hint of secrets management (link to landing page) (/secrets-management/)
link to backends
link to Vault CLI ref

## What is a Vault?
In {{site.base_gateway}}, the Vault object is used to store secrets. A secret is any sensitive piece of information required for API gateway
operations. Secrets may be part of the core {{site.base_gateway}} configuration,
they may be used in plugins, or they might be part of configuration associated
with APIs serviced by the gateway.

Some of the most common types of secrets used by {{site.base_gateway}} include:

* Data store usernames and passwords, used with PostgreSQL and Redis
* Private X.509 certificates
* API keys
* Sensitive plugin configuration fields, generally used for authentication, hashing, signing, or encryption.

## Vault use cases

Storing secrets in a Vault ensures they are protected and allows you to reference secrets from other entities. By storing sensitive values as secrets, you ensure that they are not
visible in plaintext throughout the platform, in places such as `kong.conf`,
in declarative configuration files, logs, or in the Kong Manager UI.

For example, you could store a certificate and a key in a Vault, then reference them from a [Certificate entity](/gateway/entities/certificate/). This way, the certificate and key are not stored in the entity directly and are more secure.

## How do I add secrets to a Vault?

Vaults are an object that stores secrets, it doesn't create secrets. You must add those secrets with environment variables, {{site.konnect_short_name}} Config Store, or a supported third-party backend vault.

The following table describes the different options you have:

| Backend | {{site.base_gateway}} OSS | {{site.base_gateway}} Enterprise | Uses Vault entity | {{site.konnect_short_name}} supported |
|--------|--------------------|----------------|--------------|---------------|
| [Environment variable](/how-to/store-secrets-as-env-variables) | {% include icon_true.html %} | {% include icon_true.html %} | {% include icon_false.html %}| {% include icon_true.html %} |
| [{{site.konnect_short_name}} Config Store](/how-to/store-secrets-in-konnect-config-store) | {% include icon_false.html %}| {% include icon_false.html %}| {% include icon_true.html %} | {% include icon_true.html %}|
| [AWS Secrets Manager](/how-to/configure-aws-secrets-manager-as-a-vault-backend) | {% include icon_false.html %}| {% include icon_true.html %} | {% include icon_true.html %} | {% include icon_true.html %}|
| [Azure Key Vaults](/how-to/configure-azure-key-vaults-as-a-vault-backend) | {% include icon_false.html %} | {% include icon_true.html %}| {% include icon_true.html %}| {% include icon_true.html %}|
| [Google Cloud Secret](/how-to/configure-google-cloud-secret-as-a-vault-backend) | {% include icon_false.html %} | {% include icon_true.html %}| {% include icon_true.html %}| {% include icon_true.html %}|
| [Hashicorp Vault](/how-to/configure-hashicorp-vault-as-a-vault-backend) | {% include icon_false.html %} | {% include icon_true.html %}| {% include icon_true.html %}| {% include icon_true.html %}|


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
Kong receives the payload and extracts the `"username"` value of `"john"` for the secret reference of
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
  name: env
  description: 'ENV vault for secrets'
  config:
    prefix: SECRET_
{% endentity_example %}


## Vault best practices

When managing Vaults with declarative configuration, you need to take certain precautions.
For larger teams with many contributors, or organizations with multiple teams,
we recommend splitting Vault configuration and managing it separately.

**Why split out Vault configuration?**

* Vault are closer to infrastructure than other {{site.base_gateway}} configurations.
Separation of routing policies from infrastructure-specific configurations helps
keep configuration organized.
* Vaults may be shared across teams. In this case, one specific team shouldn't
control the Vault's configuration. One team changing the Vault a can have
disastrous impact on another team.
* If a Vault is deleted while in use -- that is, if there are still references to
secrets in a Vault in configuration -- it can lead to total loss of proxy capabilities.
Those secrets would be unrecoverable.

**How should I manage my Vault configuration with decK?**

To keep your environment secure and avoid taking down your proxies by accident, make sure to:

* Manage Vaults with distributed configuration via tags.
* Use a separate [RBAC role, user, and token](/gateway/api/admin-ee/latest/#/rbac/get-rbac-users/)
to manage Vaults. Don't use a generic admin user.
* Set up a separate CI pipeline for Vaults.

## Vault backends

