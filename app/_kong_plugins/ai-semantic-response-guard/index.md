---
title: 'AI Semantic Response Guard'
name: 'AI Semantic Response Guard'

content_type: plugin

publisher: kong-inc
description: 'Permit or block prompts based on semantic similarity to known LLM responses, preventing misuse of llm/v1/chat or llm/v1/completions requests'


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