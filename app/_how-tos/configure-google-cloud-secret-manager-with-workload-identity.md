---
title: Configure Google Cloud Secret Manager with Workload Identity in {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-google-cloud-secret/
  - text: Secrets management
    url: /secrets-management/
  - text: Configure Google Cloud Secret Manager as a Vault entity in {{site.base_gateway}}
    url: /how-to/configure-google-cloud-secret-as-a-vault-backend/

products:
    - gateway


works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

entities: 
  - vault

tags:
    - security

tldr:
    q: Placeholder
    a: Placeholder

tools:
    - deck

prereqs:
  inline:
    - title: Google Cloud Secret Manager
      position: before
      content: |
        placeholder

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

@todo

pull content from https://docs.konghq.com/gateway/latest/kong-enterprise/secrets-management/backends/gcp-sm/#vault-entity-configuration-options

pay special attention to the notes, there's more here that's probably not documented about Workload Identity specifically that will take more research