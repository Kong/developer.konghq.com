---
title: How to accurately calculate upstream target weights for traffic distribution
content_type: support
description: "How Kong's upstream load balancer treats each IP address returned by a DNS A record as a separate weighted target, and how to calculate weights so traffic is distributed as intended."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why doesn't Kong's upstream weighting produce the expected traffic split when a target's hostname resolves to multiple IP addresses?
  a: |
    Each IP address returned by a target's DNS A record is added to the balancer as a separate target with the same weight as the original hostname target, so a hostname with multiple A records gets a multiplied effective weight. To achieve an intended ratio (e.g. 50:50), divide the desired weight by the number of resolved IP addresses, then scale all weights to whole numbers, since Kong weights must be integers.
related_resources:
  - text: Kong upstream load-balancing reference documentation
    url: /gateway/traffic-control/load-balancing-reference/
---

## Overview

How to accurately calculate upstream target weights for traffic distribution

## Steps

The behavior of the Kong upstream load-balancer mechanism is described in the documentation. The most misunderstood mechanism is the way to weight targets, which is usually due to a misunderstanding of the load balancing mechanism itself.

Specifically, if you have a hostname that has an A record that returns multiple IP addresses, each IP address gets added to the balancer as a separate upstream target with the same weight as the initial hostname target.

50:50 - Example

Target 1: httpbin.org:80

Weight: 100

Returns: 200 Status

Target 2: kong-loopback.me.test:8000

Weight: 100

Returns: 202 Status - Loopback DNS that points back to Kong and a request termination plugin

Target setup in my test instance:

The implication here that most believe, is that the requests should be distributed equally among the 2 targets due to their weighting.

However if you run a test and review the Vitals information for that service, you'll see the following distribution:

If you review the DNS A records for the 2 targets, the reason becomes clear:

```bash
nslookup -type=A httpbin.org
Server:		172.18.0.100
Address:	172.18.0.100:53

Non-authoritative answer:
Name:	httpbin.org
Address: 34.231.5.222
Name:	httpbin.org
Address: 18.215.122.215
Name:	httpbin.org
Address: 44.195.242.112
Name:	httpbin.org
Address: 54.91.120.77
Name:	httpbin.org
Address: 3.229.191.75
Name:	httpbin.org
Address: 52.55.211.119
Name:	httpbin.org
Address: 52.7.224.181
Name:	httpbin.org
Address: 54.157.76.102
```

```bash
nslookup -type=A kong-loopback.me.test
Server:		172.18.0.100
Address:	172.18.0.100:53

Name:	kong-loopback.me.test
Address: 172.18.0.8
```

httpbin.org is actually 8 different IP addresses and kong-loopback only has 1.

This means the weighting is actually 800 for httpbin.org and 100 for kong-loopback, resulting in an ~11% distribution going to the loopback, despite the apparent identical weight of both hostname targets. 100/900 = ~11.1%

To correctly weight the above example as 50:50, the easiest way would be to set the weights like so:

Target 1: httpbin.org:80

Weight: (100 weight / 8 targets = 12.5)

Target 2: kong-loopback.me.test:8000

Weight: 100

You can not use decimals for weights as they need to be integers so 12.5 needs to be converted to a whole number with respect to the other weights.

To do this, we multiply both weights by 10 to remove the decimal place.

The weights then become:

httpbin.org weight: 125

kong-loopback weight: 1000

The resulting distribution is close to 50:50:
