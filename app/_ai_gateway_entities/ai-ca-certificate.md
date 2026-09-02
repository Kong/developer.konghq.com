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

---

## What is an AI CA Certificate

An AI CA certificate contains the PEM-encoded public certificate of a trusted Certificate Authority. This is used as the root CA to verify the validity of [AI Certificates](/ai-gateway/entities/ai-certificate/) and [AI Data Plane Certificates](/ai-gateway/entities/ai-data-plane-certificate/).

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