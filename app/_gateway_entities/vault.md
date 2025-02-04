---
title: Vaults
content_type: reference
entities:
  - vault

description: A Vault is used to store secrets.

related_resources:
  - text: Secrets Management
    url: /gateway/secrets-management/
  - text: Workspaces
    url: /gateway/entities/workspace/
  - text: RBAC
    url: /gateway/entities/rbac/


faqs:
  - q: What types of fields can be used in Vaults?
    a: Vaults work with "referenceable" fields. All fields in `kong.conf` are referenceable and some fields within entities (for example, plugins, certificates) are also. Refer to the appropriate entity documentation to learn more.
  - q: Can Vaults be referenced during custom plugin development?
    a: Yes. The plugin development kit (PDK) offers a Vaults module (`kong.vault`) that can be used to resolve, parse, and verify Vault references.
  - q: What data types can I use when referencing a secret in a Vault?
    a: A secret reference points to a string value. No other data types are currently supported.

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

Vaults allow you to securely store and then reference secrets from within other entities. This ensures that secrets aren't visible in plaintext throughout the platform, in places such as `kong.conf`,
declarative configuration files, logs, or the UI.

For example, you could store a certificate and a key in a Vault, then reference them from a [Certificate entity](/gateway/entities/certificate/). This way, the certificate and key are not stored in the entity directly and are more secure.

## How do I add secrets to a Vault?

You can add secrets to Vaults in one of the following ways:
* Environment variables
* {{site.konnect_short_name}} Config Store
* Supported third-party backend vault

## What can be stored as a secret?

You can store and reference the following as secrets in a Vault:

* All [`kong.conf` values](/gateway/manage-kong-conf/)<sup>1</sup>. For example:
  * Data store usernames and passwords, used with PostgreSQL and Redis
  * Private X.509 certificates
* Certificates and keys stored in the [Certificate {{site.base_gateway}} entity](/gateway/entities/certificate/)
* [{{site.base_gateway}} license](/gateway/entities/license/)<sup>2</sup>
* Referenceable plugin fields, such as third-party API keys (see table below for all values)

{:.info}
> **{{site.konnect_short_name}} Config Store limitations:**
> * <sup>1</sup>: You can't reference secrets stored in a [{{site.konnect_short_name}} Config Store](/how-to/configure-the-konnect-config-store/) Vault in `kong.conf` because {{site.konnect_short_name}} resolves the secret after {{site.base_gateway}} connects to the control plane.
> * <sup>2</sup>: In Konnect, the {{site.base_gateway}} license is managed and stored by {{site.konnect_short_name}}, and doesn't need to be stored manually in any Vault.

### Referenceable plugin fields

The following plugin fields can be stored and referenced as secrets:

{% referenceable_fields %}

## Supported Vault backends

Each vault has its own required configuration. You can provide this configuration by creating a Vault entity, or by configuring specific environment variables before starting {{ site.base_gateway }}.

For more information, choose a Vault below to see the specific configuration required.

{% feature_table %}
item_title: Backend
columns:
  - title: {{site.base_gateway}} OSS
    key: oss
  - title: {{site.ee_product_name}}
    key: enterprise
  - title: {{site.konnect_short_name}} supported
    key: supports_konnect

features:
  - title: Environment variable
    url: /gateway/entities/vault/#store-secrets-as-environment-variables
    oss: true
    enterprise: true
    supports_konnect: true
  - title: Konnect Config Store
    url: /how-to/configure-the-konnect-config-store/
    oss: false
    enterprise: false
    supports_konnect: true
  - title: AWS Secrets Manager
    url: /how-to/configure-aws-secrets-manager-as-a-vault-backend-with-vault-entity/
    oss: false
    enterprise: true
    supports_konnect: true
  - title: Azure Key Vaults
    url: /how-to/configure-azure-key-vaults-as-a-vault-backend-with-vault-entity/
    oss: false
    enterprise: true
    supports_konnect: true
  - title: Google Cloud Secret
    url: /how-to/configure-google-cloud-secret-as-a-vault-backend/
    oss: false
    enterprise: true
    supports_konnect: true
  - title: Hashicorp Vault
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/
    oss: false
    enterprise: true
    supports_konnect: true
{% endfeature_table %}

## How do I reference secrets stored in a Vault?

When you want to use a secret stored in a Vault, you can reference the secret with a `vault` reference. You can use the `vault` reference in places such as `kong.conf`, declarative configuration files, logs, or in the UI.

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

Vault references must be used for the whole referenced value. 
Imagine that you're calling a service application with the authentication token `ABC123`:

{% feature_table %}
item_title: Works
columns:
  - title: Configuration Value
    key: config
  - title: Vault Value
    key: vault
features:
  - title: ❌
    config: 'Bearer {vault://hcv/myservice-auth-token}'
    vault: ABC123
  - title: ✅
    config: '{vault://hcv/myservice-auth-token}'
    vault: Bearer ABC123
{% endfeature_table %}

## Secret rotation in Vaults

By default, {{site.base_gateway}} automatically refreshes secrets *once every minute* in the background. 
You can also configure how often {{site.base_gateway}} refreshes secrets using the Vault entity configuration.

There are two types of refresh configuration available:
* Refresh periodically using TTLs: For example, check for a new TLS certificate once per day.
* Refresh on failure: For example, on a database authentication failure, check if the secrets were updated, and try again.

For more information, see [Secret management](/gateway/secrets-management/).

## Best practices for Vaults

@TODO: Move this to deck docs when available

### General best practices

To keep your environment secure and avoid taking down your proxies by accident, make sure to:
* Manage Vaults with distributed configuration via tags.
* Use a separate [RBAC role, user, and token](/gateway/entities/rbac/).
to manage Vaults. Don't use a generic admin user.
* Set up a separate CI pipeline for Vaults.

### Best practices for managing Vaults using decK

For larger teams with many contributors, or organizations with multiple teams, we recommend splitting Vault configurations into separate files and managing them isolated from other [entities'](/gateway/entities/) configuration using tags. We recommend splitting the configuration for the following reasons:
* Vaults are closer to infrastructure than other {{site.base_gateway}} configurations. Separation of routing policies from infrastructure-specific configurations helps keep configuration organized.
* Vaults may be shared across teams. In this case, one specific team shouldn't control the Vault's configuration. One team changing the Vault a can have a negative impact on another team.
* If a Vault is deleted while in use -- that is, if there are still references to secrets in a Vault in configuration -- it can lead to total loss of proxy capabilities. Those secrets would be unrecoverable.

## Schema

The Vault entity can only be used once the database is initialized. Secrets for values that are used before the database is initialized can’t make use of the Vaults entity.

{% entity_schema %}

## Set up a Vault

{% entity_example %}
type: vault
data:
  name: env
  description: ENV vault for secrets
  prefix: my-env-vault
  config:
    prefix: MY_SECRET_
{% endentity_example %}

## Store secrets as environment variables

You can store secrets as environment variables instead of configuring a Vault entity or third-party backend vault. 

<!--vale off-->

| Use case | Environment variable example | Secret reference example |
|-------|-------------|-------------|
| Single secret value | `export MY_SECRET_VALUE=example-secret` | `{vault://env/my-secret-value}` |
| Multiple secrets (flat JSON string) | `export PG_CREDS='{"username":"user", "password":"pass"}'` | `{vault://env/pg-creds/username}`<br><br>`{vault://env/pg-creds/password}` | 

<!--vale on-->




