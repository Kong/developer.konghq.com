---
title: 'Header Cert Authentication'
name: 'Header Cert Authentication'

content_type: plugin

publisher: kong-inc
description: 'Authenticate clients with mTLS certificates passed in headers by a WAF or load balancer'


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

icon: header-cert-auth.png

categories:
  - authentication

search_aliases:
  - header cert auth
  - header-cert-auth
  - authentication
---

## Overview
