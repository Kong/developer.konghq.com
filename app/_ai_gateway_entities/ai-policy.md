---
title: AI Policies
content_type: reference
entities:
  - ai-policy
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-policy/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: "AI Policies for {{site.ai_gateway}}."
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayPolicy
works_on:
  - konnect
tools:
  - konnect-api
  - kongctl
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Custom Policy entity
    url: /ai-gateway/entities/ai-custom-policy/

faqs:
  - q: Are AI Policies shared across multiple entities?
    a: |
      Each AI Policy is an independent entity. You can apply the same AI Policy
      to multiple other entities by referencing the AI Policy in each entity's configuration.

  - q: How is an AI Policy different from a plugin?
    a: |
      An AI Policy is a policy configuration created through the {{site.ai_gateway}} entity surface
      instead of the classic `/plugins` endpoint. The runtime effect is the same: a policy attached
      at the appropriate scope.

  - q: Can an AI Policy be scoped to an AI Consumer or AI Consumer Group?
    a: |
      Yes. Add the AI Policy's `name` or `id` to the AI Consumer's or AI Consumer Group's `policies` array.
      The AI Policy runs when the AI Consumer is identified during a request, or when a member of the
      AI Consumer Group is identified.

  - q: Can I attach more than one AI Policy of the same type to the same entity?
    a: |
      No. Attach at most one AI Policy of a given type to an entity.
      If you attach two, {{site.ai_gateway}} accepts the configuration, but only one of the two takes effect and you can't control which.
      To use the same AI Policy type with different configurations, attach each AI Policy at a different scope, for example one globally and one on a specific AI Model.

  - q: What happens to an AI Policy when its parent entity is deleted?
    a: |
      Standalone AI Policies referenced from parent entities through a `policies` array are independent
      and aren't deleted when a referencing parent is deleted. The reference is simply removed.
---

## What is an AI Policy?

Create an AI Policy when you want to add governance, security, transformation, or observability to {{site.ai_gateway}} traffic. For example:
- Redact sensitive data with [AI PII Sanitizer](/ai-gateway/policies/ai-sanitizer/)
- Manage request volume with [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/)
- Validate prompts with [AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/) or [other guardrail AI Policies](/ai-gateway/policies/?terms=guardrail)
- Track requests and responses for observability with [logging AI Policies](/ai-gateway/policies/?category=logging)

If none of the available AI Policy types fit your use case, you can register a custom AI Policy type.
See [AI Custom Policies](/ai-gateway/entities/ai-custom-policy/).

To control access and verify identity, assign an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) instead of an AI Policy.

{:.info}
> For the complete set of available policy types and configurations, see the [AI Policies hub](/ai-gateway/policies/).

## Manage AI Policies

