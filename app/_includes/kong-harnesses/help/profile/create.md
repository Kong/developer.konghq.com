```ansi
Create a connection profile and install it. kong-harnesses reads the details
of your identity provider from its OIDC discovery document.

Run it without flags to answer the questions in three steps.

The profile sets up Claude Code, Codex, OpenCode, omp and pi, and Hermes when
--audience-parameter is audience. A --client that the profile does not set up
is refused before anything is saved.

--mcp-server, --mcp-oauth-server and --mcp-key-server add MCP servers that
the gateway serves. Activation adds them to Claude Code.

After it saves the profile, it sends an empty test request, without your
sign-in, to the gateway route of each agent CLI. It warns about each route
that the gateway does not have.

The built-in policy selects the provider when --provider is absent.

Usage:
  kong-harnesses profile create [flags]

Aliases:
  create, c, C

Examples:
  # Create a profile by answering questions
  kong-harnesses profile create
  # Create one without questions
  kong-harnesses profile create --name work --issuer <issuer-url> --client-id <client-id> --audience <audience> --gateway-origin <gateway-url> --model <model-id>

Flags:
      --advisor on|off                       Claude Code's advisor tool: on|off, on when given alone (default off)
      --audience uri                         audience of the access token, as a uri
      --audience-parameter resource          how the sign-in request sends the audience: resource, audience or none (default resource)
      --auto-updates on|off                  Claude Code auto-updates: on|off, on when given alone (default off)
      --client-id id                         OIDC client id (a public client, with no secret)
      --gateway-origin origin                HTTPS address of the gateway (its origin)
  -h, --help                                 help for create
      --issuer url                           OIDC issuer url
      --max-token-lifetime-seconds seconds   longest token lifetime to accept, in seconds, from 360 to 86400 (default 3600)
      --mcp-key-header name=header           header that a --mcp-key-server server reads its key from, as name=header (default apikey); repeat for each
      --mcp-key-server name=/path            gateway MCP server that takes a key your administrator gives each developer, as name=/path; login asks for the key; repeat for each
      --mcp-oauth-server name=/path          gateway MCP server with its own OAuth sign-in, as name=/path; repeat for each
      --mcp-server name=/path                gateway MCP server that uses the same sign-in as the models, as name=/path; repeat for each
      --model id                             id of the model the agent CLIs start with
      --name name                            name of the new profile
      --prompt-cache lifetime                prompt cache lifetime: off, 5m or 1h (default 1h)
      --provider provider                    model provider: anthropic, mantle, foundry (default anthropic)
      --public-client-evidence deployment    why the OIDC client may have no secret: deployment
      --redirect-uri url                     local redirect url that the sign-in returns to (default http://localhost:9876/callback)
      --scope scope                          OIDC scope to request; repeat for each, at most 16 (default openid profile email offline_access)
      --sign-in kind                         kind of sign-in when not only an identity provider: static-key, a key from the administrator, with no identity provider; or environment-key, the same key read from KONG_HARNESSES_STATIC_KEY on every call, for a CI job
      --tool-reference on|off                Claude Code tool references: on|off, on when given alone (default on)

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, omp, hermes, or pi
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```