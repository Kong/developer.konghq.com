```
Remove the settings that kong-harnesses added to the agent CLIs.

Without --client, cleanup removes them from every supported agent CLI, so no
agent CLI is left half set up. With --client, it cleans up only that agent
CLI: claude-code, codex, opencode, or omp.

Usage:
  kong-harnesses profile cleanup [flags]

Examples:
  # Show what cleanup would remove
  kong-harnesses profile cleanup --dry-run
  # Remove the settings that kong-harnesses added
  kong-harnesses profile cleanup

Flags:
      --dry-run   show the changes without making them
  -h, --help      help for cleanup

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```