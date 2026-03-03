```bash
Usage:
  kongctl dump declarative [flags]


Flags:
      --base-url string            Base URL for Konnect API requests.
                                   - Config path: [ konnect.base-url ]
                                   - Default   : [ https://us.api.konghq.com ]
      --color-theme string         Configures the CLI UI/theme (prompt, tables, TUI elements).
                                   - Config path: [ color-theme ]
                                   - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                   - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string         Path to the configuration file to load.
                                   - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --default-namespace string   Default namespace to include in declarative output (_defaults.kongctl.namespace).
  -h, --help                       help for declarative
      --include-child-resources    Include child resources in the dump.
      --log-file string            Write execution logs to the specified file instead of STDERR.
                                   - Config path: [ log-file ]
      --log-level string           Configures the logging level. Execution logs are written to STDERR.
                                   - Config path: [ log-level ]
                                   - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string              Configures the format of data written to STDOUT.
                                   - Config path: [ output ]
                                   - Allowed    : [ json|yaml|text ] (default "text")
      --output-file string         File to write the output to. If not specified, output is written to stdout.
      --page-size int              Max number of results to include per response page.
                                   - Config path: [ konnect.page-size ] (default 10)
      --pat string                 Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                   Setting this value overrides tokens obtained from the login command.
                                   - Config path: [ konnect.pat ]
  -p, --profile string             Specify the profile to use for this command. (default "default")
      --region string              Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                   - Config path: [ konnect.region ]
      --resources string           Comma separated list of resource types to dump (portals, apis, application_auth_strategies, control_planes, event_gateways, organization.teams).

```