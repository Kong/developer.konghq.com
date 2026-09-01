---
title: AI Certificates
content_type: reference
entities:
  - ai-certificate
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-certificate/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: A PEM-encoded certificate and its matching private key, used to terminate or originate TLS connections on an {{site.ai_gateway}} data plane.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayCertificate
works_on:
  - konnect
tools:
  - konnect-api
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} architecture"
    url: /ai-gateway/architecture/
  - text: AI SNI entity
    url: /ai-gateway/entities/ai-sni/
  - text: AI Vault entity
    url: /ai-gateway/entities/ai-vault/
  - text: AI Data Plane Certificate entity
    url: /ai-gateway/entities/ai-data-plane-certificate/
faqs:
  - q: How is an AI Certificate different from a {{site.base_gateway}} Certificate?
    a: |
      Both hold a PEM-encoded certificate and private key for TLS, but they're separate entities, and the {{site.base_gateway}} [Certificate](/gateway/entities/certificate/) documentation doesn't fully carry over:

      * **Hostname association**: A {{site.base_gateway}} Certificate accepts an inline `snis` array at creation time. An AI Certificate has no such field. Create [AI SNIs](/ai-gateway/entities/ai-sni/) separately and point them at the AI Certificate by name.
      * **Identifier**: A {{site.base_gateway}} Certificate is referenced by `id`. An AI Certificate has an immutable `name` that acts as its stable reference.
      * **Metadata**: A {{site.base_gateway}} Certificate uses `tags`. An AI Certificate uses `labels`, following the {{site.ai_gateway}} entity convention.
      * **Tooling**: {{site.base_gateway}} Certificates are managed through the Admin API, {{site.konnect_short_name}} API, decK, KIC, and Terraform. AI Certificates are managed through the {{site.konnect_short_name}} {{site.ai_gateway}} API.
      * **Scope**: A {{site.base_gateway}} Certificate is scoped to a control plane, and to a Workspace on {{site.konnect_short_name}}. An AI Certificate is scoped to a single {{site.ai_gateway}} instance, which doesn't participate in Workspaces.

  - q: What's the difference between an AI Certificate and an AI CA Certificate?
    a: |
      An AI Certificate is an identity the data plane uses itself: it carries a private key and is
      presented to complete a TLS handshake. An AI CA Certificate represents a trusted certificate
      authority, carries no private key, and is used to verify the certificate a client or an
      upstream server presents. AI CA Certificates are managed through their own endpoint,
      `/v1/ai-gateways/{aiGatewayId}/ca-certificates`.

  - q: How does this relate to the AI Data Plane Certificate entity?
    a: |
      An [AI Data Plane Certificate](/ai-gateway/entities/ai-data-plane-certificate/) authenticates a
      data plane node to the {{site.ai_gateway}} control plane over mTLS, so the node can pull
      configuration. An AI Certificate is used on the traffic path instead, for TLS with the LLM, MCP,
      and A2A clients calling the data plane and with the upstreams it connects to.

  - q: Can I retrieve a private key back from the API?
    a: |
      No. The `key` and `key_alt` fields are write-only. They're accepted on create and update, but
      never returned by a read. Keep your own copy of any key you register, or store it in an
      [AI Vault](/ai-gateway/entities/ai-vault/) and register a reference to it instead of the literal value.
---

## What is an AI Certificate?

An AI Certificate holds a PEM-encoded public certificate chain and its matching private key. An {{site.ai_gateway}} data plane uses it to terminate TLS connections from clients, and to originate TLS connections to upstreams.

Each AI Certificate belongs to exactly one {{site.ai_gateway}} instance. An {{site.ai_gateway}} can hold many AI Certificates, so you can serve several hostnames from the same data plane, each with its own certificate.

## Associate hostnames with an AI Certificate

To decide which AI Certificate the data plane presents for a given connection, create one or more [AI SNIs](/ai-gateway/entities/ai-sni/) that name this AI Certificate. The mapping is many-to-one: a single AI Certificate can back many hostnames.

You can create the AI SNIs:

* From the AI SNI endpoint, `/v1/ai-gateways/{aiGatewayId}/snis`, naming the AI Certificate in the request body
* From the AI Certificate's nested endpoint, `/v1/ai-gateways/{aiGatewayId}/certificates/{certificateIdOrName}/snis`

## Alternative certificates

Set [`cert_alt`](#schema-aigateway-certificate-cert-alt) and [`key_alt`](#schema-aigateway-certificate-key-alt) to serve a second certificate alongside the first. The alternative certificate must use a different key algorithm than `cert`, which lets one AI Certificate carry, for example, both an RSA and an ECDSA chain. The data plane then picks whichever one the connecting client supports.

Both fields go together: `key_alt` requires `cert_alt` to be set.

## Store keys in an AI Vault

The [`cert`](#schema-aigateway-certificate-cert), [`key`](#schema-aigateway-certificate-key), `cert_alt`, and `key_alt` fields are referenceable, so you can keep the material in an [AI Vault](/ai-gateway/entities/ai-vault/) instead of sending it to {{site.konnect_short_name}} in the request body. Set the field to a vault reference string:

```
{vault://vault-name/secret-key}
```

The entire field value must be the reference. Partial references aren't resolved.

## Lifecycle

AI Certificates support create, list, get, update, and delete operations.

To rotate a certificate in place, update the existing AI Certificate with the new `cert` and `key`. Every AI SNI pointing at it starts using the new material without any change to the AI SNIs themselves.

Deleting an AI Certificate leaves any AI SNI that names it without a usable certificate, and the data plane falls back to its default certificate for those hostnames.

## Set up an AI Certificate

The following example registers a certificate and its private key. Reference it afterwards from an [AI SNI](/ai-gateway/entities/ai-sni/) to bind it to a hostname.

{% entity_example %}
type: certificate
data:
  name: my-tls-cert
  cert: |
      -----BEGIN CERTIFICATE-----
      -----END CERTIFICATE-----
  key: |
      -----BEGIN PRIVATE KEY-----
      -----END PRIVATE KEY-----
{% endentity_example %}

## Schema

{% entity_schema %}
