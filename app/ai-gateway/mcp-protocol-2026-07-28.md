---
title: "MCP 2026-07-28 protocol support"
content_type: reference
layout: reference

products:
  - ai-gateway
works_on:
  - konnect
min_version:
  ai-gateway: '2.1'
breadcrumbs:
  - /ai-gateway/
tags:
  - ai
  - mcp
permalink: /ai-gateway/mcp-protocol-2026-07-28/
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

The Model Context Protocol (MCP) [2026-07-28 revision](https://modelcontextprotocol.io/specification/2026-07-28/) is the largest change to MCP since launch. Starting in {{site.ai_gateway}} 2.1, [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) supports this revision alongside the earlier `2025-03-26`, `2025-06-18`, and `2025-11-25` revisions on the same endpoint.

## Why this revision matters

Earlier MCP revisions (`2025-06-18` and `2025-11-25`) share a session-based transport. A client establishes a session with an `initialize`/`initialized` handshake, receives an `Mcp-Session-Id`, and carries that ID on every subsequent request. The server handling that session must track its state, which in practice requires sticky routing behind a load balancer.

The 2026-07-28 revision removes the handshake and `Mcp-Session-Id` entirely. Every request is self-contained: the client declares its protocol revision and identity on each call instead of once at connection time. Any server instance can handle any request, and sticky routing is no longer required at the protocol layer.

## What changed in the spec

<!-- vale off -->
{% table %}
columns:
  - title: Area
    key: area
  - title: "2025-06-18 / 2025-11-25"
    key: before
  - title: "2026-07-28"
    key: after
rows:
  - area: Session lifecycle
    before: "`initialize` handshake plus `Mcp-Session-Id` on every request"
    after: "No session; protocol version and client info carried in `_meta` per request"
  - area: Capability exchange
    before: One-time at connection
    after: "`server/discover` on demand"
  - area: Server-to-client prompts
    before: SSE stream held open
    after: "`InputRequiredResult` with a client retry carrying `requestState`"
  - area: Routing signal
    before: Body inspection required
    after: "`Mcp-Method` and `Mcp-Name` headers on every request"
  - area: Tool list freshness
    before: Long-lived SSE stream for change notification
    after: "`ttlMs` and `cacheScope` per response"
  - area: Trace correlation
    before: Unofficial
    after: "W3C Trace Context keys fixed in `_meta`"
  - area: Tool input schemas
    before: Restricted JSON Schema subset
    after: "Full JSON Schema 2020-12 (composition, `$ref`, `$defs`)"
  - area: Missing resource error code
    before: "`-32002` (MCP custom)"
    after: "`-32602` (JSON-RPC standard)"
{% endtable %}
<!-- vale on -->

These changes are breaking at the protocol level: a `2026-07-28` client sending a stateless request to a server that only expects a session handshake gets an error or is misrouted. A revision-aware gateway is what lets both kinds of clients reach the same endpoint safely.

## How {{site.ai_gateway}} supports 2026-07-28

[AI MCP Server](/ai-gateway/entities/ai-mcp-server/) detects a client's protocol revision from the `MCP-Protocol-Version` header, reconfirmed from `_meta`, and applies the matching request and response model on the same route that already serves older revisions. Specifically:

- **Stateless dispatch.** No `initialize`/`initialized` exchange, no `Mcp-Session-Id` issued or expected, and an inbound `Mcp-Session-Id` header is ignored.
- **`server/discover`.** Replaces `initialize` as the way a `2026-07-28` client fetches server capabilities.
- **Header validation.** `Mcp-Method` and `Mcp-Name` headers are validated against the JSON-RPC body; a mismatch is rejected.
- **HTTP-status errors.** A JSON-RPC failure carries its own HTTP status instead of riding inside an HTTP 200 response.
- **Unsupported revisions.** A client declaring a revision the server doesn't accept gets `HTTP 400` with JSON-RPC error `-32022`, listing the revisions the server serves. Narrow the accepted set with [`config.server.allowed_versions`](/ai-gateway/entities/ai-mcp-server/#mcp-protocol-versions).
- **Cache hints.** `tools/list` and `server/discover` responses can carry `ttl_ms` and `cache_scope` cache hints, configured through [`config.server.cache`](/ai-gateway/entities/ai-mcp-server/#mcp-protocol-versions).
- **Scope-hierarchy ACLs.** An OAuth-scope ACL rule matches on scope hierarchy for `2026-07-28` clients, so a broader granted scope satisfies a rule naming a narrower one. Earlier revisions keep exact-match comparison.

For field-level configuration, see [MCP protocol versions](/ai-gateway/entities/ai-mcp-server/#mcp-protocol-versions) on the AI MCP Server entity page.
