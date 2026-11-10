```
Refresh the budget numbers that the status bar shows.

The command asks the gateway for your budgets with your saved access token,
and saves the answer next to the profile. It never signs in, renews the
token, or asks questions. Without a valid saved token, it saves nothing.

The status bar runs this command in the background and shows the numbers it
saved last time, so the command always exits with success, even when the
refresh fails.

Usage:
  kong-harnesses budget [command]

Examples:
  # Refresh the budget numbers of profile work
  kong-harnesses budget refresh --profile work

Available Commands:
  refresh     Refresh the budget numbers of one profile

Flags:
  -h, --help   help for budget

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)

Use "kong-harnesses budget [command] --help" for more information about a command.
```