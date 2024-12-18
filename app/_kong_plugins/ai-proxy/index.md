---
title: 'AI Proxy'
name: 'AI Proxy'

content_type: plugin

publisher: kong-inc
description: The AI Proxy plugin lets you transform and proxy requests to a number of AI providers and models.


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.6'

# topologies:
#    - hybrid
#    - db-less
#    - traditional

icon: ai-proxy.png
---

{% include plugins/ai-proxy/overview.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}
{% include plugins/ai-proxy/formats.md plugin=page.name params=site.data.plugins.ai-proxy.parameters %}

{:.note}
> Check out the [AI Gateway quickstart](/gateway/latest/get-started/ai-gateway/) to get an AI proxy up and running within minutes!

{% include plugins/ai-proxy/links.md plugin=page.name %}

