# Policy page frontmatter

Match existing migrated pages. Open one or two pages in `app/_ai_gateway_policies/` first to confirm the template still holds.

```yaml
---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin      # existing policy pages use `plugin`; confirm with a grep before changing
description: 'One or two sentences, written for search results.'
categories:
  - <category from the plugin>
tags:
  - <tags from the plugin>
  - ai
search_aliases:
  - <plugin-slug>
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity          # one per scope the policy supports
    url: /ai-gateway/entities/ai-model/
---
```

- Drop plugin-only fields: `publisher`, `topologies`, `icon`, `min_version.gateway`, `products: gateway`. The page is AI Gateway only, and the frontmatter validator rejects these for this collection.
- Do not add `faqs:` unless the user asks.
- Entity link slugs: `ai-model`, `ai-agent`, `ai-mcp-server`, `ai-consumer`, `ai-consumer-group`. Confirm each exists in `app/_ai_gateway_entities/`.
- After any frontmatter change, run `node tools/frontmatter-validator/index.js <file>`.
