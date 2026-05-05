---
title: AI Consumer Credentials
content_type: reference
entities:
  - ai-consumer-credential
products:
  - ai-gateway
description: Credentials issued to AI Consumers for authenticating to {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayConsumerCredential
works_on:
  - konnect
  - on-prem
tools:
  - deck
  - admin-api
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Consumer entity
    url: /ai-gateway/entities/consumer/
  - text: Consumer Group entity
    url: /ai-gateway/entities/consumer-group/
  - text: Policy entity
    url: /ai-gateway/entities/policy/
faqs:
  - q: Why are credentials a separate entity instead of a field on the Consumer?
    a: |
      Each credential has its own lifecycle, identifier, and (for API keys) TTL. Modeling them as
      a sub-entity of the Consumer lets you list, rotate, and revoke individual credentials
      independently of the Consumer record.

  - q: What credential types are supported?
    a: |
      Two types: `api-key` and `oauth`. The `type` of the Credential must match the Consumer's
      `type`. An `api-key` credential carries the `api_key` value (and an optional `ttl`). An
      `oauth` credential carries a `custom_id` that maps to the OAuth provider's identifier.

  - q: Can a Consumer have multiple credentials?
    a: |
      Yes. Issue one Credential per environment, client, or rotation cycle, and revoke individual
      Credentials without affecting the others.

  - q: Is the API key value visible after creation?
    a: |
      No. The `api_key` field is write-only; subsequent reads return the Credential's metadata
      (`name`, `display_name`, `ttl`, timestamps) but not the secret. Distribute the key value at
      creation time, and rotate by issuing a new Credential and revoking the old one.

  - q: What's the relationship between `ttl` and the Consumer's lifecycle?
    a: |
      `ttl` controls how long the API key value remains valid in seconds. When it elapses, the
      Credential stops authenticating but the Credential record (and the parent Consumer) remain.
      Issue a new Credential to keep the Consumer authenticating.
---

## What is a Consumer Credential?

A Consumer Credential is the {{site.ai_gateway}} entity that represents the secret material a [Consumer](/ai-gateway/entities/consumer/) presents to authenticate to {{site.ai_gateway}}.

Credentials are nested under their owning Consumer: each Credential belongs to exactly one Consumer, and removing the Consumer removes its Credentials.

Consumer Credentials are managed through the {{site.ai_gateway}} entity API surface in both deployment modes:

{% table %}
columns:
  - title: Deployment
    key: deployment
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - deployment: "{{site.konnect_short_name}}"
    cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/consumers/{consumerId}/credentials
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/consumers/{consumerId}/credentials
{% endtable %}

## Credential types

The `type` field on a Credential must match the parent Consumer's `type`:

* **`api-key`**: the Credential carries an `api_key` value the client presents on each request. An optional `ttl` (seconds) bounds the validity period; once it elapses, the value no longer authenticates.
* **`oauth`**: the Credential carries a `custom_id` that maps to the OAuth provider's identifier (for example, an OIDC Client ID). The actual token is issued and validated by the OAuth provider, not stored on the Credential.

The `api_key` field is write-only and cannot be retrieved after creation. Treat creation responses as the only opportunity to capture the key value.

## Lifecycle

Each Credential has its own UUID and is independently listable, gettable, and deletable through the nested endpoints under its parent Consumer. There's no PUT operation: rotation is an explicit "create new, delete old" flow, which avoids long-lived stale references.

Deleting a Credential immediately stops authenticating that key. Deleting the parent Consumer removes all of its Credentials.

## Set up an API key Credential

The following example issues a 24-hour API key credential to an existing Consumer named `mobile-app-production`.

{% entity_example %}
type: consumer-credential
data:
  display_name: Mobile App - Dev Key
  name: mobile-app-dev-key
  type: api-key
  api_key: <your-api-key>
  ttl: 86400
{% endentity_example %}

{:.warning}
> Don't commit `api_key` values to source control. Inject them at creation time from a
> secret-management system, and treat any value checked into a configuration file as compromised.

## Set up an OAuth Credential

The following example issues an OAuth credential that maps an external OIDC client ID to a Consumer.

{% entity_example %}
type: consumer-credential
data:
  display_name: Mobile App - OIDC Mapping
  name: mobile-app-oidc-mapping
  type: oauth
  custom_id: 0oatibf4t2PlDxqgR1d7
{% endentity_example %}

## Schema

{% entity_schema %}
