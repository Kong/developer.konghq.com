---
title: 'SAML'
name: 'SAML'

content_type: plugin

publisher: kong-inc
description: 'Provides SAML v2.0 authentication and authorization between a service provider (Kong) and an identity provider (IdP)'


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
icon: saml.png

categories:
  - authentication

search_aliases:
  - azure
  - security assertion markup language
---

## Overview
