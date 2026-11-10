```
List the installed profiles and mark the default profile.

Usage:
  kong-harnesses profile list [flags]

Aliases:
  list, ls, l

Examples:
  # List the installed profiles and the default
  kong-harnesses profile list
  # Print the list as YAML
  kong-harnesses profile list -o yaml

Flags:
  -h, --help            help for list
  -o, --output format   output format: text (the default), json, or yaml

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```