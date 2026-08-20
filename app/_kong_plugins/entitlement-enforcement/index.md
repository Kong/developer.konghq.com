---
title: 'Entitlement Enforcement'
name: 'Entitlement Enforcement'

content_type: plugin

publisher: kong-inc
description: 'Allow or deny API requests based on customer entitlements. Checks feature access, usage limits, and credit balance against Metering & Billing before routing traffic.'


products:
    - gateway
    - metering-and-billing

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.16'

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
  - monetization

search_aliases:
  - entitlement-enforcement
  - governance
  - metering and billing
  

icon: entitlement-enforcement.png

categories:
   - monetization

# related_resources:
#   - text: How-to guide for the plugin
#     url: /how-to/guide/
---

TO DO