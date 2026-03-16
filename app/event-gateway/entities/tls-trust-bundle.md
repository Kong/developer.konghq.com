---
title: "TLS trust bundles"
content_type: reference
layout: gateway_entity

description: |
    TLS trust bundles store CA certificates used to verify client certificates during mutual TLS (mTLS) handshakes.

related_resources:
  - text: "TLS Server policy"
    url: /event-gateway/policies/tls-server/
  - text: "Listeners"
    url: /event-gateway/entities/listener/
  - text: "How-to: Configure mTLS client authentication"
    url: /event-gateway/configure-mtls-client-authentication/

tools:
    - konnect-api

works_on:
  - konnect

api_specs:
    - konnect/event-gateway

products:
    - event-gateway

schema:
    api: konnect/event-gateway
    path: /schemas/EventGatewayTLSTrustBundle

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## What is a TLS trust bundle?

A TLS trust bundle is a collection of trusted CA certificates that {{site.event_gateway}} uses to verify client certificates during a mutual TLS (mTLS) handshake. When a [TLS server policy](/event-gateway/policies/tls-server/) is configured with `client_authentication`, it references one or more trust bundles to determine whether a client's certificate is trusted.

Trust bundles can contain:
* **Literal PEM certificates**: The CA certificate is stored directly. Literal values are encrypted at rest and omitted from API responses.
* **Vault or environment references**: A template expression like `${env['MY_CA_CERT']}` that is resolved at runtime by the data plane.

Trust bundles are evaluated in order. Verification stops at the first trust bundle that successfully validates the client certificate chain. If no trust bundle validates the certificate, the connection is closed when the client authentication mode is `required`.

## Set up a TLS trust bundle

{% entity_example %}
type: tls_trust_bundle
data:
  name: my-ca-bundle
  description: Internal CA for client verification
  config:
    trusted_ca: $CA_CERT
{% endentity_example %}

## Schema

{% entity_schema %}
