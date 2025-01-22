---
title: Bootstrap RBAC
content_type: how_to

products:
    - gateway

tools:
    - deck

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

@todo Create a super-admin in KGW set up default workspaces and teams validate isolated workspace.

Maybe https://docs.konghq.com/gateway/latest/production/access-control/enable-rbac/ ?


## Create an RBAC user

Creating an RBAC User requires [RBAC to be enabled](#enable-rbac) for {{site.base_gateway}}.

{% entity_example %}
type: rbac
data:
  name: my-user
  user_token: exampletoken
headers:
  admin-api:
    - "Kong-Admin-Token: $ADMIN_TOKEN"
{% endentity_example %}