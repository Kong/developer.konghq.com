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

search_aliases:
  - ip-restriction

related_resources:
  - text: Restrict access to {{site.base_gateway}} resources by allowing specific IPs
    url: /how-to/restrict-access-to-resources-by-allowing-ips/
---

## Overview

The IP Restriction plugin restricts access to a Gateway Service or a Route by either allowing or denying IP addresses. Single IPs, multiple IPs, or ranges in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation) like 10.10.10.0/24 can be used. The plugin supports IPv4 and IPv6 addresses.

## Usage

An `allow` list provides a positive security model, in which the configured CIDR ranges are allowed access to the resource, and all others are inherently rejected. A `deny` list configuration provides a negative security model, in which certain CIDRS are explicitly denied access to the resource, and all others are inherently allowed.

You can configure the plugin with both allow and deny configurations. This can be useful if you want to allow a CIDR range but deny an IP address on that CIDR range.

## How is the IP address determined?

The IP address is determined by the request header sent to Kong from downstream. In most cases, the header has a name `X-Real-IP` or `X-Forwarded-For`.

By default, Kong uses the header name `X-Real-IP`. If a different header name is required, it needs to be defined using the `real_ip_header` property in `kong.conf`. Depending on the network setup, the `trusted_ips` property may also need to be configured to include the load balancer IP address.