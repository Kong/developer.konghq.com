```ansi
Print the status bar line for Claude Code.

Claude Code sends its session data to this command on stdin and shows what
the command prints. The line always describes Claude Code, even with
--client. To use it, add this to Claude Code's settings:

  "statusLine": {"type": "command", "command": "kong-harnesses statusline --profile <name>"}

Usage:
  kong-harnesses statusline [flags]

Examples:
  # Print the status bar line of profile work from a saved session file
  kong-harnesses statusline --profile work < session.json

Flags:
  -h, --help              help for statusline
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```