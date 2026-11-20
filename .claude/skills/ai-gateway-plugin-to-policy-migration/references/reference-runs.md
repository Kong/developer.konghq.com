# Reference runs

Use these as models for the shape and depth of a migration.

## request-termination (simple policy)
- The stub had frontmatter only. Schema: `app/_schemas/gateway/plugins/3.14/RequestTermination.json`.
- Verified live on `ai-quickstart` (`.tech`, runtime 2.2.0): status code and message, `trigger` header, `body` with `content_type`, `echo`, global scope, Model, Agent, MCP server, Consumer and Consumer Group scopes, streaming, real OpenAI, and execution order (a guardrail ran before termination).
- Findings that went into the page: `echo` exposes internal routing details; global scope stops all traffic; Consumer scopes need authentication first; guardrails run before termination.
- Plugin content dropped: Forward Proxy note, dynamic ordering, how-to link, use-case table.

## canary (policy with Gateway-only dependencies)
Model for a policy that redirects traffic.
- Runtime 2.3.0-rc.1 on `.tech`. Schema: `app/_schemas/gateway/plugins/3.16/Canary.json`. Priority `20`. Scopes: models, mcp-servers, agents, global.
- Needed a TLS mock upstream (SAN for `api.openai.com` and `host.docker.internal`) trusted by the data plane.
- Verified: `percentage`, `canary_by_header_name` (`always`, `never`), `hash` `consumer`, `header` and `ip`, `upstream_uri` (with and without a host), streaming, time-based start (before `start` all traffic goes to the primary), Model, Agent, MCP server and global scope.
- Contradicted or not working: `hash: allow` and `deny` with AI Consumer Groups (no match by group name, group ID or consumer name), `upstream_fallback` (no effect, a dead host returns `502`).
- AI Gateway behavior the plugin page never had: on a Model the redirected request keeps the provider's `Host` header, TLS server name and path; on an Agent the `Host` becomes the canary host; at MCP server scope the whole inbound MCP request is redirected, not the tool's upstream call; global scope affects every entity.
- Handled as findings, not page content: the MCP server behavior and the group mismatch went to the writer with a draft Slack question for engineering.
- Not tested, so left off or hedged on the page: the end state of a time-based rollout and whether the ramp is linear, `hash: ip` with different client IPs, the `steps` bucket granularity, whether the gateway translates the request format for a canary upstream, the finalize flow.
- Mistake to avoid: the first example shipped with `konnect-api` only and was written inline. Create examples with the `ai-gateway-policy-examples-migration` skill, which requires `konnect-api` and `kongctl` and checks the kongctl manifest.
- Incident to avoid: a root `kong reload` broke the container's startup (see `harness-ops.md`).
- Plugin content dropped: use-case table, KIC warning, Service and Upstream health check wording, ACL plugin dependency.
