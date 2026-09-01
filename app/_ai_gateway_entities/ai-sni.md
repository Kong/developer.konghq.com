---
title: AI SNIs
content_type: reference
entities:
  - ai-sni
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-sni/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: A many-to-one mapping of hostnames to a certificate, used to select the TLS certificate an {{site.ai_gateway}} data plane presents to a client.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewaySNI
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} architecture"
    url: /ai-gateway/architecture/
  - text: AI Data Plane Certificate entity
    url: /ai-gateway/entities/ai-data-plane-certificate/
faqs:
  - q: How is an AI SNI different from a {{site.base_gateway}} SNI?
    a: |
      Both map hostnames to a certificate for the TLS handshake, but they're separate entities, and the {{site.base_gateway}} [SNI](/gateway/entities/sni/) documentation doesn't fully carry over:

      * **Routing**: A {{site.base_gateway}} SNI can act as a routing matcher on a Route with a secure protocol, including TLS Routes handled by the expressions router. An AI SNI selects a TLS certificate only, since {{site.ai_gateway}} has no Route entity. Requests route to the AI Model, AI Agent, or AI MCP Server they target.
      * **Certificate reference**: A {{site.base_gateway}} SNI references a Certificate by `id`. An AI SNI references an AI Certificate by `name`.
      * **Hostname field**: On a {{site.base_gateway}} SNI, the hostname is the SNI's `name`. On an AI SNI, `name` is a separate immutable identifier, the hostname is set in `hostname`, and `display_name` is required.
      * **Metadata**: A {{site.base_gateway}} SNI uses `tags`. An AI SNI uses `labels`, following the {{site.ai_gateway}} entity convention.
      * **Tooling**: {{site.base_gateway}} SNIs are managed through the Admin API, {{site.konnect_short_name}} API, decK, KIC, and Terraform. AI SNIs are managed through the {{site.konnect_short_name}} {{site.ai_gateway}} API.
      * **Scope**: A {{site.base_gateway}} SNI is scoped to a control plane, and to a Workspace on {{site.konnect_short_name}}. An AI SNI is scoped to a single {{site.ai_gateway}} instance, which doesn't participate in Workspaces.

  - q: What happens if I delete the AI Certificate an AI SNI points at?
    a: |
      The AI SNI no longer resolves to a usable AI Certificate, and the data plane falls back to its default AI Certificate for connections matching that hostname. Point the AI SNI at a replacement AI Certificate before deleting the old one.

  - q: How does this relate to the AI Data Plane Certificate entity?
    a: |
      They sit on opposite sides of the data plane. An [AI Data Plane Certificate](/ai-gateway/entities/ai-data-plane-certificate/) authenticates a data plane node to the {{site.ai_gateway}} control plane over mTLS. An AI SNI, paired with an AI Certificate, controls which AI Certificate that node presents to LLM, MCP, and A2A clients connecting to it.
---

## What is an AI SNI?

An AI SNI (Server Name Indication) maps a hostname to an [AI Certificate](/ai-gateway/entities/ai-certificate/) registered on an {{site.ai_gateway}} instance. When a client opens a TLS connection to a data plane node, the node reads the hostname from the TLS `ClientHello` message and presents the AI Certificate that the matching AI SNI points at. This lets a single data plane serve several hostnames, each with its own AI Certificate, on the same listener.

Each AI SNI belongs to exactly one {{site.ai_gateway}} instance, alongside the AI Certificate it references.

The mapping is many-to-one: one AI Certificate can be associated with many hostnames, so you create one AI SNI per hostname (or one wildcard AI SNI per subdomain) and point them all at the same AI Certificate.

## Hostname matching

The [`hostname`](#schema-aigateway-sni-hostname) field accepts an exact hostname or a hostname with a single wildcard segment at one end, for example:

* `llm.example.com` matches that hostname only
* `*.example.com` matches subdomains of `example.com`
* `example.*` matches the same name across top-level domains
* `*.example.*` is rejected

When several AI SNIs could match an incoming hostname, the data plane resolves the AI Certificate in this order:

1. An AI SNI with an exact hostname match
1. An AI SNI with a matching prefix wildcard
1. An AI SNI with a matching suffix wildcard
1. The data plane's default AI Certificate

## AI Certificate association

An AI SNI references its [`certificate`](#schema-aigateway-sni-certificate) by name. The AI Certificate must include a valid private key, since the data plane uses it to complete the TLS handshake.

There are two ways to create an AI SNI:

* **Standalone**: `POST` to `/v1/ai-gateways/{aiGatewayId}/snis` with an AI Certificate name in the request body. Use this when you're attaching hostnames to an AI Certificate that already exists.
* **Nested under an AI Certificate**: `POST` to `/v1/ai-gateways/{aiGatewayId}/certificates/{certificateIdOrName}/snis`. The AI Certificate comes from the path, so the request body has no `certificate` field.

Both create the same entity. Renaming an AI Certificate breaks any AI SNI still pointing at the old name, so update the referencing AI SNIs whenever you rename an AI Certificate.

## Set up an AI SNI

The following example creates an AI SNI that maps every subdomain of `example.com` to an AI Certificate named `my-tls-cert`. Create the AI Certificate on the same {{site.ai_gateway}} first, through `/v1/ai-gateways/{aiGatewayId}/certificates`.

{% entity_example %}
type: sni
data:
  name: llm-example-com
  display_name: LLM API - example.com
  hostname: '*.example.com'
  certificate: my-tls-cert
{% endentity_example %}

## Schema

{% entity_schema %}
