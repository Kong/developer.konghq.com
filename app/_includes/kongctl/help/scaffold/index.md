```ansi
Usage:
  kongctl scaffold <resource-path> [flags]

Examples:
  # Generate a starter API configuration
  kongctl scaffold api
  # Generate a root-level child resource scaffold
  kongctl scaffold api_version
  # Generate a nested child scaffold
  kongctl scaffold api.versions
  # Generate an analytics dashboard scaffold with a starter tile
  kongctl scaffold analytics.dashboards


Flags:
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                 help for scaffold
      --log-file string      Write execution logs to the specified file instead of STDERR.
                             - Config path: [ log-file ]
      --log-level string     Configures the logging level. Execution logs are written to STDERR.
                             - Config path: [ log-level ]
                             - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --no-telemetry         Disable telemetry for this command invocation. Overrides config and env.
                             - Config path: [ telemetry.enabled ]
                             - Env var    : [ KONGCTL_NO_TELEMETRY ]
                             - Default    : [ false ]
  -p, --profile string       Specify the profile to use for this command. (default "default")

```