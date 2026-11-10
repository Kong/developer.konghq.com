```ansi
Print a short-lived access token for a profile.

token never signs in. If you are not signed in, it fails and tells you to
run login. Some agent CLIs run this command to get their token.

Usage:
  kong-harnesses token [flags]

Examples:
  # Print an access token for profile work without signing in
  kong-harnesses token --profile work

Flags:
  -h, --help              help for token
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```