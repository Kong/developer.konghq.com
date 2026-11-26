```ansi
Sign in to a profile, or check its sign-in.

Without --profile or KONG_HARNESSES_PROFILE, login uses the only installed
profile, or the default profile if there are several.

With --diagnostics, login signs in when the saved sign-in is missing or
cannot be used, which can open the browser. It then says which part of the
sign-in failed. It never prints the token or the sign-in URL.

Usage:
  kong-harnesses login [flags]

Examples:
  # Sign in to the default profile
  kong-harnesses login
  # Print the sign-in URL of profile work, to open in a browser on this computer
  kong-harnesses login --profile work --no-browser
  # Find out why the sign-in of profile work fails; it signs in if needed
  kong-harnesses login --profile work --diagnostics

Flags:
      --diagnostics       sign in if needed, then say which part of the sign-in failed
  -h, --help              help for login
      --no-browser        print the sign-in URL instead of opening a browser; open the URL on this computer
  -p, --profile profile   the installed profile to use; KONG_HARNESSES_PROFILE sets it too
      --replace           sign in again, even if you are already signed in

Global Flags:
      --client client     the one agent client to work on: claude-code
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```