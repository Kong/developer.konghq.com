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
  - text: AI Provider
    url: /ai-gateway/entities/ai-provider/
  - text: AI Model
    url: /ai-gateway/entities/ai-model/
  - text: AI MCP Server
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer Credential
    url: /ai-gateway/entities/ai-consumer-credential/
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

You need to store secrets like API keys and authentication tokens somewhere secure instead of embedding them directly in your configurations. An AI Vault entity lets you register an external secret backend (AWS Secrets Manager, HashiCorp Vault, environment variables, or others) so that [AI Providers](/ai-gateway/entities/ai-provider/), [AI Models](/ai-gateway/entities/ai-model/), and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) can reference secrets instead of storing them as literal values.

An AI Vault entity stores the connection configuration and credentials needed to reach your secret backend. When other entities reference a secret, {{site.ai_gateway}} looks up the vault at request time, retrieves the actual secret value, and uses it for authentication or configuration.

## Manage AI Vaults

AI Vaults can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/vaults`

For configuration examples and step-by-step setup instructions, see [Set up an AI Vault](#set-up-an-ai-vault) below.

## Backends

Each AI Vault selects one of the supported secret backends:

* {{site.konnect_short_name}} Config Store
* Environment variables
* [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
* [Google Secret Manager](https://cloud.google.com/secret-manager)
* [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault)
* [CyberArk Conjur](https://www.conjur.org/)
* [HashiCorp Vault](https://www.vaultproject.io/)

The connection details vary per backend; the {{site.konnect_short_name}} UI surfaces the relevant fields based on the backend you choose.

## Which fields support AI Vault references?

AI Vault references can be used in sensitive fields across your AI Gateway entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Sensitive fields
    key: fields
rows:
  - entity: AI Provider
    fields: Authentication credentials (API keys, bearer tokens) in auth headers for upstream LLM providers
  - entity: AI Model
    fields: Backend-specific authentication required by target model configurations
  - entity: AI MCP Server
    fields: Encryption keys used by MCP Servers for client session management
  - entity: AI Consumer
    fields: API keys and tokens issued to downstream consumers
{% endtable %}

{:.success}
> Any field marked as supporting vault references can accept a secret reference instead of a literal value.

## How do I reference secrets?

To reference a secret stored in a vault, use the syntax:

```
{vault://vault-name/secret-key}
```

Where:
- `vault-name` is the `name` field of the vault you created
- `secret-key` is the identifier of the secret within that vault (exact format depends on the backend)

For example, if you created a vault named `prod-aws-vault` and stored an OpenAI API key under the key `openai-api-key`, reference it as:

```
{vault://prod-aws-vault/openai-api-key}
```

Here's how you'd use that reference in an AI Provider entity:

{% entity_example %}
type: provider
data:
  display_name: OpenAI Production
  name: openai-prod
  type: openai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: "{vault://prod-aws-vault/openai-api-key}"
{% endentity_example %}

{:.warning}
> The entire field value must be the vault reference string. You cannot use partial references like `Bearer {vault://...}`. The field itself must be exactly `{vault://vault-name/secret-key}`.

At request time, {{site.ai_gateway}} resolves the reference by looking up the vault name, retrieving the secret value, and using it for authentication or configuration.

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
    when: Getting started, no external dependencies. Built-in {{site.konnect_short_name}} Config Store for teams without existing secret infrastructure.
  - backend: "`env`"
    when: Development, edge deployments, or environments where you control data plane startup. Secrets loaded at startup, no network calls.
  - backend: "`aws`"
    when: AWS-deployed data planes. Integrate with AWS Secrets Manager or Parameter Store.
  - backend: "`gcp`"
    when: GCP-deployed data planes. Integrate with Google Secret Manager.
  - backend: "`azure`"
    when: Azure-deployed data planes. Integrate with Azure Key Vault.
  - backend: "`conjur`"
    when: Enterprises standardized on CyberArk Conjur for centralized secrets management.
  - backend: "`hcv`"
    when: Dedicated secret management with fine-grained access control. Supports token, AppRole, JWT, Kubernetes, AWS IAM, GCP, and Azure authentication.
{% endtable %}
<!-- vale on -->

## Caching and availability

Cloud-backed vault types (`aws`, `gcp`, `azure`, `conjur`, `hcv`) cache resolved secrets so {{site.ai_gateway}} doesn't hit the backend on every request. This reduces latency and vault load. The `env` backend doesn't cache because environment-variable lookups are local.

If your vault becomes unreachable, {{site.ai_gateway}} can continue using recently-cached secrets for a grace period, keeping your system operational during brief vault outages. This allows you to maintain service continuity even when secret infrastructure is temporarily unavailable.

Cache duration and grace periods are tunable per vault, allowing you to balance between fresh secrets (shorter cache times) and reduced vault requests (longer cache times). The default settings work for most deployments; adjust only if your secret rotation strategy or vault reliability requires custom behavior.

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
