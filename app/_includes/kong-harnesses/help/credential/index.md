```
Print a short-lived access token for a profile.

If you are not signed in yet, credential signs you in first. Some agent CLIs
run this command to get their token. Others run token, which never signs in.

Usage:
  kong-harnesses credential [flags]

Examples:
  # Print an access token for profile work, signing in first when needed
  kong-harnesses credential --profile work

Flags:
  -h, --help              help for credential
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```