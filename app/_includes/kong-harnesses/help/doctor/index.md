```
Check one profile end to end and report each fix beside its finding.

Unlike status, this reaches the network: it establishes and closes one
connection to the issuer and to the gateway. It opens no browser and writes
no settings. Under --client opencode it also asks the npm registry, with your
own npm token, whether OpenCode can install the gateway plugin, and looks for
the plugin in OpenCode's cache.

For Claude Code it also reads the gateway's model list with the profile's
sign-in, as activation does, and checks that /model offers only what the
gateway serves, that the configured model is one of those, and that no
setting still sends Claude Code to Anthropic.

--json writes the report as one JSON document with a schema_version.

--report writes the JSON report for a support ticket. It adds the
agent-auth-cli and Claude Code versions, the platform, and the Claude Code
settings and shell variables. Each value that can hold a credential is
replaced with <redacted>, so the report can be attached as it is.

--inference sends one small request through the active Claude Code route.
It uses the selected model, profile sign-in, CA bundle, and process proxy.
It checks a complete response stream from the Anthropic API.
This request can incur model charges. The prompt is "Reply with OK." and
the output limit is 16 tokens. The check sends no files or conversation data.
It opens no browser and makes no automatic retry or provider fallback.

Usage:
  agent-auth-cli doctor --name <name> [--json | --report] [--inference]
```