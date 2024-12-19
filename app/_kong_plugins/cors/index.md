---
title: 'CORS'
name: 'CORS'

content_type: plugin

publisher: kong-inc

description: 'The CORS plugin lets you add Cross-Origin Resource Sharing (CORS) to a service or a route.'


products:
    - gateway


works_on:
    - on-prem
    - konnect
topologies:
    - hybrid
    - db-less
    - traditional


related_resources:
  - text: DNS configuration reference
    url: /gateway/networking/dns-config-reference/

icon: cors.png

categories:
  - security

---

## Overview


The CORS plugin lets you add Cross-Origin Resource Sharing (CORS) to a Service or a Route. This allows you to automate the configuration of CORS rules, ensuring that your upstreams only accept and share resources with approved sources.


{% include sections/cors-and-kong-gateway.md %}


## CORS limitations

If the client is a browser, there is a known issue with this plugin caused by a
limitation of the [CORS specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) that prevents specifying a custom
`Host` header in a preflight `OPTIONS` request.

Because of this limitation, this plugin only works for routes that have been
configured with a `paths` setting. The CORS plugin does not work for routes that
are being resolved using a custom DNS (the `hosts` property).

To learn how to configure `paths` for a route, read the [Proxy Reference](/gateway/traffic-control/proxy/).

