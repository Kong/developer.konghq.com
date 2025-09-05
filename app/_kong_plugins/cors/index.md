---
title: 'CORS'
name: 'CORS'

content_type: plugin

publisher: kong-inc

description: 'The CORS plugin lets you add Cross-Origin Resource Sharing (CORS) to a Service or a Route.'


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

related_resources:
  - text: DNS configuration reference
    url: /gateway/network/dns-config-reference/

icon: cors.png

categories:
  - security

min_version:
  gateway: '1.0'
---

The CORS plugin lets you add Cross-Origin Resource Sharing (CORS) to a Service or a Route. This allows you to automate the configuration of CORS rules, ensuring that your upstreams only accept and share resources with approved sources.

{% include sections/cors-and-kong-gateway.md %}

## CORS limitations

When the client is a browser, the preflight OPTIONS requests defined by the [CORS specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) have strict rules about which headers can be set. Certain headers, including Host, are classified as forbidden headers, meaning the browser always controls their value and they cannot be customised in code, e.g. in JavaScript. As a result, a browser cannot send a custom Host header during a preflight request.

This limitation is important when using the CORS plugin with Routes in Kong. If a Route is configured to match only on the hosts field, the preflight request may not carry the expected Host header, and Kong may fail to match the Route. As a result, the CORS plugin cannot reliably process these requests. To ensure correct behaviour, the plugin should be used with routes that match on paths (and optionally methods), which the preflight request will include and Kong can use for matching.
