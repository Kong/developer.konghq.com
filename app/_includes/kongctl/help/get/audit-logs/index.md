```ansi
Usage:
  kongctl get audit-logs [flags]
  kongctl get audit-logs [command]

Aliases:
  audit-logs, audit-log

Examples:
  # Retrieve the 50 most recent events
  kongctl get audit-logs

  # Retrieve and automatically paginate every event from the last 24 hours
  kongctl get audit-logs --since 24h --output jsonl

  # List audit-log destinations
  kongctl get audit-logs destinations

  # Get one destination by id or name
  kongctl get audit-logs destination <id|name>

  # Get regional webhook configuration
  kongctl get audit-logs webhook

Available Commands:
  destination  Get one Konnect audit-log destination
  destinations List Konnect audit-log destinations
  webhook      Get Konnect regional audit-log webhook configuration


Flags:
      --base-url string          Base URL for Konnect API requests.
                                 - Config path: [ konnect.base-url ]
                                 - Default   : [ https://us.api.konghq.com ]
      --color-theme string       Configures the CLI UI/theme (prompt, tables, TUI elements).
                                 - Config path: [ color-theme ]
                                 - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                 - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --columns stringArray      Select text columns as HEADER=.field (repeatable or comma-separated).
                                 Supports nested fields, quoted keys, array indexes, and string slices.
      --config-file string       Path to the configuration file to load.
                                 - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --end-time string          Inclusive RFC3339 upper bound for event timestamps.
                                 Accepts UTC (Z) or a numeric UTC offset.
                                 - UTC example   : [ 2026-08-24T14:00:00Z ]
                                 - Offset example: [ 2026-08-24T09:00:00-05:00 ]
  -F, --follow                   Poll continuously for new events until interrupted.
  -h, --help                     help for audit-logs
      --jq string                Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string          Controls colorized output for jq filter results.
                                 - Config path: [ jq.color.enabled ]
                                 - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string    Select the color theme used for jq filter results.
                                 - Config path: [ jq.color.theme ]
                                 - Examples   : [ friendly, github-dark, dracula ]
                                 - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output            Output string jq results without JSON quotes (like jq -r).
                                 - Config path: [ jq.raw-output ]
      --limit int                Maximum total events to return.
                                 Defaults to 50 when no time window is specified.
                                 Time-window queries are unlimited unless --limit is specified.
                                 Set to 0 for unlimited.
      --log-file string          Write execution logs to the specified file instead of STDERR.
                                 - Config path: [ log-file ]
      --log-level string         Configures the logging level. Execution logs are written to STDERR.
                                 - Config path: [ log-level ]
                                 - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --no-telemetry             Disable telemetry for this command invocation. Overrides config and env.
                                 - Config path: [ telemetry.enabled ]
                                 - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                 - Default    : [ false ]
  -o, --output string            Configures the format of data written to STDOUT.
                                 - Config path: [ output ]
                                 - Allowed    : [ json|yaml|text|jsonl ] (default "text")
      --page-size int            Maximum audit-log records requested per API page (1..1000).
                                 - Config path: [ konnect.page-size ] (default 100)
      --pat string               Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                 Setting this value overrides tokens obtained from the login command.
                                 - Config path: [ konnect.pat ]
      --poll-interval duration   Interval between successful polling cycles in follow mode. (default 10s)
  -p, --profile string           Specify the profile to use for this command. (default "default")
      --region string            Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                 - Config path: [ konnect.region ]
      --since duration           Retrieve events from the specified lookback period.
                                 - Examples: [ 30s, 15m, 2h, 24h, 168h, 1h30m ]
      --start-time string        Inclusive RFC3339 lower bound for event timestamps.
                                 Accepts UTC (Z) or a numeric UTC offset.
                                 - UTC example   : [ 2026-08-23T14:00:00Z ]
                                 - Offset example: [ 2026-08-23T09:00:00-05:00 ]
      --text-id-format string    Configure UUID rendering in static text-table ID columns.
                                 - Config path: [ text.id-format ]
                                 - Allowed    : [ compact|full ]
                                 - Default    : [ compact ]
      --text-layout string       Configure static text-table column selection.
                                 - Config path: [ text.layout ]
                                 - Allowed    : [ compact|auto|wide ]
                                 - Default    : [ compact ]
      --type string              Filter by event type: authentication, authorization, or gateway_access.

Use "kongctl get audit-logs [command] --help" for more information about a command.

```