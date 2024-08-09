---
title: Rate Limiting Advanced plugin reference

name: Rate Limiting Advanced
publisher: kong-inc
tier: enterprise
konnect_compatible: true
content_type: plugin
description: This page provides a reference for the Rate Limiting Advanced plugin configuration.
tags:
  - rate-limiting
  - rate-limiting-advanced
  - traffic-control
tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform
related_resources:
  - text: How to create rate limiting tiers with Rate Limiting Advanced
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/how-to/
---

## DB-less and hybrid mode limitations

The `cluster` strategy is not supported in DB-less and hybrid modes. For Kong Gateway in DB-less or hybrid mode, the `redis` strategy is the only available option for configuring the plugin with a central data store.

We recommend setting `namespace` to a static value in DB-less mode. The namespace will be regenerated on every configuration change if not explicitly set, resetting counters to zero.

## Configuration parameters

[ schema ]

[ to the right of schema: full config in codeblock; selectable examples ]

---

{% contentfor config_examples %}
{% entity_example %}
type: plugin
data:
  name: rate-limiting-advanced
  config:
    limit: 
    - 200
    window_size: 
    - 1800
    window_type: fixed
targets:
  - consumer
  - service
  - route
  - global
  - consumer_group
formats:
  - admin-api
  - konnect-api
  - kic
  - deck
  - ui
  - terraform
description: "Users are allowed 200 requests per 30 minutes, resetting exactly on the 30 minute mark with no carryover of unused limits."
{% endentity_example %}

{% entity_example %}
type: plugin
data:
  name: rate-limiting-advanced
  config:
    limit: 
    - 300
    window_size: 
    - 3600
    window_type: fixed
targets:
  - consumer
  - service
  - route
  - global
  - consumer_group
formats:
  - admin-api
  - konnect-api
  - kic
  - deck
  - ui
  - terraform
description: "A fixed limit of 500 requests per hour resetting sharply on the hour, ensuring no user can exceed this limit."
{% endentity_example %}

{% entity_example %}
type: plugin
data:
  name: rate-limiting-advanced
  config:
    limit: 
    - 100
    window_size: 
    - 3600
    window_type: sliding
targets:
  - consumer
  - service
  - route
  - global
  - consumer_group
formats:
  - admin-api
  - konnect-api
  - kic
  - deck
  - ui
  - terraform
description: "Each user can make up to 100 requests every rolling hour, with the plugin continuously adjusting the count over the course of the hour. There is no hard limit or known reset."
{% endentity_example %}

{% entity_example %}
type: plugin
data:
  name: rate-limiting-advanced
  config:
    limit: 
    - 300
    window_size: 
    - 1800
    window_type: sliding
targets:
  - consumer
  - service
  - route
  - global
  - consumer_group
formats:
  - admin-api
  - konnect-api
  - kic
  - deck
  - ui
  - terraform
description: "Each user can make up to 300 requests in any rolling 30 minute period, with the plugin continuously adjusting the count as new requests are made."
{% endentity_example %}

{% endcontentfor %}