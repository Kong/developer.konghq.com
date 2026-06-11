```ansi
Usage:
  kongctl delete spat [id|name] [flags]

Aliases:
  spat, spats

Examples:
  kongctl delete spat ci --system-account-name ci-bot --auto-approve


Flags:
      --auto-approve                 Skip confirmation prompts for delete operations
      --base-url string              Base URL for Konnect API requests.
                                     - Config path: [ konnect.base-url ]
                                     - Default   : [ https://us.api.konghq.com ]
      --color-theme string           Configures the CLI UI/theme (prompt, tables, TUI elements).
                                     - Config path: [ color-theme ]
                                     - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                     - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string           Path to the configuration file to load.
                                     - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --force                        Force deletion even when related resources exist (not configurable)
  -h, --help                         help for spat
      --log-file string              Write execution logs to the specified file instead of STDERR.
                                     - Config path: [ log-file ]
      --log-level string             Configures the logging level. Execution logs are written to STDERR.
                                     - Config path: [ log-level ]
                                     - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --no-telemetry                 Disable telemetry for this command invocation. Overrides config and env.
                                     - Config path: [ telemetry.enabled ]
                                     - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                     - Default    : [ false ]
  -o, --output string                Configures the format of data written to STDOUT.
                                     - Config path: [ output ]
                                     - Allowed    : [ json|yaml|text ] (default "text")
      --pat string                   Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                     Setting this value overrides tokens obtained from the login command.
                                     - Config path: [ konnect.pat ]
  -p, --profile string               Specify the profile to use for this command. (default "default")
      --region string                Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                     - Config path: [ konnect.region ]
      --system-account-id string     Konnect system account ID
      --system-account-name string   Konnect system account name

```