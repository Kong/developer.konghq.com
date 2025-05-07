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

---

The CORS plugin lets you add Cross-Origin Resource Sharing (CORS) to a Service or a Route. This allows you to automate the configuration of CORS rules, ensuring that your upstreams only accept and share resources with approved sources.

{% include sections/cors-and-kong-gateway.md %}

## CORS limitations

If the client is a browser, there is a known issue with this plugin caused by a
limitation of the [CORS specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) that prevents specifying a custom
`Host` header in a preflight `OPTIONS` request.

Because of this limitation, this plugin only works for Routes that have been
configured with a `paths` setting. The CORS plugin does not work for Routes that
are being resolved using a custom DNS (the `hosts` property).