### LLM traffic metrics

When the `config.ai_metrics` parameter is set to `true` in the Prometheus plugin, you can get the following [AI LLM metrics](/ai-gateway/monitor-ai-llm-metrics/#llm-traffic-metrics-overview):

- **AI requests**: AI request sent to LLM providers.
- **AI cost**: AI cost charged by LLM providers.
- **AI tokens**: AI tokens counted by LLM providers.
- **AI LLM latency**: {% new_in 3.8 %} Time taken to return a response by LLM providers.
- **AI cache fetch latency**: {% new_in 3.8 %} Time taken to return a response from the cache.
- **AI cache embeddings latency**: {% new_in 3.8 %} Time taken to generate embedding during the cache.

These metrics are available per provider, model, cache, database name (if cached), embeddings provider (if cached), embeddings model (if cached), and Workspace. The AI Tokens metrics are also available per token type.

{:.info}
> **Note:** Starting with {% new_in 3.11 %}, AI metrics include the `consumer` label. This enables you to attribute AI usage and token counts to individual Consumers, helping you measure cost, performance, and client-specific behavior.
>
> Starting with {% new_in 3.12 %}, AI metrics (except `kong_ai_llm_tokens_total`) include the `request_mode` label. This label shows how the request was processed:
> - `oneshot`: A single response was returned.
> - `stream`: The response was delivered as a stream of tokens.
> - `realtime`: The request was handled as a real-time session.

### MCP traffic metrics {% new_in 3.12 %}

When the `config.ai_metrics` parameter is set to `true`, the following [MCP-specific metrics](/ai-gateway/monitor-ai-llm-metrics/#mcp-traffic-metrics-overview) are also available:

- **MCP response body size**: Histogram of response body sizes (in bytes) returned by MCP servers.
- **MCP latency**: Histogram of request latencies (in milliseconds) for MCP server calls.
- **MCP error total**: Counter of total MCP server errors, labeled by error type.

These metrics are labeled with `service`, `route`, `method`, `workspace`, and `tool_name`. The MCP error total metric also includes the type label.