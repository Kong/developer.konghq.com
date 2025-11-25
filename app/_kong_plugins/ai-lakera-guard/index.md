---
title: 'ai lakera plugin'
name: 'schema of ai lakera plugin'

content_type: plugin

publisher: kong-inc
description: 'schema of ai lakera plugin'


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

icon: plugin-slug.png # e.g. acme.svg or acme.png

categories:
   - traffic-control

related_resources:
  - text: How-to guide for the plugin
    url: /how-to/guide/
---