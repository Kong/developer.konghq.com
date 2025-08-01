---
title: 'IP Restriction'
name: 'IP Restriction'

content_type: plugin

publisher: kong-inc
description: 'Allow or deny IPs that can make requests to your services'


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
icon: ip-restriction.png

categories:
  - security

tags:
  - security

search_aliases:
  - ip-restriction

related_resources:
  - text: Restrict access to {{site.base_gateway}} resources by allowing specific IPs
    url: /how-to/restrict-access-to-resources-by-allowing-ips/

min_version:
  gateway: '1.0'
---

The IP Restriction plugin restricts access to a Gateway Service or a Route by either allowing or denying IP addresses. This can help block malicious activity, such as spam or access to certain websites. Single IPs, multiple IPs, or ranges in [Classless Inter-Domain Routing (CIDR) notation](https://datatracker.ietf.org/doc/html/rfc4632) like 10.10.10.0/24 can be used. The plugin supports IPv4 and IPv6 addresses.

## How does the IP Restriction plugin work?

You can configure the plugin with an `allow` list of IP addresses or ranges to allow and a `deny` list of IP addresses or ranges to reject. When only an `allow` list is configured, all IP addresses that aren't on that list are rejected. Similarly, when only a `deny` list is configured, all IP addresses that aren't on the `deny` list are accepted. 

You can configure the plugin with both an `allow` and `deny` list. This can be useful if you want to allow a CIDR range but deny an IP address on that CIDR range.

## How is the IP address determined?

The IP address is determined by the request header sent to {{site.base_gateway}} from downstream. In most cases, the header has the name `X-Real-IP` or `X-Forwarded-For`.

By default, {{site.base_gateway}} uses the header name `X-Real-IP`. If a different header name is required, it needs to be defined using the [`real_ip_header`](/gateway/configuration/#real-ip-header) property in `kong.conf`. Depending on the network setup, the [`trusted_ips`](/gateway/configuration/#trusted-ips) property may also need to be configured to include the load balancer IP address.