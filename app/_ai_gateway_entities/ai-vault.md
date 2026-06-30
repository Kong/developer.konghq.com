---
title: AI Vaults
content_type: reference
entities:
  - ai-vault
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-vault/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: AI Vaults for storing and referencing secrets used by {{site.ai_gateway}} entities.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayVault
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Provider entity
    url: /ai-gateway/entities/ai-provider/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: "{{site.base_gateway}} Vault entity"
    url: /gateway/entities/vault/
faqs:
  - q: How is an {{site.ai_gateway}} AI Vault different from a {{site.base_gateway}} Vault?
    a: |
      The runtime entity is the same secret-management abstraction. The {{site.ai_gateway}} surface
      manages AI Vaults through the AI entity convention (`display_name`, `name`, `description`,
      `labels`) and exposes them through the {{site.konnect_short_name}} API alongside the other AI entities.

  - q: Which secret backends are supported?
    a: |
      The `type` field selects the backend: `konnect`, `env`, `aws`, `gcp`, `azure`, `conjur`, or `hcv`.
      Each type carries its own `config` shape. HashiCorp Vault (`hcv`) further selects an
      `auth_method` from `token`, `cert`, `jwt`, `approle`, `kubernetes`, `gcp_iam`, `gcp_gce`,
      `aws_ec2`, `aws_iam`, or `azure`.

  - q: How are AI Vault secrets referenced from other {{site.ai_gateway}} entities?
    a: |
      Sensitive fields on AI Provider, AI Model, AI MCP Server, and other entities are annotated as
      referenceable. Set those fields to a vault reference string (for example, a `{vault://...}`
      placeholder) instead of a literal value. The AI Vault `name` is the lookup key.

  - q: What does `name` control?
    a: |
      `name` is a user-defined unique identifier and the stable handle used to look up the AI Vault
      configuration when other entities reference secrets. Renaming an AI Vault breaks any reference
      pointing at the old value.
---

## What is an AI Vault?

An AI Vault is a first-class {{site.ai_gateway}} entity that registers a secret-management backend so that other entities (AI Providers, AI Models, AI MCP Servers) can reference secrets instead of embedding values directly.

An AI Vault entity stores the connection configuration and credentials needed to reach the backend. {{site.ai_gateway}} resolves vault references against the registered AI Vaults at request time.

AI Vaults can be created and managed through the {{site.konnect_short_name}} UI and the {{site.ai_gateway}} API:

{% table %}
columns:
  - title: Control Plane
    key: cp
  - title: Endpoint
    key: endpoint
rows:
  - cp: "{{site.konnect_short_name}} {{site.ai_gateway}} API"
    endpoint: /v1/ai-gateways/{aiGatewayId}/vaults
{% endtable %}

## Backends

Each AI Vault selects one of the supported secret backends: {{site.konnect_short_name}} Config Store, environment variables, AWS Secrets Manager, Google Secret Manager, Azure Key Vault, CyberArk Conjur, or HashiCorp Vault. The connection details vary per backend; the {{site.konnect_short_name}} UI surfaces the relevant fields based on the backend you choose.

HashiCorp Vault additionally supports several authentication methods (token, AppRole, JWT, Kubernetes, AWS, GCP, Azure, and others). See the [{{site.base_gateway}} Vault entity](/gateway/entities/vault/) for backend-specific guidance that applies to both deployment modes.

## Choosing a backend for your AI Vault

Pick a backend matching your infrastructure and secret management strategy. Cloud-native deployments can use their platform's secret service (`aws`, `gcp`, `azure`), enterprises can use dedicated secret management systems (`conjur`, `hcv`), and smaller deployments can use `env` (environment variables) or `konnect` (built-in Config Store).

<!-- vale off -->
{% table %}
columns:
  - title: Backend
    key: backend
  - title: When to use
    key: when
rows:
  - backend: "`konnect`"
    when: All-in-one {{site.konnect_short_name}} Config Store. Simplest for users without existing secret infrastructure.
  - backend: "`env`"
    when: Development and simple deployments. Secrets loaded from process environment at data plane startup (no network calls).
  - backend: "`aws`"
    when: AWS-deployed data planes. Integrate with AWS Secrets Manager or Parameter Store.
  - backend: "`gcp`"
    when: GCP-deployed data planes. Integrate with Google Secret Manager.
  - backend: "`azure`"
    when: Azure-deployed data planes. Integrate with Azure Key Vault.
  - backend: "`conjur`"
    when: Enterprises using CyberArk Conjur for centralized secrets management.
  - backend: "`hcv`"
    when: Enterprises with HashiCorp Vault. Supports many auth methods (token, AppRole, JWT, Kubernetes, AWS IAM, GCP, Azure).
{% endtable %}
<!-- vale on -->

## Caching

Cloud-backed AI Vault types (`aws`, `gcp`, `azure`, `conjur`, `hcv`) cache resolved secrets so that {{site.ai_gateway}} doesn't hit the backend on every reference. Cache duration, negative-lookup caching, and how long expired secrets stay in use during backend outages are all tunable. The `env` type doesn't cache because environment-variable lookups don't hit the network.

## Set up an AI Vault

The following example registers an environment-variable AI Vault that resolves references against process environment variables prefixed with `KONG_`.

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
