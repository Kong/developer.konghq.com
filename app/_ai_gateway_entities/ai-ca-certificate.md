---
title: AI CA Certificates
content_type: reference
entities:
  - ai-ca-certificate
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-ca-certificate/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: Store public certificates from trusted Certificate Authorities to verify the validity of AI Certificates.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayCACertificate
works_on:
  - konnect
tools:
  - konnect-api
  - kongctl
related_resources:
  - text: "{{site.ai_gateway}} architecture"
    url: /ai-gateway/architecture/
  - text: AI Certificate
    url: /ai-gateway/ai-certificate/
  - text: AI SNI
    url: /ai-gateway/entities/ai-sni/
  - text: AI Data Plane Certificate
    url: /ai-gateway/entities/ai-data-plane-certificate/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
faqs:
  - q: How is an AI CA Certificate different from a {{site.base_gateway}} CA Certificate?
    a: |
      Both hold a PEM-encoded certificate used to validate TLS certificates, but they're separate entities.
  - q: What's the difference between an AI Certificate and an AI CA Certificate?
    a: |
      An AI CA Certificate represents a trusted certificate
      authority, carries no private key, and is used to verify the certificate a client or an
      upstream server presents. An AI Certificate is an identity the data plane uses itself: it carries a private key and is
      presented to complete a TLS handshake.
  - q: Can MCP Servers and Agents use an AI CA Certificate to verify their upstreams?
    a: |
      Yes. From {{site.ai_gateway}} 2.3 onward, an [AI MCP Server](/ai-gateway/entities/ai-mcp-server/)
      or [AI Agent](/ai-gateway/entities/ai-agent/) can reference one or more AI CA Certificates by
      name in its `config.ca_certificates` field. The data plane builds a trust store from them to
      verify the upstream's TLS certificate, which supports upstreams serving certificates signed by
      a private or internal CA. When `config.ca_certificates` is unset, the data plane's default
      trust store is used.
---

## What is an AI CA Certificate

An AI CA certificate contains the PEM-encoded public certificate of a trusted Certificate Authority. This is used as the root CA to verify the validity of [AI Certificates](/ai-gateway/entities/ai-certificate/) and [AI Data Plane Certificates](/ai-gateway/entities/ai-data-plane-certificate/).

{{site.ai_gateway}} verifies certificates by default and will fail to push an insecure configuration to a Data Plane.

##  Set up an AI CA Certificate

The following example registers a CA certificate and creates an AI CA Certificate entity:

{% entity_example %}
type: ca_certificate
data:
  name: my-root-ca
  cert: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
{% endentity_example %}

## Schema

{% entity_schema %}