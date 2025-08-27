---
title: 'AI GCP Model Armor'
name: 'AI GCP Model Armor'

content_type: plugin

publisher: kong-inc
description: 'Audit and validate AI Proxy messages with Google Cloud Model Armor before forwarding them to an upstream LLM.'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless


icon: plugin-slug.png # e.g. acme.svg or acme.png

tags:
   - ai
---