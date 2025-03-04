---
title: 'Upstream OAuth'
name: 'Upstream OAuth'

content_type: plugin

publisher: kong-inc
description: 'Configure {{site.base_gateway}} to obtain an OAuth2 token to consume an upstream API'


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
icon: upstream-oauth.png

categories:
  - authentication

search_aliases:
  - upstream-oauth
  - upstream authentication
  - oauth2
---

## Overview
