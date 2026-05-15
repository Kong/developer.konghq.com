---
title: AI Data Plane Certificates
content_type: reference
entities:
  - ai-data-plane-certificate
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0.0'
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: Client certificates that authorize data planes to connect to an {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayDataPlaneClientCertificate
works_on:
  - konnect
tools:
  - konnect-api
  - terraform
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Provider entity
    url: /ai-gateway/entities/provider/
  - text: Vault entity
    url: /ai-gateway/entities/vault/
faqs:
  - q: Why is there no update operation?
    a: |
      The certificate body is immutable once registered. To rotate, register a new Data Plane
      Certificate alongside the existing one, roll the data planes onto the new certificate, then
      delete the old entry. This pattern avoids a window where no certificate is installed.

  - q: What happens to connected data planes when a certificate is deleted?
    a: |
      Any data plane currently connecting with the deleted certificate loses its trust anchor and
      can no longer establish a connection to the {{site.ai_gateway}}. Roll data planes onto a
      replacement certificate before deleting the old one.

  - q: Is the private key stored alongside the certificate?
    a: |
      No. Only the public certificate is registered with the {{site.ai_gateway}}. The corresponding
      private key stays on the data plane and is never sent to {{site.konnect_short_name}}.

  - q: Can the same certificate be used by multiple data planes?
    a: |
      Yes. Any data plane provisioned with the registered certificate and its private key can
      establish a connection. Use multiple certificates when you need to revoke trust for a subset
      of data planes independently.

  - q: How does this relate to the {{site.base_gateway}} data plane client certificate?
    a: |
      It plays the same role, establishing mutual TLS between the control plane and a data plane,
      but it is scoped to a single {{site.ai_gateway}} instance and managed through the
      {{site.ai_gateway}} entity surface, not the {{site.konnect_short_name}} Gateway control plane API.
---

## What is a Data Plane Certificate?

A Data Plane Certificate is an {{site.ai_gateway}} entity that registers a public X.509 certificate as a trusted client identity for an {{site.ai_gateway}}. Data planes presenting the matching private key during the mTLS handshake are allowed to connect; data planes without a matching registered certificate are rejected.

Each Data Plane Certificate belongs to exactly one {{site.ai_gateway}}. An {{site.ai_gateway}} can have multiple registered certificates so that you can issue one per data plane fleet, rotate keys without downtime, or revoke trust for a subset of data planes independently.

Data Plane Certificates are managed through the {{site.konnect_short_name}} {{site.ai_gateway}} API, the {{site.konnect_short_name}} UI, or Terraform:

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
    endpoint: /v1/ai-gateways/{aiGatewayId}/data-plane-certificates
{% endtable %}

There is no on-prem equivalent for this entity. Self-managed {{site.base_gateway}} deployments use the existing [`/certificates`](/gateway/entities/certificate/) entity and [hybrid mode node configuration](/gateway/hybrid-mode/) instead.

## Trust model

The {{site.ai_gateway}} acts as the control plane in a CP/DP topology. Each data plane presents a client certificate during the TLS handshake, and the {{site.ai_gateway}} accepts the connection only if the presented certificate matches one that has been registered as a Data Plane Certificate on that {{site.ai_gateway}}.

Only the public certificate is registered with the {{site.ai_gateway}}. The private key is generated and held on the data plane side; it never leaves the data plane host.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant DP as Data Plane
    participant CP as {{site.ai_gateway}} (Control Plane)

    Note over DP: Holds private key locally<br>(never sent over the network)
    DP->>CP: TLS handshake with client certificate
    Note over CP: Compare presented certificate against<br>registered Data Plane Certificates
    alt Certificate matches a registered entry
        CP-->>DP: TLS handshake completes
        DP->>CP: Receive configuration and stream telemetry
    else No matching registered certificate
        CP-->>DP: Connection rejected
    end
{% endmermaid %}
<!-- vale on -->

## Lifecycle

Data Plane Certificates support create, list, get, and delete operations. There is no update endpoint, the certificate body is immutable.

To rotate a certificate without downtime:

1. Register the new certificate as an additional Data Plane Certificate on the {{site.ai_gateway}}.
1. Reconfigure the data planes to present the new certificate and key.
1. Verify that data planes have reconnected with the new identity.
1. Delete the old Data Plane Certificate.

Deleting a Data Plane Certificate immediately invalidates the trust for any data plane still using it. Existing connections are dropped and reconnect attempts using the deleted certificate are rejected.

## Schema

{% entity_schema %}
