---
title: Create admins using the admin API
content_type: how_to

products:
    - gateway

works_on:
    - on-prem


tldr: 
  q: How do I apply multiple rate limits or window sizes with one plugin instance?
  a: |
    You can use the Rate Limiting Advanced plugin to apply any number of rate limits and window sizes per plugin instance. 
    This lets you create multiple rate limiting windows, for example, rate limit per minute and per hour, and per any arbitrary window size.

min_version:
    gateway: '3.4'
---

@todo Maybe this https://docs.konghq.com/gateway/latest/production/access-control/register-admin-api/ -- I think it needs to e