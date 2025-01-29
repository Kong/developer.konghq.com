---
title: 'Standard Webhooks'
name: 'Standard Webhooks'

content_type: plugin

publisher: kong-inc
description: 'Validate that incoming webhooks adhere to the Standard Webhooks specification, which Kong contributes to'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: standard-webhooks.png

categories:
  - traffic-control
---

## Overview
