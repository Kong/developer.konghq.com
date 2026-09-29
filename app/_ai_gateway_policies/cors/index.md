---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: plugin
description: 'Configure Cross-Origin Resource Sharing (CORS) so that browser clients on approved origins can call your AI Models, AI Agents, and AI MCP Servers.'
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
tags:
  - security
  - ai
---

The CORS Policy lets you configure Cross-Origin Resource Sharing (CORS) for {{site.ai_gateway}}. This automates your CORS rules, so your AI Models, AI Agents, and AI MCP Servers only accept and share resources with approved origins.


{% include md/ai-gateway/v2/policies/cors-and-ai-gateway.md %}

## CORS limitations

When the client is a browser, the preflight OPTIONS requests defined by the [CORS specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS) have strict rules about which headers can be set.
Certain headers, including Host, are classified as forbidden headers, meaning the browser always controls their value and they can't be customized in code (for example, in JavaScript).
As a result, a browser can't send a custom Host header during a preflight request.
