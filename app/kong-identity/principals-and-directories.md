---
title: "Principals and directories"
content_type: reference
layout: reference

products:
  - konnect

works_on:
  - konnect

breadcrumbs:
  - /kong-identity/

description: "Learn how Kong Identity principals and directories represent authenticating entities and centralize identity, credentials, and metadata across {{site.base_gateway}}, {{site.event_gateway_short}}, and {{site.dev_portal}}."

related_resources:
  - text: "Kong Identity"
    url: /kong-identity/
  - text: "Centrally-managed Consumers"
    url: /gateway/entities/consumer/#centrally-managed-consumers
  - text: "{{site.konnect_short_name}} control plane resource limits"
    url: /gateway/control-plane-resource-limits/
---

Kong Identity uses principals and directories to unify how Kong products represent the entities they authenticate. 

A principal represents an entity that authenticates to a Kong product. 
The entity can be a human, a workload acting on behalf of a human, or a workload acting on behalf of itself.

A directory is a regional collection of principals. 
Each {{site.konnect_short_name}} organization gets one directory per region.

The following table describes when you'd want to use principals:

{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: "Authenticate clients"
    description: "Terminate authentication at the gateway using credentials stored on a principal, such as a username and password or an API key."
  - usecase: "Hydrate metadata after external authentication"
    description: "After a third-party IdP verifies an OAuth token, look up the matching principal in a directory to retrieve metadata for policy decisions."
  - usecase: "Share identity across Kong products"
    description: "Define a principal once and use it for {{site.base_gateway}}, {{site.event_gateway_short}}, and {{site.dev_portal}} without manually synchronizing identities."
  - usecase: "Drive gateway behavior with metadata"
    description: "Scope rate limits, ACLs, and conditional plugin execution by attributes that the principal carries, such as business unit or tier."
{% endtable %}

## What lives on a principal

Every principal carries some combination of credentials, identities, and metadata. 
* Credentials are secrets a principal presents at authentication time.
* Identities are references to how a principal is known in other systems.
* Metadata is a set of key/value pairs attached to a principal.

### Credentials

Credentials are secrets a principal presents at authentication time. The gateway checks them directly against the directory.

Kong Identity supports the following credential types:

* **Username and password**: A principal can have up to two passwords per username to support rotation.
* **API key**: Each API key must be unique within a directory.

A single principal can have multiple credentials, including multiple credentials of the same type. To authenticate using a credential, a principal must exist in the target directory with a matching credential set.

### Identities

Identities are references to how a principal is known in other systems. They are not secrets, and they don't prove anything on their own. Identities are used for lookup after authentication has already happened somewhere else.

Kong Identity supports the following identity types:

* **Kong Identity OAuth client**: A Kong Identity OAuth client that can authenticate this principal.
* **Remote OAuth client**: An OAuth client managed by a different IdP, such as Okta or Cognito, identified by the combination of `iss` and `sub`.
* **Custom**: An identifier defined in a remote registry such as an asset management system, with a customer-defined name and value (for example, `workload_id` = `wl-0042`).

A single principal can have multiple identities, including multiple of the same type.

### Metadata

Metadata is a set of key/value pairs attached to a principal. Values can be strings, integers, floats, booleans, datetimes, or lists of any of those types.

Metadata is what makes a principal useful for policy decisions. A rate limiting plugin can filter by `principal.metadata.tier`. An ACL plugin can allow access only when `principal.metadata.business_unit == "payments"`. A logging plugin can include `principal.metadata.region` in every log line.

For more on how metadata drives plugin behavior, see [Principals and plugins](#principals-and-plugins).

### Principal example

Consider a payments platform with two types of clients to authenticate: internal workloads they own, and partner applications authenticated by their corporate IdP.

an internal workload using basic auth:

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
  - title: Purpose
    key: purpose
rows:
  - field: "Display name"
    value: "`invoicing-service`"
    purpose: "Observability"
  - field: "Credential (username and password)"
    value: "`invoicing-svc` / `s3cr3t`"
    purpose: "What the gateway checks at authentication time"
  - field: "Identity (custom)"
    value: "name = `workload_id`, value = `wl-0042`"
    purpose: "An asset management ID used for cross-referencing in logs, not for authentication"
  - field: "Metadata"
    value: "`business_unit = payments`, `tier = internal`"
    purpose: "Drives gateway behavior such as rate limiting and conditional plugin execution"
{% endtable %}

When this workload authenticates, the gateway checks the credential against the directory, finds the matching principal, and loads the metadata into the request context. A rate limiting plugin scoped to `principal.metadata.tier == "internal"` then takes effect.

a partner application authenticated by a third-party IdP:

The partner's tokens are issued by an external IdP with `iss: https://idp.example.com` and `sub: partner-app`.

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
  - title: Purpose
    key: purpose
rows:
  - field: "Display name"
    value: "`partner-app`"
    purpose: "Observability"
  - field: "Credential"
    value: "none"
    purpose: "Kong Identity never authenticates the partner directly. The third-party IdP does."
  - field: "Identity (remote OAuth client)"
    value: "`iss = https://idp.example.com`, `sub = partner-app`"
    purpose: "Lookup handle used after the OIDC plugin verifies the token against the IdP's JWKS"
  - field: "Metadata"
    value: "`business_unit = lending`, `tier = partner`, `rate_limit_override = 500`"
    purpose: "Drives gateway behavior"
{% endtable %}

For the partner principal, there is no credential at all. The third-party IdP performs the authentication, and the identity is the lookup handle Kong Identity uses to find the matching principal and return its metadata.

{:.info}
> **Credentials vs. identities:** The partner-application principal above has no credential, because the third-party IdP authenticates the token. The remote OAuth client identity is how Kong Identity recognizes the already-verified token and returns the principal's metadata. By contrast, the internal-workload principal has a credential (username and password) that the gateway checks directly. The same principal can hold both: you could add a Kong Identity OAuth client identity to the workload principal to give it a second authentication path.

## Principals and plugins

Plugins can read principal attributes from the request context after authentication. The most direct way to act on those attributes is conditional plugin execution: a plugin runs only when an expression evaluates to true.

For example, a rate limiting plugin scoped to gold-tier principals would use a condition like this:

```yaml
condition: principal.metadata.tier == "gold"
```

The following request context fields are available to plugins after a principal is authenticated:

* `principal.id`: the UUID of the principal
* `principal.metadata.*`: any metadata key on the principal
* `principal.identities.*`: any identity on the principal

Specific plugins, including ACL, rate limiting, logging, and OpenTelemetry, can scope their behavior by principal natively. See each plugin's reference for the exact configuration.

## Principal entity mapping

Principals align the concept of an authenticating entity across Kong products. Each product has its own representation of who is calling: {{site.base_gateway}} has Consumers, {{site.dev_portal}} has Applications, and metering has Subjects. Principals give you one identity layer underneath all of them.

### Principals and Consumers

A principal can map to one Consumer per gateway workspace and up to 100 Consumer Groups. When an authentication plugin authenticates a principal, the mapped Consumer and Consumer Groups load into the request context just as if the Consumer had been authenticated directly. This lets existing Consumer-scoped plugins keep working while you migrate to principals.

### Principals and {{site.dev_portal}} Applications

Every {{site.dev_portal}} Application has a corresponding principal in the default directory, and the Application and the principal share the same UUID. Application-driven authentication ties into the same identity layer that {{site.base_gateway}} and {{site.event_gateway_short}} use, so the same plugins and policies can apply to traffic from {{site.dev_portal}} Applications and from directly-managed principals.

### When to use principals instead of Consumers

The existing {{site.base_gateway}} Consumer mechanism has known limitations. Principals address them in the following ways:

* **Scale beyond Consumer limits.** Customers with large populations of authenticating entities can exceed the [Consumer and Consumer Group control plane limits](/gateway/control-plane-resource-limits/). Consumers are loaded into data plane memory; principals are loaded on demand when they authenticate.
* **Share identity across gateways without manual sync.** When the same entity needs to authenticate to multiple gateways, Consumers have to be replicated. A principal lives in one directory and can be referenced from any gateway in the same region.
* **Unify identity across Kong products.** Consumers, Applications, and Subjects each represent the same logical entity in different ways, which makes it hard to reason about authentication, policy, and observability together. Principals replace that with one model.
* **Attach metadata to identity.** Consumers don't support metadata, which forces custom plugins or header-injection workarounds when you want per-entity rate limits, conditional plugin behavior, or richer logs. Principals support metadata natively.

### Migration

placeholder

## Principal limitations

The following are default limits for principals and directories:

* 1 directory per region
* Soft limit of 100,000 principals per directory. Contact Kong to raise this limit.
* 10 identities per principal
* 5 of each credential type per principal
* 50 metadata keys per principal
* 2 passwords per username (for rotation)
* 100 Consumer Group mappings per principal
* Usernames must be unique within a directory
* API keys must be unique within a directory
* Custom identity name and value combinations must be unique within a directory
* `iss` and `sub` combinations must be unique within a directory

## Create a directory and principal

{% navtabs "create-principal" %}
{% navtab "{{site.konnect_short_name}} UI" %}

UI steps will be added once the feature is available for testing.

{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}

API steps will be added once the feature is available for testing.

{% endnavtab %}
{% navtab "Terraform" %}

Terraform steps will be added once the feature is available for testing.

{% endnavtab %}
{% endnavtabs %}
