---
title: Response Ratelimiting plugin

name: Response Ratelimiting
publisher: kong-inc
tier: oss
konnect_compatible: true
content_type: plugin
description: Rate limit based on a custom response header value.
tags:
  - rate-limiting
  - graphql-rate-limiting-advanced
  - traffic-control
---

This plugin allows you to limit the number of requests a developer can make based on a custom response header returned by the upstream service. You can arbitrarily set as many rate limiting objects (or quotas) as you want and instruct Kong to increase or decrease them by any number of units. Each custom rate limiting object can limit the inbound requests per seconds, minutes, hours, days, months, or years.

If the underlying service or route has no authentication layer, the Client IP address is used. Otherwise, the consumer is used if an authentication plugin has been configured.

