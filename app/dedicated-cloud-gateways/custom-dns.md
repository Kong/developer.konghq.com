---
title: "Custom DNS"
content_type: reference
layout: reference
description: "{{site.konnect_short_name}} integrates domain name management and configuration with [managed data planes](/dedicated-cloud-gateways/)."

products:
    - gateway


related_resources:
  - text: Konnect Advanced Analytics
    url: /advanced-analytics/
---

## Domain Registrar configuration

{{site.konnect_short_name}} integrates domain name management and configuration with [Dedicated Cloud Gateways](/konnect/gateway-manager/dedicated-cloud-gateways/).

{% table %}
columns:
  - title: Host Name
    key: host
  - title: Record Type
    key: type
  - title: Routing Policy
    key: routing
  - title: Alias
    key: alias
  - title: Evaluate Target Health
    key: health
  - title: Value
    key: value
  - title: TTL
    key: ttl
rows:
  - host: "`_acme-challenge.example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`_acme-challenge.9e454bcfec.acme.gateways.konghq.com`"
    ttl: 300
  - host: "`example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`9e454bcfec.gateways.konghq.com`"
    ttl: 300
{% endtable %}
