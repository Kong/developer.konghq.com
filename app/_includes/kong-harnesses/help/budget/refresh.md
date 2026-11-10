```
Refresh the budget numbers of one profile

Usage:
  kong-harnesses budget refresh [flags]

Examples:
  # Refresh the budget numbers of profile work
  kong-harnesses budget refresh --profile work

Flags:
  -h, --help              help for refresh
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```