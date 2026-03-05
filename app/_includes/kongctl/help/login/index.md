```bash
Usage:
  kongctl login [flags]
  kongctl login [command]

Examples:
  # Login to Kong Konnect (default)
  kongctl login
  
  # Login to Kong Konnect (explicit)
  kongctl login konnect

Available Commands:
  konnect     Login to Konnect


Flags:
      --auth-path string       URL path used to initiate Konnect Authorization.
                               - Config path: [ konnect.auth-path ]
                               - (default "/v3/internal/oauth/device/authorize")
      --base-auth-url string   Base URL used for Konnect Authorization requests.
                               - Config path: [ konnect.base-auth-url ]
                               - (default "https://global.api.konghq.com")
      --color-theme string     Configures the CLI UI/theme (prompt, tables, TUI elements).
                               - Config path: [ color-theme ]
                               - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                               - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string     Path to the configuration file to load.
                               - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                   help for login
      --log-file string        Write execution logs to the specified file instead of STDERR.
                               - Config path: [ log-file ]
      --log-level string       Configures the logging level. Execution logs are written to STDERR.
                               - Config path: [ log-level ]
                               - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string          Configures the format of data written to STDOUT.
                               - Config path: [ output ]
                               - Allowed    : [ json|yaml|text ] (default "text")
  -p, --profile string         Specify the profile to use for this command. (default "default")
      --refresh-path string    URL path used to refresh the Konnect auth token.
                               - Config path: [ konnect.refresh-path ]
                               - (default "/kauth/api/v1/refresh")
      --token-path string      URL path used to poll for the Konnect Authorization response token.
                               - Config path: [ konnect.token-path ]
                               - (default "/v3/internal/oauth/device/token")

Use "kongctl login [command] --help" for more information about a command.

```