---
title: "Principals and directories"
content_type: reference
layout: reference
permalink: /identity/principals/
products:
  - konnect

works_on:
  - konnect

breadcrumbs:
  - /identity/

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

* **Principal:** Represents an entity that authenticates to a Kong product. 
  The entity can be a human, a workload acting on behalf of a human, or a workload acting on behalf of itself.
* **Directory:** Regional collection of principals. 
  Each {{site.konnect_short_name}} organization gets one directory per region.

Principals can be used for {{site.base_gateway}} in {{site.konnect_short_name}}, {{site.event_gateway_short}}, and {{site.dev_portal}}.

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

### Credentials

Credentials are secrets a principal presents at authentication time. The gateway checks them directly against the directory.

Kong Identity supports the following credential types:

* **Username and password**: A principal can have up to two passwords per username to support rotation.
* **API key**: Each API key must be unique within a directory.

A single principal can have multiple credentials, including multiple credentials of the same type. To authenticate using a credential, a principal must exist in the target directory with a matching credential set.

### Identities

Identities are references to how a principal is known in other systems. 
They are used for lookup after authentication has already happened somewhere else, like a third-party IdP.

Kong Identity supports the following identity types:

* **Kong Identity OAuth client**: A Kong Identity OAuth client that can authenticate this principal.
* **Remote OAuth client**: An OAuth client managed by a different IdP, such as Okta or Cognito, identified by the combination of `iss` and `sub`.
* **Custom**: An identifier defined in a remote registry such as an asset management system, with a customer-defined name and value (for example, `workload_id` = `wl-0042`).

A single principal can have multiple identities, including multiple of the same type.

### Metadata

Metadata is a set of key/value pairs attached to a principal. Values can be strings, integers, floats, booleans, datetimes, or lists of any of those types.

Metadata is what makes a principal useful for policy decisions. A rate limiting plugin can filter by `principal.metadata.tier`. An ACL plugin can allow access only when `principal.metadata.business_unit == "payments"`. A logging plugin can include `principal.metadata.region` in every log line.

For more on how metadata drives plugin behavior, see [Principals and plugins](#principals-and-plugins).

### Principal example use case

Consider a payments platform with two types of clients to authenticate: internal workloads they own, and partner applications authenticated by their corporate IdP.

They would configure the internal principal like the following:

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "Display name"
    value: "`invoicing-service`"
  - field: "Credential (username and password)"
    value: "`invoicing-svc` / `s3cr3t`"
  - field: "Identity (custom)"
    value: "name = `workload_id`, value = `wl-0042`"
  - field: "Metadata"
    value: "`business_unit = payments`, `tier = internal`"
{% endtable %}

When this workload authenticates, the gateway checks the credential against the directory, finds the matching principal, and loads the metadata into the request context. A rate limiting plugin scoped to `principal.metadata.tier == "internal"` then takes effect.

They would also configure a principal for the partner application authenticated by a third-party IdP like the following:

{% table %}
columns:
  - title: Field
    key: field
  - title: Value
    key: value
rows:
  - field: "Display name"
    value: "`partner-app`"
  - field: "Credential"
    value: "none"
  - field: "Identity (remote OAuth client)"
    value: "`iss = https://idp.example.com`, `sub = partner-app`"
  - field: "Metadata"
    value: "`business_unit = lending`, `tier = partner`, `rate_limit_override = 500`"
{% endtable %}

For the partner principal, there is no credential. 
The third-party IdP performs the authentication, and the identity is the lookup handle Kong Identity uses to find the matching principal and return its metadata. The lookup handle is used after the OIDC plugin verifies the token against the IdP's JWKS.
The partner's tokens are issued by an external IdP with `iss: https://idp.example.com` and `sub: partner-app`.

## Principal entity mapping

Principals centralize the concept of an authenticating entity across Kong products. 
Each product has its own representation of who is authenticating: {{site.base_gateway}} has Consumers and {{site.dev_portal}} has applications:

* **Consumers**: A principal can map to one Consumer per gateway workspace and up to 100 Consumer Groups. When an authentication plugin authenticates a principal, the mapped Consumer and Consumer Groups load into the request context just as if the Consumer had been authenticated directly. This lets existing Consumer-scoped plugins keep working while you migrate to principals.
* **Applications**: A {{site.dev_portal}} application can be mapped to a {{site.base_gateway}} Consumer through a principal, creating a 1:1:1 relationship between the application, the principal, and the Consumer. This is how you apply Consumer-scoped plugins (including ACE and KAA) to traffic from a {{site.dev_portal}} application: configure the plugin on the mapped Consumer, and it runs for any request authenticated as the application. Consumer-dimension analytics also include the application's activity once the mapping is in place. A Portal Admin maps an existing application to an existing Consumer; Kong Identity creates or updates the principal of type `application` behind the scenes.

### When to use principals instead of Consumers

The existing {{site.base_gateway}} Consumer mechanism has known limitations. 
Principals address them in the following ways:

* **Scale beyond Consumer limits.** Users with large populations of authenticating entities can exceed the [Consumer and Consumer Group control plane limits](/gateway/control-plane-resource-limits/). Consumers are loaded into data plane memory; principals are loaded on demand when they authenticate.
* **Share identity across gateways without manual sync.** When the same entity needs to authenticate to multiple gateways, Consumers must be replicated. A principal lives in one directory and can be referenced from any gateway in the same region.
* **Unify identity across Kong products.** Consumers and applications each represent the same logical entity in different ways, which makes it hard to reason about authentication, policy, and observability together. Principals replace that with one model.
* **Attach metadata to identity.** Consumers don't support metadata, which forces custom plugins or header-injection workarounds when you want per-entity rate limits, conditional plugin behavior, or richer logs. Principals support metadata natively.

If you have existing Consumers you want to migrate to principals, see [HOW TO PLACEHOLDER](/).

## Apply plugins to principals

Plugins can read principal attributes from the request context after authentication. 
The only way to scope plugins to a principal is by using conditional plugin execution on the principal metadata.

For example, a rate limiting plugin scoped to gold-tier principals would use a condition like this:

```yaml
condition: principal.metadata.tier == "gold"
```

The following request context fields are available to plugins after a principal is authenticated:

* `principal.id`: The UUID of the principal
* `principal.metadata.*`: Any metadata key on the principal
* `principal.identities.*`: Any identity on the principal

Specific plugins, including ACL, rate limiting, logging, and OpenTelemetry, can scope their behavior by principal natively. See each plugin's reference for the exact configuration.

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
{% navtab "UI" %}

UI steps will be added once the feature is available for testing.

{% endnavtab %}
{% navtab "API" %}

API steps will be added once the feature is available for testing.

{% endnavtab %}
{% navtab "Terraform" %}

Terraform steps will be added once the feature is available for testing.

{% endnavtab %}
{% endnavtabs %}
