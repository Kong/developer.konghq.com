---
title: 'Access Control Enforcement'
name: 'Access Control Enforcement'

content_type: plugin

publisher: kong-inc
description: 'The ACE plugin manages developer access control to APIs published with Dev Portal.'

products:
  - gateway

works_on:
  - konnect

min_version:
   gateway: '3.13'

topologies:
  on_prem:
    - hybrid
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - traffic-control

icon: ace.png 

categories:
  - traffic-control

related_resources:
  - text: Dev Portal API packaging
    url: /dev-portal/api-catalog-and-packaging/
---

{:.warning}
> **Important:** The Access Control Enforcement plugin can only be used with APIs that are linked to a control plane, which is a private beta feature. Contact your account manager for access.

{% include /plugins/ace/ace-overview.md %}

## Route matching policy

{% include /plugins/ace/ace-route-matching.md %}
