```
Choose the profile that commands use when you do not give --profile.

With one profile installed, commands use it. With several, they use the
default profile. Until you choose one, the default is the first profile in
profile list. If you delete the default profile, the first profile becomes the
default again. Changing the default does not change any agent CLI settings,
because each agent CLI names its own profile.

Usage:
  kong-harnesses profile default <name> [flags]

Examples:
  # Make work the default profile
  kong-harnesses profile default work

Flags:
  -h, --help   help for default

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```