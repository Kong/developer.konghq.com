## What is a plugin?

A **plugin** extends {{site.base_gateway}} with additional functionality — authentication, rate limiting, logging, request/response transformation, and more. Plugins run as part of the request lifecycle and can be applied at different scopes.

## Plugin scopes

Plugins can be attached to:

| Scope | What it affects |
|-------|----------------|
| **Global** | Every request through the gateway |
| **Service** | All requests forwarded to a specific upstream |
| **Route** | Requests matching a specific Route only |
| **Consumer** | Requests from a specific identified client |

More specific scopes take precedence over broader ones, giving you fine-grained control.

## Plugin execution order

Plugins run in a deterministic order based on their priority value. High-priority plugins (such as authentication) run before low-priority ones (such as logging). This ensures, for example, that a request is authenticated before rate limiting is applied.

## Key plugins to know

| Plugin | Purpose |
|--------|---------|
| [Key Auth](/hub/kong-inc/key-auth/) | Protect routes with API keys |
| [Rate Limiting](/hub/kong-inc/rate-limiting/) | Limit request rates by Consumer, IP, or globally |
| [Proxy Cache](/hub/kong-inc/proxy-cache/) | Cache upstream responses at the gateway |
| [Request Transformer](/hub/kong-inc/request-transformer/) | Add, remove, or rename headers and query parameters |
| [HTTP Log](/hub/kong-inc/http-log/) | Send request/response logs to an HTTP endpoint |

## Further reading

- [Plugin Hub](/hub/) — Browse all available plugins
- [Plugin configuration reference](/gateway/entities/plugins/)
- [Custom plugins](/custom-plugins/) — Write your own plugin in Lua or Go
