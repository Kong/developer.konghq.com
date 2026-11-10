```
Remove settings values still owned by agent-auth-cli.

Usage:
  agent-auth-cli profile cleanup [--print-only]
  agent-auth-cli --client <name> profile cleanup [--print-only]

Without --client, cleanup reverses everything this tool owns in every
supported client at its default configuration location, so a machine reported
as cleaned up is not left half configured. The optional process-level --client
selector scopes it to one target: claude-code, codex, opencode, or omp. An
activation installed with --claude-config-location is bound to that file and
is reversed by repeating the same --claude-config-location.
```