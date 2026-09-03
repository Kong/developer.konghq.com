---
title: "MCP version support"
content_type: reference
layout: reference

products:
  - ai-gateway
works_on:
  - konnect
breadcrumbs:
  - /ai-gateway/
tags:
  - ai
  - mcp
permalink: /ai-gateway/mcp-version-support/
description: What's new in the MCP 2026-07-28 specification and how {{site.ai_gateway}} supports it.

related_resources:
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: MCP traffic gateway
    url: /mcp/
  - text: Model Context Protocol specification
    url: https://modelcontextprotocol.io/specification/2026-07-28/
  - text: MCP 2026-07-28 release announcement
    url: https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/
---

{% include md/ai-gateway/v2/mcp-versions.md %}

## 2026-07-28 {% new_in 2.1 %}

The Model Context Protocol (MCP) [2026-07-28 revision](https://modelcontextprotocol.io/specification/2026-07-28/) is the largest change to MCP since launch. 

Earlier MCP revisions (`2025-06-18` and `2025-11-25`) share a session-based transport. A client establishes a session with an `initialize`/`initialized` handshake, receives an `Mcp-Session-Id`, and carries that ID on every subsequent request. The server handling that session must track its state, which in practice requires sticky routing behind a load balancer.

The `2026-07-28` revision removes the handshake and `Mcp-Session-Id` entirely. Every request is self-contained: the client declares its protocol revision and identity on each call instead of once at connection time. Any server instance can handle any request, and sticky routing is no longer required at the protocol layer.

### Specification changes

The [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity detects a client's protocol revision from the `MCP-Protocol-Version` header, reconfirmed from `_meta`, and applies the matching request and response model on the same route that already serves older revisions. The following table describes each change between the `2026-07-28` revision and the previous ones, and the specific impact on {{site.ai_gateway}}.

<!-- vale off -->
{% table %}
columns:
  - title: Area
    key: area
  - title: "2025-06-18 / 2025-11-25"
    key: before
  - title: "2026-07-28"
    key: after
  - title: "Impact on {{site.ai_gateway}}"
    key: impact
rows:
  - area: Session lifecycle
    before: "`initialize` handshake plus `Mcp-Session-Id` on every request"
    after: "No session; protocol version and client info carried in `_meta` per request"
    impact: "Stateless dispatch: no `initialize`/`initialized` exchange, no `Mcp-Session-Id` issued or expected, and an inbound `Mcp-Session-Id` header is ignored"
  - area: Capability exchange
    before: One-time at connection
    after: "`server/discover` on demand"
    impact: "`server/discover` replaces `initialize` as the way a `2026-07-28` client fetches server capabilities"
  - area: Routing signal
    before: Body inspection required
    after: "`Mcp-Method` and `Mcp-Name` headers on every request"
    impact: "`Mcp-Method` and `Mcp-Name` headers are validated against the JSON-RPC body; a mismatch is rejected"
  - area: Tool list freshness
    before: Long-lived SSE stream for change notification
    after: "`ttlMs` and `cacheScope` per response"
    impact: "`tools/list` and `server/discover` responses can carry `ttl_ms` and `cache_scope` cache hints, configured through [`config.server.cache`](/ai-gateway/entities/ai-mcp-server/#mcp-versions)"
{% endtable %}
<!-- vale on -->

These changes are breaking at the protocol level: a `2026-07-28` client sending a stateless request to a server that only expects a session handshake gets an error or is misrouted. A revision-aware gateway is what lets both kinds of clients reach the same endpoint safely.

The following {{site.ai_gateway}} behaviors are specific to the `2026-07-28` revision but don't map to a single spec change:

- **Header validation**: `Mcp-Method` and `Mcp-Name` headers are validated against the JSON-RPC body, a mismatch is rejected.
- **HTTP-status errors**: A JSON-RPC failure carries its own HTTP status instead of being nested inside an HTTP 200 response.
- **Unsupported revisions**: A client declaring a revision the server doesn't accept gets `HTTP 400` with JSON-RPC error `-32022`, listing the revisions the server serves. Narrow the accepted set with [`config.server.allowed_versions`](/ai-gateway/entities/ai-mcp-server/#mcp-versions).
- **Scope-hierarchy ACLs**: An OAuth-scope ACL rule matches on scope hierarchy for `2026-07-28` clients, so a broader granted scope satisfies a rule naming a narrower one. Earlier revisions keep exact-match comparison.

For field-level configuration, see [MCP versions](/ai-gateway/entities/ai-mcp-server/#mcp-versions) on the AI MCP Server entity page.