AI Policies are managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/policies`
* [kongctl](/kongctl/)

For configuration examples and step-by-step setup instructions, see [Set up a global AI Policy](#set-up-a-global-ai-policy).

## AI Policy scopes

An AI Policy applies wherever you attach it.
An AI Policy with `global: true` applies to all {{site.ai_gateway}} traffic on the data plane.
An AI Policy without it applies only to the entities that reference it.

The available scopes are:

* **Global**: Set `global: true` to apply the AI Policy to all {{site.ai_gateway}} traffic on the data plane. Non-AI traffic on the same data plane isn't affected.

* **Entity-scoped**: Reference the AI Policy from the `policies` array on an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), [AI Consumer](/ai-gateway/entities/ai-consumer/), or [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) entity. The AI Policy applies at that entity's scope.

To apply an identical configuration in multiple places, create an entity-scoped AI Policy and reference it in each entity's configuration.

Not every AI Policy type supports every scope.
For example, an ACL AI Policy can only be global, and AI NVIDIA NeMo Guardrail can only be scoped to an AI Model.
{{site.ai_gateway}} rejects the request with an error when you attach an AI Policy at a scope its type doesn't support.

### Scope precedence

Scope precedence determines which AI Policy runs when AI Policies of the same type apply to a request at more than one scope.
Only the most specific AI Policy runs.
From most to least specific, the order is:

1. AI Consumer
1. AI Consumer Group
1. AI Model, AI Agent, or AI MCP Server
1. Global

For example, if a global AI Rate Limiting Advanced AI Policy and one scoped to an AI Model both apply to a request, only the Model-scoped AI Policy runs.
Requests to other Models still use the global AI Policy.

Attach at most one AI Policy of a given type to the same entity.
For details, see [the FAQ](#faqs).

## AI Policy priority

Every AI Policy type has a fixed priority that determines execution order when more than one AI Policy applies to a request.
You can't configure or override an AI Policy's priority.

When AI Policies of different types apply to the same request, the AI Policy with the higher priority runs first.
When AI Policies of the same type apply at different scopes, see [Scope precedence](#scope-precedence).

[Custom AI Policies](/ai-gateway/entities/ai-custom-policy/) run at the priority set by the plugin's author, so they don't appear in the following table.

The following table lists the priority of every built-in AI Policy type, from highest to lowest.

{% ai_policy_priorities %}

{:.info}
> These values apply to the current {{site.ai_gateway}} release and can change in a future release.

## Conditional AI Policy execution

An AI Policy has a `condition` field that determines whether the AI Policy runs for a given request.
Write the condition as a CEL (Common Expression Language) expression.
When a request comes in, {{site.ai_gateway}} evaluates the condition.
If it matches, the AI Policy runs.
If it doesn't match, the AI Policy is skipped for that request.

For example, to run an AI Policy only when the request includes the header `x-tier: premium`:

```yaml
condition: 'http.headers.x_tier == "premium"'
```

In the expression, write header names with underscores in place of hyphens, so `x-tier` becomes `x_tier`.
{{site.ai_gateway}} validates the expression when you save the AI Policy and rejects an invalid one.

With this condition:
* A request with the header `x-tier: premium` matches, so the AI Policy runs.
* A request with `x-tier: free`, any other value, or no `x-tier` header doesn't match. {{site.ai_gateway}} skips the AI Policy and processes the request as if the AI Policy weren't attached.

For the full expression syntax, see the [CEL reference](/gateway/plugins/expressions/).

## Protocols

An AI Policy takes its protocols from the entity it's attached to.
An AI Policy scoped to an AI Model, AI Agent, or AI MCP Server runs on the protocols of that entity's Route.
A global AI Policy runs only on HTTP and HTTPS traffic.

On a WebSocket route, an AI Policy scoped to an AI Model runs only if its type supports the `ws` and `wss` protocols.
Otherwise, it's skipped for that route.

## Set up a global AI Policy

An AI Policy specifies a `type` (like AI Sanitizer or AI Rate Limiting Advanced) and a `config` block that configures that behavior. {{site.ai_gateway}} applies the AI Policy at the scope you choose: globally across all traffic, or scoped to the entities where it is referenced.

The following example creates a global AI PII Sanitizer AI Policy that runs for every {{site.ai_gateway}} Route. It anonymizes high-risk PII categories (email, phone, SSN, and credit cards) along with custom patterns for sensitive tokens like AWS API keys and GitHub tokens.

{:.info}
> This AI Policy connects to an AI PII Anonymizer service at `host`/`port` (`sanitizer-service.internal:8080` in this example) to perform the actual sanitization. Substitute the address of your own running instance. See [AI PII Anonymizer service](/ai-gateway/policies/ai-sanitizer/#ai-pii-anonymizer-service) for image access and setup instructions.
>
> Without a reachable service at that address, requests through this AI Policy will fail.

{% entity_example %}
type: policy
data:
  display_name: PII Sanitizer - Global
  name: pii-sanitizer-global
  type: ai-sanitizer
  enabled: true
  global: true
  config:
    anonymize:
      - email
      - phone
      - ssn
      - creditcard
      - custom
    custom_patterns:
      - name: aws_api_key
        regex: AKIA[0-9A-Z]{16}
        score: 0.95
      - name: github_token
        regex: ghp_[A-Za-z0-9]{36}
        score: 0.9
    host: sanitizer-service.internal
    port: 8080
    redact_type: placeholder
    stop_on_error: true
    recover_redacted: false
{% endentity_example %}

## Schema

{% entity_schema %}
