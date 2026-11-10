```ansi
Sign in to a profile, or check its sign-in.

Without --profile or KONG_HARNESSES_PROFILE, login uses the only installed
profile, or the default profile if there are several.

Usage:
  kong-harnesses login [flags]

Examples:
  # Sign in to the default profile
  kong-harnesses login
  # Print the sign-in URL of profile work, to open in a browser on this computer
  kong-harnesses login --profile work --no-browser
  # Check the sign-in of profile work without signing in
  kong-harnesses login --profile work --diagnostics

Flags:
      --diagnostics       check the sign-in without signing in
  -h, --help              help for login
      --no-browser        print the sign-in URL instead of opening a browser; open the URL on this computer
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too
      --replace           sign in again, even if you are already signed in

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```