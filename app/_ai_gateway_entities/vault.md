---
title: AI Vaults
content_type: reference
entities:
  - ai-vault
products:
  - ai-gateway
description: Vaults for storing and referencing secrets used by {{site.ai_gateway}} entities.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayVault
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
  - text: Provider entity
    url: /ai-gateway/entities/provider/
  - text: Model entity
    url: /ai-gateway/entities/model/
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
faqs:
  - q: How is an {{site.ai_gateway}} Vault different from a {{site.base_gateway}} Vault?
    a: |
      The runtime entity is the same secret-management abstraction. The {{site.ai_gateway}} surface
      manages Vaults through the AI entity convention (`display_name`, `name`, `description`,
      `labels`) and exposes them at the `/ai/vaults` API alongside the other AI entities.

  - q: Which secret backends are supported?
    a: |
      The `type` field selects the backend: `env`, `aws`, `gcp`, `azure`, `conjur`, or `hcv`.
      Each type carries its own `config` shape. HashiCorp Vault (`hcv`) further selects an
      `auth_method` from `token`, `cert`, `jwt`, `approle`, `kubernetes`, `gcp_iam`, `gcp_gce`,
      `aws_ec2`, `aws_iam`, or `azure`.

  - q: How are Vault secrets referenced from other {{site.ai_gateway}} entities?
    a: |
      Sensitive fields on Provider, Model, MCP Server, and other entities are annotated as
      referenceable. Set those fields to a vault reference string (for example, a `{vault://...}`
      placeholder) instead of a literal value. The Vault `name` is the lookup key.

  - q: What does `name` control?
    a: |
      `name` is a user-defined unique identifier and the stable handle used to look up the Vault
      configuration when other entities reference secrets. Renaming a Vault breaks any reference
      pointing at the old value.
---

## What is a Vault?

A Vault is a first-class {{site.ai_gateway}} entity that registers a secret-management backend so that other entities (Providers, Models, MCP Servers) can reference secrets instead of embedding values directly.

A Vault entity stores the connection configuration and credentials needed to reach the backend. {{site.ai_gateway}} resolves vault references against the registered Vaults at request time.

Vaults can be created and managed through {{site.konnect_short_name}}, the on-prem Admin API, decK, or the {{site.konnect_short_name}} UI:

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
    endpoint: /v1/ai-gateways/{aiGatewayId}/vaults
  - deployment: On-prem
    cp: Admin API
    endpoint: /ai/vaults
{% endtable %}

## Backends

Each Vault selects one of the supported secret backends — environment variables, AWS Secrets Manager, Google Secret Manager, Azure Key Vault, CyberArk Conjur, or HashiCorp Vault. The connection details vary per backend; the {{site.konnect_short_name}} UI surfaces the relevant fields based on the backend you choose.

HashiCorp Vault additionally supports several authentication methods (token, AppRole, JWT, Kubernetes, AWS, GCP, Azure, and others). See the [{{site.base_gateway}} Vault entity](/gateway/entities/vault/) for backend-specific guidance that applies to both deployment modes.

## Caching

Cloud-backed vault types (`aws`, `gcp`, `azure`, `conjur`, `hcv`) cache resolved secrets so that {{site.ai_gateway}} doesn't hit the backend on every reference. Cache duration, negative-lookup caching, and how long expired secrets stay in use during backend outages are all tunable. The `env` type doesn't cache because environment-variable lookups don't hit the network.

## Set up a Vault

The following example registers an environment-variable vault that resolves references against process environment variables prefixed with `KONG_`.

{% entity_example %}
type: vault
data:
  display_name: Production Env Vault
  name: prod-env-vault
  description: Vault for production secrets sourced from environment variables.
  type: env
  config:
    prefix: KONG_
{% endentity_example %}

## Schema

{% entity_schema %}
