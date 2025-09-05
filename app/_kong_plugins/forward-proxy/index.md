---
title: 'Forward Proxy Advanced'
name: 'Forward Proxy Advanced'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Allows {{site.base_gateway}} to connect to intermediary transparent HTTP proxies'


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
icon: forward-proxy.png

categories:
  - traffic-control

tags:
  - traffic-control
  - routing

search_aliases:
  - forward-proxy

min_version:
  gateway: '1.0'
---

The Forward Proxy Advanced plugin allows {{site.base_gateway}} to connect to intermediary transparent HTTP proxies, instead of directly to the `upstream_url`, when forwarding requests upstream. 

This is useful in environments where the following is true:
1. {{site.base_gateway}} sits inside an organization's internal network.
2. The upstream service is available via the public internet.
3. The organization proxies all outbound traffic through a forward proxy server.

## How it works

The Forward Proxy Advanced plugin attempts to transparently replace upstream connections made by {{site.base_gateway}}, sending the request instead to an intermediary forward proxy.

Only transparent HTTP proxies are supported. TLS connections (via `CONNECT`) are not supported.

The Forward Proxy Advanced plugin can't be used with an [Upstream](/gateway/entities/upstream/).
As a workaround for load balancing, configure the [`host` field in a Gateway Service](/gateway/entities/service/#schema) to a domain name so that you can use a 
[DNS-based load balancing](/gateway/traffic-control/load-balancing-reference/#dns-based-load-balancing) technique.

