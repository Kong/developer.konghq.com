---
title: 'Redirect'
name: 'Redirect'

content_type: plugin

publisher: kong-inc
description: 'Redirect incoming requests to a new URL'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.9'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: redirect.png

categories:
  - traffic-control
---

The Redirect plugin allows you to stop request execution and return a `Location` header to the caller to redirect them to a new URL.

You can keep the incoming request URL while redirecting to a new host or port by setting `keep_incoming_path` to `true`.
