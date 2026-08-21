---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The CORS Policy lets you configure Cross-Origin Resource Sharing (CORS) for {{site.ai_gateway}}. This automates your CORS rules, so your upstreams only accept and share resources with approved origins.

{% include md/ai-gateway/v2/policies/cors-and-ai-gateway.md %}

## CORS limitations

When the client is a browser, the preflight OPTIONS requests defined by the [CORS specification](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) have strict rules about which headers can be set.
Certain headers, including Host, are classified as forbidden headers, meaning the browser always controls their value and they can't be customized in code (for example, in JavaScript).
As a result, a browser can't send a custom Host header during a preflight request.
