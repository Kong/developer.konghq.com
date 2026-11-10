```ansi
Check that a profile works from start to end, and show a fix for each
problem found.

Without --profile or KONG_HARNESSES_PROFILE, doctor checks the only installed
profile, or the default profile if there are several. Without --client, it
checks every agent CLI that the profile lists, with one report for each.

Unlike status, doctor uses the network. It connects to the identity provider
and to the gateway for each agent CLI. It does not open a browser and does
not change any settings. It also checks that:

  - the gateway has a route for each agent CLI that is set up, and accepts
    your sign-in there (doctor sends an empty request to find out)
  - for OpenCode, npm can install the gateway plugin (doctor asks the npm
    registry with your own npm token), and the plugin is in OpenCode's cache
  - for Claude Code, /model offers only the models that the gateway serves,
    the selected model is one of them, and no setting still sends Claude
    Code to Anthropic

-o json prints the report as one JSON document with a schema_version and one
entry for each agent CLI. -o yaml prints the same document as YAML.

--report prints a JSON report to attach to a support ticket. It adds the
kong-harnesses version and the platform. For Claude Code it adds the
settings, the shell variables and the Claude Code version. For Codex,
OpenCode and omp it adds only the path of the config file and whether that
file exists. Each value that can hold a secret is replaced with <redacted>,
so you can attach the report as it is.

--inference sends one small model request through Claude Code's route, so
the profile must set up Claude Code. It uses the selected model, your
sign-in, the CA bundle and the proxy, and checks for a complete answer from
the Anthropic API. This request can cost money. The prompt is "Reply with
OK." and the answer is at most 16 tokens. It sends no files and no chat
history. It does not open a browser, retry, or switch to another provider.

Usage:
  kong-harnesses doctor [flags]

Examples:
  # Check the default profile and every agent CLI it lists
  kong-harnesses doctor
  # Also send one small model request through Claude Code's route (this can cost money)
  kong-harnesses doctor --profile work --inference
  # Print a report to attach to a support ticket
  kong-harnesses doctor --profile work --report

Flags:
  -h, --help              help for doctor
      --inference         send one small model request through Claude Code's route; this can cost money
  -o, --output format     output format: text (the default), json, or yaml
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too
      --report            print a JSON report to attach to a support ticket

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```