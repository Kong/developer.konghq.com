If the AI Model, AI Agent, or AI MCP Server handling the request has no authentication layer, the [client IP address](#limit-by-ip-address) is used to identify clients.
Otherwise, the AI Consumer is used once an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) has authenticated the request.
