---
title: "Kong Gateway: Errors seen when using decK: \"HTTP status 403 (message: \"<failed to parse response body: invalid character '<' looking for beginning of value>\")\""
content_type: support
description: This situation is rare but is known to be caused by network security rules, specifically those in a WAF (Web Application Firewall).
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does `deck sync` fail with \"HTTP status 403 ... failed to parse response body: invalid character '<' looking for beginning of value\"?"
  a: |
    This is rare and is usually caused by a misconfigured WAF (Web Application Firewall) or other network security appliance rejecting or manipulating requests from decK to Kong Gateway — for example, dropping HTTP PUT requests. decK then fails to parse the HTML error page the WAF returns as JSON. Work with your network/security team to adjust the WAF rules so traffic from the decK workstation reaches Kong Gateway unmodified.
related_resources: []
---

## Problem

We are trying to use decK for our configurations in Kong Gateway; however, we are receiving an error response like the ones below, indicating a failed `deck sync` command:

```
Error: 3 errors occurred:
while processing event: {action type} route {name of entity} failed: HTTP status 403 (message: "<failed to parse response body: invalid character '<' looking for beginning of value>")
while processing event: {action type} route {name of entity} failed: HTTP status 403 (message: "<failed to parse response body: invalid character '<' looking for beginning of value>")
while processing event: {action type} route {name of entity} failed: HTTP status 403 (message: "<failed to parse response body: invalid character '<' looking for beginning of value>")
```

## Cause

This situation is rare but is known to be caused by network security rules, specifically those in a WAF (Web Application Firewall). An improperly configured WAF can reject requests from the Kong decK tool to the Kong Gateway. There may exist some "deny" rules in the WAF which need to be adjusted by the network/security team. For example, the WAF may be set to manipulate or drop HTTP PUT requests.

## Solution

The solution in this situation is to work with the network team to ensure that traffic from the workstation running `deck sync` commands is unencumbered when talking to the Kong Gateway destination. Once the WAF is properly configured to allow the traffic as expected, this issue should then be resolved. If the error persists, ensure that no other network / security appliances are affecting the requests between the client workstation and Kong Gateway.
