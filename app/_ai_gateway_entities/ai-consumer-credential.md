---
title: AI Consumer Credentials
content_type: reference
entities:
  - ai-consumer-credential
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-consumer-credential/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: Credentials issued to AI Consumers for authenticating to {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayConsumerCredential
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
faqs:
  - q: Why are credentials a separate entity instead of a field on the Consumer?
    a: |
      Each credential has its own lifecycle, identifier, and (for API keys) TTL. Modeling them as
      a sub-entity of the Consumer lets you list, rotate, and revoke individual credentials
      independently of the Consumer record.

  - q: What credential types are supported?
    a: |
      Two types: `api-key` and `oauth`. The [`type`](#schema-aigateway-consumer-credential-type) of the Credential must match the Consumer's
      `type`. An `api-key` credential carries the [`api_key`](#schema-aigateway-consumer-credential-api-key) value (and an optional [`ttl`](#schema-aigateway-consumer-credential-ttl)). An
      `oauth` credential is paired with a Consumer that maps to an OAuth identity through the Consumer's `custom_id` field.

  - q: Can a Consumer have multiple credentials?
    a: |
      Yes. Issue one Credential per environment, client, or rotation cycle, and revoke individual
      Credentials without affecting the others.

  - q: Is the API key value visible after creation?
    a: |
      No. The [`api_key`](#schema-aigateway-consumer-credential-api-key) field is write-only; subsequent reads return the Credential's metadata
      ([`name`](#schema-aigateway-consumer-credential-name), [`display_name`](#schema-aigateway-consumer-credential-display-name), [`ttl`](#schema-aigateway-consumer-credential-ttl), timestamps) but not the secret. Distribute the key value at
      creation time, and rotate by issuing a new Credential and revoking the old one.

  - q: What's the relationship between `ttl` and the Consumer's lifecycle?
    a: |
      [`ttl`](#schema-aigateway-consumer-credential-ttl) controls how long the API key value remains valid in seconds. When it elapses, the
      Credential stops authenticating but the Credential record (and the parent Consumer) remain.
      Issue a new Credential to keep the Consumer authenticating.
---

## What is an AI Consumer Credential?

An AI Consumer Credential is the {{site.ai_gateway}} entity that represents the secret material an [AI Consumer](/ai-gateway/entities/ai-consumer/) presents to authenticate to {{site.ai_gateway}}.

Credentials are nested under their owning AI Consumer: each Credential belongs to exactly one AI Consumer, and removing the AI Consumer removes its Credentials.

Consumer Credentials are managed through the {{site.ai_gateway}} entity API:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/consumers/{consumerId}/credentials
{% endtable %}

## Credential types

The [`type`](#schema-aigateway-consumer-credential-type) field on a Credential must match the parent Consumer's `type`:

* **`api-key`**: the Credential carries an [`api_key`](#schema-aigateway-consumer-credential-api-key) value the client presents on each request. An optional [`ttl`](#schema-aigateway-consumer-credential-ttl) (seconds) bounds the validity period; once it elapses, the value no longer authenticates.
* **`oauth`**: the Credential type for OAuth Consumers. The parent Consumer's `custom_id` field maps to an OAuth identity issued by an external provider. {{site.ai_gateway}} works with any standards-compliant OAuth 2.0 / OpenID Connect provider configured through the [OpenID Connect AI Policy](/ai-gateway/policies/openid-connect/), or, for MCP traffic, the [AI MCP OAuth2 AI Policy](/ai-gateway/policies/ai-mcp-oauth2/). The `custom_id` is typically the OIDC `sub` claim or the Client ID issued by the OAuth provider. The actual access token is issued and validated by the OAuth provider, not stored on the Credential.

The [`api_key`](#schema-aigateway-consumer-credential-api-key) field is write-only and cannot be retrieved after creation. Treat creation responses as the only opportunity to capture the key value.

## Lifecycle

Each Credential has its own UUID and supports independent list, get, and delete operations through the nested endpoints under its parent AI Consumer. There is no `PUT` operation: rotation is an explicit "create new, delete old" flow, which avoids long-lived stale references.

Deleting a Credential immediately stops it from authenticating. Deleting the parent AI Consumer removes all of its Credentials.

## Set up an API key Credential

The following example issues a 24-hour API key credential to an existing Consumer named `mobile-app-production`.

{% entity_example %}
type: consumer_credential
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

The following example issues an OAuth credential that maps an external OIDC client ID to an AI Consumer.

{% entity_example %}
type: consumer_credential
data:
  display_name: Mobile App - OIDC Mapping
  name: mobile-app-oidc-mapping
  type: oauth
  custom_id: 0oatibf4t2PlDxqgR1d7
{% endentity_example %}

## Schema

{% entity_schema %}
