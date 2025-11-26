---
title: 'AI Lakera Guard'
name: 'AI Lakera Guard'

content_type: plugin

publisher: kong-inc
description: 'Audit and enforce safety policies on LLM requests and responses using the AI AWS Lakera plugin before they reach upstream LLMs.'

category: AI

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.13'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - ai

search_aliases:
  - ai-lakera-guard

icon: ai-lakera.png

categories:
   - ai

---

Hi Fabian