```ansi
Usage:
  kongctl create spat [flags]

Aliases:
  spat, spats

Examples:
  kongctl create spat --system-account-name ci-bot --name ci --expires-in 30d -o env


Flags:
      --base-url string              Base URL for Konnect API requests.
                                     - Config path: [ konnect.base-url ]
                                     - Default   : [ https://us.api.konghq.com ]
      --color-theme string           Configures the CLI UI/theme (prompt, tables, TUI elements).
                                     - Config path: [ color-theme ]
                                     - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                     - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string           Path to the configuration file to load.
                                     - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --expires-at string            Token expiration timestamp in RFC3339 format, for example 2026-06-24T12:00:00Z or 2026-06-24T12:00:00+02:00. Fractional seconds are accepted. Must be between 1 day and 365 days (12 months) from now.
      --expires-in string            Token lifetime. Use a duration between 1 day and 365 days (12 months). Supported units are ns, us, ms, s, m, h, and d (days). Examples: 24h, 36h, 1d, 30d.
  -h, --help                         help for spat
      --jq string                    Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string              Controls colorized output for jq filter results.
                                     - Config path: [ jq.color.enabled ]
                                     - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string        Select the color theme used for jq filter results.
                                     - Config path: [ jq.color.theme ]
                                     - Examples   : [ friendly, github-dark, dracula ]
                                     - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output                Output string jq results without JSON quotes (like jq -r).
                                     - Config path: [ jq.raw-output ]
      --log-file string              Write execution logs to the specified file instead of STDERR.
                                     - Config path: [ log-file ]
      --log-level string             Configures the logging level. Execution logs are written to STDERR.
                                     - Config path: [ log-level ]
                                     - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --name string                  Token name
      --no-telemetry                 Disable telemetry for this command invocation. Overrides config and env.
                                     - Config path: [ telemetry.enabled ]
                                     - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                     - Default    : [ false ]
  -o, --output string                Configures the format of data written to STDOUT.
                                     - Config path: [ output ]
                                     - Allowed    : [ json|yaml|text|token|env ] (default "text")
      --pat string                   Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                     Setting this value overrides tokens obtained from the login command.
                                     - Config path: [ konnect.pat ]
  -p, --profile string               Specify the profile to use for this command. (default "default")
      --region string                Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                     - Config path: [ konnect.region ]
      --system-account-id string     Konnect system account ID
      --system-account-name string   Konnect system account name

```