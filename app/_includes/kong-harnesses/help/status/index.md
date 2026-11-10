```ansi
Show the sign-in of a profile and the agent CLIs set up to use it. status
does not use the network.

Without --profile or KONG_HARNESSES_PROFILE, status lists every installed
profile, its sign-in and the agent CLIs that use it. Without --client, it
shows every agent CLI that the profile lists, one block for each.

Usage:
  kong-harnesses status [flags]

Examples:
  # Show every installed profile, its sign-in and the agent CLIs that use it
  kong-harnesses status
  # Show profile work as JSON
  kong-harnesses status --profile work -o json

Flags:
  -h, --help              help for status
  -o, --output format     output format: text (the default), json, or yaml
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```