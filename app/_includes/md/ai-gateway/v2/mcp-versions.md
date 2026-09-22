{{site.ai_gateway}} accepts the following client-facing MCP revisions:
* `2025-03-26`
* `2025-06-18`
* `2025-11-25`
* {% new_in 2.1 %} `2026-07-28`

`2026-07-28` is a stateless revision: it removes the `initialize` handshake and `Mcp-Session-Id` entirely, so the client declares its revision on every request instead of once at connection time.