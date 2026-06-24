Set `config.proxy_config` on this plugin to route its outbound requests through an HTTP forward proxy. Use this in network-isolated deployments where {{site.ai_gateway}} cannot open direct connections to LLM providers or auxiliary services.

The `proxy_config` record is identical across all {{site.ai_gateway}} plugins that support forward proxying. Existing capabilities such as load balancing, health checking, streaming, WebSocket, and HTTP/2 continue to work when the proxy is active.

For the full field reference, traffic flow, and limitations, see [Forward proxy support](/ai-gateway/forward-proxy/).
