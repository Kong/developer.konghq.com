```
Install a connection profile from a file or HTTPS URL. A profile holds no
secrets. Profile schema versions 1 to 14 are supported.

Before it installs anything, import shows the gateway and identity provider of
the profile, and asks you to type the profile name. This needs a terminal.
--auto-approve answers yes in advance and prints the same summary to stderr,
so a run without a terminal still records what it installed.

Usage:
  kong-harnesses profile import <source> [flags]

Examples:
  # Install a profile from a file
  kong-harnesses profile import work.json
  # Install a profile from a URL, without typing its name
  kong-harnesses profile import <profile-url> --auto-approve

Flags:
      --auto-approve   install the profile without asking you to type its name
  -h, --help           help for import

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```