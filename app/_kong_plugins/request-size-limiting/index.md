---
title: 'Request Size Limiting'
name: 'Request Size Limiting'

content_type: plugin

publisher: kong-inc
description: 'Block requests with bodies greater than a specified size'


products:
    - gateway

works_on:
    - on-prem
    - konnect


topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: request-size-limiting.png

categories:
  - traffic-control

search_aliases:
  - request-size-limiting

tags:
  - traffic-control

min_version:
  gateway: '1.0'
---

Block incoming requests where the body is greater than a specific size.
You can limit the payload size in bytes, kilobytes, or megabytes (default).

{:.warning}
> For security reasons, we suggest enabling this plugin for any [Gateway Service](/gateway/entities/service/) you add
to {{site.base_gateway}} to prevent a DOS (Denial of Service) attack.

