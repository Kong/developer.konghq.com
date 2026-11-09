* When it's scoped to an AI Agent or AI MCP Server, the policy caches responses for requests to that entity.
  Use this scope to cache the traffic of one entity.
* When it's scoped to an AI Consumer or AI Consumer Group, the policy caches responses for authenticated requests from that Consumer or from members of that group.
  Use this scope when only some clients need caching.
* When the policy is scoped to an AI Model, {{site.ai_gateway}} sends every request to the upstream.
  See [Limitations](#limitations).
