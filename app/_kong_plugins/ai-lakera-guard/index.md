---
title: 'AI Lakera Guard'
name: 'AI Lakera Guard'

content_type: plugin

publisher: kong-inc
description: 'Audit and enforce safety policies on LLM requests and responses using the AI AWS Lakera plugin before they reach upstream LLMs.'

category: AI

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.4'

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
  - traffic-control

search_aliases:
  - plugin-name-in-code eg rate-limiting-advanced
  - common aliases, eg OIDC or RLA
  - related terms, eg LLM for AI plugins

premium_partner: true # can be a kong plugin or a third-party plugin

icon: ai-lakera.png

categories:
   - traffic-control

related_resources:
  - text: How-to guide for the plugin
    url: /how-to/guide/
---