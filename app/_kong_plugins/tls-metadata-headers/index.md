---
title: 'TLS Metadata Headers'
name: 'TLS Metadata Headers'

content_type: plugin

publisher: kong-inc
description: 'Proxies TLS client certificate metadata to upstream services via HTTP headers'
tier: enterprise


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

icon: tls-metadata-headers.png

categories:
  - security

search_aliases:
  - tls-metadata-headers
  - certificates
---

## Overview
