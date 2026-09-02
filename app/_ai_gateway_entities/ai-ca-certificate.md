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

An AI CA certificate contains the PEM-encoded public certificate of a trusted Certificate Authority. This entity is used as the root CA to verify the validity of [AI Certificates](/ai-gateway/entities/ai-certificate/).

##  Set up an AI CA Certificate

The following example registers a certificate:

```
curl --request POST \
  --url https://us.api.konghq.com/v1/ai-gateways/bf138ba2-c9b1-4229-b268-04d9d8a6410b/ca-certificates \
  --header 'Accept: application/json, application/problem+json' \
  --header 'Authorization: ••••••' \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "my-root-ca",
  "cert": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n"
}'
```

## Schema

{% entity_schema %}