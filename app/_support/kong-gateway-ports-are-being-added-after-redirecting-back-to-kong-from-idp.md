---
title: "Kong Gateway: Ports are being added after redirecting back to Kong from IDP"
content_type: support
description: "When a port such as `8443` gets appended to the redirect URL from the IDP, configure `port_maps` (behind an L4 load balancer) or `trusted_ips` (behind an L7 load balancer) so Kong Gateway doesn't display the port."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Port maps
    url: /gateway/configuration/#port-maps
  - text: Trusted IPs
    url: /gateway/configuration/#trusted-ips
tldr:
  q: How can we stop a port number like 8443 from being appended to the redirect URL after IDP authentication with the OpenID Connect plugin?
  a: |
    If Kong sits behind an L4 load balancer, configure `port_maps` (e.g. `port_maps=80:8000, 443:8443`) so Kong maps the default port to the actual listening port instead of appending it to the redirect URL. If Kong sits behind an L7 load balancer, configure `trusted_ips` instead so Kong trusts the `X-Forwarded-*` headers from the load balancer rather than appending its own port.
---

## Problem

We are utilizing a service protected by the Open ID Connect (OIDC) plugin. After redirecting to the Identity Provider (IDP) and successfully authenticating, it is being redirected back with the port `8443` appended to the URL.

## Solution

In order to resolve this issue we would need to setup `port_maps`. This would allow us to map a default port of 443 to 8443. Once a default port is utilized, the ports no longer will display.

If the port appended to the redirect url is from an L4 load balancer in front of Kong then using `port_maps` will also resolve this issue.

Sample:

```
port_maps=80:8000, 443:8443
```

If the port appended to the redirect url is from an L7 load balancer in front of Kong then we need to setup `trusted_ips`. This allows Kong to trust the `X-Forwarded-*` headers sent by the load balancer.

Sample:

```
trusted_ips=192.168.1.1/32
```
