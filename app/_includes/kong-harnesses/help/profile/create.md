```ansi
Create a connection profile and install it. kong-harnesses reads the details
of your identity provider from its OIDC discovery document.

Run it without flags to answer the questions in three steps.

The profile sets up Claude Code. A --client that the profile does not set up
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
      --anthropic-telemetry on|off           Claude Code usage metrics and feature-flag requests sent to Anthropic (it sends error reports only on a direct Anthropic API connection, so a profile sends none): on|off, on when given alone (default off)
      --audience uri                         resource identifier of the gateway, as an absolute uri; the sign-in request sends it unless --audience-parameter is none, and the token's aud can differ, as with Entra ID
      --audience-parameter resource          how the sign-in request sends the audience: resource, audience or none (default resource)
      --auto-mode-gateway-check on|off       Claude Code runs auto mode's check through the gateway: on|off, on when given alone (default off)
      --auto-updates on|off                  Claude Code auto-updates: on|off, on when given alone (default off)
      --client-id id                         OIDC client id (a public client, with no secret)
      --gateway-origin origin                HTTPS address of the gateway (its origin), or http:// on localhost
  -h, --help                                 help for create
      --issuer url                           OIDC issuer url
      --max-token-lifetime-seconds seconds   longest token lifetime to accept, in seconds, from 365 to 86400; a renewed token must still have 360 seconds left when a client gets it (default 3600)
      --mcp-key-header name=header           header that a --mcp-key-server server reads its key from, as name=header (default apikey); repeat for each
      --mcp-key-server name=/path            gateway MCP server that takes a key your administrator gives each developer, as name=/path; login asks for the key; repeat for each
      --mcp-oauth-server name=/path          gateway MCP server with its own OAuth sign-in, as name=/path; repeat for each
      --mcp-server name=/path                gateway MCP server that uses the same sign-in as the models, as name=/path; repeat for each
      --model id                             id of the model the agent CLIs start with
      --name name                            name of the new profile
      --prompt-cache lifetime                prompt cache lifetime: off, 5m or 1h (default 1h)
      --provider provider                    model provider: anthropic, mantle, foundry (default anthropic)
      --public-client-evidence deployment    accept a provider whose discovery does not list none as a token endpoint auth method: deployment; it skips only that check, so first show on a test deployment that sign-in and renewal work without a client secret
      --redirect-uri url                     local redirect url that the sign-in returns to (default http://localhost:9876/callback)
      --scope scope                          OIDC scope to request; repeat for each, at most 16 (default openid profile email offline_access)
      --sign-in kind                         kind of sign-in when it is not only an identity provider: static-key, a key from the administrator in place of an identity provider; or environment-key, the same key read from KONG_HARNESSES_STATIC_KEY on every call, for a CI job; or subscription, each developer's own Claude subscription, with --issuer, --client-id and --audience too
      --tool-reference on|off                Claude Code tool references: on|off, on when given alone (default on)

Global Flags:
      --client client     the one agent client to work on: claude-code
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```