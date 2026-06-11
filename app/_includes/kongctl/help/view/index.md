```ansi
Usage:
  kongctl view [flags]

Aliases:
  view, v, V

Examples:
  # Launch the Konnect interactive viewer
  kongctl view


Flags:
      --base-url string      Base URL for Konnect API requests.
                             - Config path: [ konnect.base-url ]
                             - Default   : [ https://us.api.konghq.com ]
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                 help for view
      --log-file string      Write execution logs to the specified file instead of STDERR.
                             - Config path: [ log-file ]
      --log-level string     Configures the logging level. Execution logs are written to STDERR.
                             - Config path: [ log-level ]
                             - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --no-telemetry         Disable telemetry for this command invocation. Overrides config and env.
                             - Config path: [ telemetry.enabled ]
                             - Env var    : [ KONGCTL_NO_TELEMETRY ]
                             - Default    : [ false ]
  -o, --output string        Configures the format of data written to STDOUT.
                             - Config path: [ output ]
                             - Allowed    : [ json|yaml|text ] (default "text")
      --page-size int        Max number of results to include per response page.
                             - Config path: [ konnect.page-size ] (default 10)
      --pat string           Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                             Setting this value overrides tokens obtained from the login command.
                             - Config path: [ konnect.pat ]
  -p, --profile string       Specify the profile to use for this command. (default "default")
      --region string        Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                             - Config path: [ konnect.region ]

```