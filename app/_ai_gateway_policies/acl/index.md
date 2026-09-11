---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: Control which AI Consumers and AI Consumer Groups can access entities
tags:
  - traffic-control
  - authorization
categories:
  - traffic-control
search_aliases:
  - access control list
related_resources:
  - text: AI Auth Strategies
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: AI Consumer
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group
    url: /ai-gateway/entities/ai-consumer-group/
faqs:
  - q: What are the differences between an ACL AI Policy and the `access.acl` field?
    a: |
      The ACL AI Policy allows you to set `always_use_authenticated_groups` and `include_consumer_groups` which are `false` by default. When setting `access.acl` fields on an entity these are always `true`.
---

The ACL (access control list) policy allows you to restrict [AI Consumers](/ai-gateway/entities/ai-consumer/) or [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) access to {{site.ai_gateway}} entities. This is the same capability provided by `access.acls` for AI Models, AI MCP Servers, and AI Agents. However, the policy provides additional configuration options.

You can configure **either** an allow list or a deny list with AI Consumers, AI Consumer Groups or authenticated groups (discovered by an [AI Auth Strategy](https://developer.konghq.com/ai-gateway/entities/ai-auth-strategy/#oidc-token-authentication) running in `openid-connect` mode).

The ACL policy requires that AI Consumers are authenticated and you should set up [AI Auth Strategies](/ai-gateway/entities/ai-auth-strategy/) before enabling this policy.

## Upstream Consumer Groups header

If `hide_groups_header` is set to `false` and an AI Consumer is validated, {{site.ai_gateway}} appends a `X-Consumer-Groups` header to the request before proxying it to the upstream service. The header contains a comma separated list of groups that belong to the AI Consumer, for example `admin, pro_user`. This allows you to identify the groups associated with the AI Consumer. 