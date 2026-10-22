When you attach an AI Auth Strategy to an AI Model, AI Agent, or AI MCP Server, {{site.ai_gateway}} auto-provisions a shared anonymous AI Consumer with a Request Termination policy under the hood, and points the auth strategy's failure path at it. 
By default, this means that any request that fails authentication (for example, no credential, an invalid token, or a valid token that doesn't map to a known AI Consumer or {{site.identity}} principal) is routed to that anonymous AI Consumer and rejected with `401 Unauthorized` before it reaches the AI Model, AI Agent, or AI MCP Server.

Two settings opt specific requests out of that default termination, without disabling it entirely:

* `config.consumer_optional: true` (`openid-connect` only): A valid token that doesn't map to any AI Consumer proceeds instead of terminating. The request still carries no AI Consumer identity.
* `config.principals.error_on_miss: false` (`key-auth` and `openid-connect`): A request that doesn't match any {{site.identity}} principal proceeds instead of terminating.

Neither setting affects a request without credentials or an invalid token, those always terminate through the anonymous AI Consumer regardless of `consumer_optional` or `principals.error_on_miss`.
