```ansi
Show the settings of an installed profile. A profile holds no secrets.

Usage:
  kong-harnesses profile get <name> [flags]

Aliases:
  get, g

Examples:
  # Show the settings of profile work
  kong-harnesses profile get work
  # Print it as JSON
  kong-harnesses profile get work -o json

Flags:
  -h, --help            help for get
  -o, --output format   output format: text (the default), json, or yaml

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```