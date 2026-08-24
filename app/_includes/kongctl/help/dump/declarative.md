```ansi
Usage:
  kongctl dump declarative [flags]


Flags:
      --base-url string            Base URL for Konnect API requests.
                                   - Config path: [ konnect.base-url ]
                                   - Default   : [ https://us.api.konghq.com ]
      --color-theme string         Configures the CLI UI/theme (prompt, tables, TUI elements).
                                   - Config path: [ color-theme ]
                                   - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                   - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string         Path to the configuration file to load.
                                   - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --default-namespace string   Default namespace to include in declarative output (_defaults.kongctl.namespace).
      --filter-id string           Filter resources by ID (exact match).
                                   Mutually exclusive with --filter-name.
      --filter-name string         Filter resources by name. Use '*' wildcards for substring matching (e.g., '*portal*').
                                   Mutually exclusive with --filter-id.
  -h, --help                       help for declarative
      --include-child-resources    Include child resources in the dump.
      --log-file string            Write execution logs to the specified file instead of STDERR.
                                   - Config path: [ log-file ]
      --log-level string           Configures the logging level. Execution logs are written to STDERR.
                                   - Config path: [ log-level ]
                                   - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --no-telemetry               Disable telemetry for this command invocation. Overrides config and env.
                                   - Config path: [ telemetry.enabled ]
                                   - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                   - Default    : [ false ]
      --output-file string         File to write the output to. If not specified, output is written to stdout.
      --page-size int              Max number of results to include per response page.
                                   - Config path: [ konnect.page-size ] (default 10)
      --pat string                 Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                   Setting this value overrides tokens obtained from the login command.
                                   - Config path: [ konnect.pat ]
  -p, --profile string             Specify the profile to use for this command. (default "default")
      --region string              Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                   - Config path: [ konnect.region ]
      --resources string           Comma separated list of resource types to dump (ai_gateways, analytics.dashboards, apis, application_auth_strategies, control_planes, dcr_providers, event_gateways, organization.teams, portals).
      --skip-defaults              Omit fields whose values match defaults declared by the Konnect API.
      --text-id-format string      Configure UUID rendering in static text-table ID columns.
                                   - Config path: [ text.id-format ]
                                   - Allowed    : [ compact|full ]
                                   - Default    : [ compact ]
      --text-layout string         Configure static text-table column selection.
                                   - Config path: [ text.layout ]
                                   - Allowed    : [ compact|auto|wide ]
                                   - Default    : [ compact ]

```