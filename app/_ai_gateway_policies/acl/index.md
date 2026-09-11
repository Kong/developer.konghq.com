---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: Control which AI Consumers and AI Consumer Groups can access entities
related_resources:
  - text: Enforce tiered AI budgets on AI Models with {{site.identity}}
    url: /ai-gateway/enforce-tiered-ai-budgets-with-kong-identity/
related_resources:
  - text: AI Consumer
    url: /ai-gateway/entities/ai-consumer/
related_resources:
  - text: AI Consumer Group
    url: /ai-gateway/entities/ai-consumer-group/
---

The ACL (access control list) policy allows you to restrict [AI Consumers](/ai-gateway/entities/ai-consumer/) or [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) access to {{site.ai_gateway}} entities. You do this by configuring **either** an allow list or a deny list with AI Consumer or AI Consumer Group names. 

This policy requires that Consumers are authenticated and you should set up [AI Auth Strategies](/ai-gateway/entities/ai-auth-strategy/) before enabling this policy.

## Upstream Consumer Groups header

If `hide_groups_header` is set to `false` and an AI Consumer is validated, {{site.ai_gateway}} appends a `X-Consumer-Groups` header to the request before proxying it to the upstream service. The header contains a comma separated list of groups that belong to the AI Consumer, for example `admin, pro_user`. This allows you to identify the groups associated with the AI Consumer. 