```
Sign out of a profile.

Without --profile or KONG_HARNESSES_PROFILE, logout uses the only installed
profile, or the default profile if there are several.

Usage:
  kong-harnesses logout [flags]

Examples:
  # Sign out of profile work and remove its saved sign-in
  kong-harnesses logout --profile work

Flags:
  -h, --help              help for logout
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```