```ansi
Manage connection profiles and the agent CLIs that use them.

Usage:
  kong-harnesses profile [flags]
  kong-harnesses profile [command]

Aliases:
  profile, profiles

Examples:
  # List the installed profiles
  kong-harnesses profile list
  # Install a profile from a URL your admin gave you
  kong-harnesses profile import <profile-url>

Available Commands:
  activate    Set up the installed agent CLIs to use a profile
  cleanup     Remove the settings that kong-harnesses added
  create      Create a profile from your identity provider's details
  default     Choose the default profile
  delete      Delete an installed profile from this computer
  get         Show the settings of an installed profile
  import      Install a profile from a file or HTTPS URL
  list        List installed profiles

Flags:
  -h, --help   help for profile

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)

Use "kong-harnesses profile [command] --help" for more information about a command.
```