```
Build and install a connection profile using OIDC discovery.

Run without flags to start the interactive three-step setup.
The profile configures Claude Code, Codex, OpenCode, and omp. With --ca-bundle
it configures Claude Code only. A --client that the profile would not configure
is refused before anything is written.
The embedded policy selects the provider when --provider is absent.

Usage:
  agent-auth-cli profile create
  agent-auth-cli profile create \
    --name <name> \
    [--provider <anthropic|foundry|mantle>] \
    --issuer <issuer-url> \
    --client-id <public-client-id> \
    --gateway-origin <https-origin> \
    --audience <audience-uri> \
    --model <provider-model-id> \
    [--ca-bundle <pem-file>] \
    [--prompt-cache <off|5m|1h>] \
    [--tool-reference <on|off>] \
    [--advisor <on|off>] \
    [--audience-parameter <resource|audience|none>] \
    [--public-client-evidence <deployment>] \
    [--redirect-uri <http-loopback-url>] \
    [--max-token-lifetime-seconds <seconds>] \
    [--auto-updates <on|off>] \
    [--scope <scope> ...]
```