---
title: 'WebSocket Size Limit'
name: 'WebSocket Size Limit'

content_type: plugin

publisher: kong-inc
description: 'Block incoming WebSocket messages greater than a specified size'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: websocket-size-limit.png

categories:
  - traffic-control

search_aliases:
  - websocket-size-limit
---

## Overview
