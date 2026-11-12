```ansi
Usage:
  kongctl adopt konnect ai-gateway <ai-gateway-id|ai-gateway-display-name> [flags]
  kongctl adopt konnect ai-gateway [command]

Aliases:
  ai-gateway, ai-gateways, aigw

Available Commands:
  agents          Adopt existing AI Gateway agents into a namespace
  auth-strategies Adopt existing AI Gateway auth-strategies into a namespace
  ca-certificates Adopt existing AI Gateway ca-certificates into a namespace
  consumer-groups Adopt existing AI Gateway consumer-groups into a namespace
  consumers       Adopt existing AI Gateway consumers into a namespace
  custom-policies Adopt existing AI Gateway custom-policies into a namespace
  mcp-servers     Adopt existing AI Gateway mcp-servers into a namespace
  model-providers Adopt existing AI Gateway model-providers into a namespace
  models          Adopt existing AI Gateway models into a namespace
  policies        Adopt existing AI Gateway policies into a namespace
  snis            Adopt existing AI Gateway snis into a namespace
  vaults          Adopt existing AI Gateway vaults into a namespace


Flags:
      --base-url string             Base URL for Konnect API requests.
                                    - Config path: [ konnect.base-url ]
                                    - Default   : [ https://us.api.konghq.com ]
      --color-theme string          Configures the CLI UI/theme (prompt, tables, TUI elements).
                                    - Config path: [ color-theme ]
                                    - Examples   : [ auto, 0_x_96_f, 12_bit_rainbow, 13_th_floor, 3024_day ]
                                    - List       : [ kongctl list themes ] (default "auto")
      --config-file string          Path to the configuration file to load.
                                    - Environment variable: KONGCTL_CONFIG_FILE (overridden by this flag)
                                    - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --declarative-output string   Write the adopted resource as declarative YAML to a new file
      --dry-run                     Validate adoption and show ownership metadata changes without writing resources
  -h, --help                        help for ai-gateway
      --log-file string             Write execution logs to the specified file instead of STDERR.
                                    - Config path: [ log-file ]
      --log-level string            Configures the logging level. Execution logs are written to STDERR.
                                    - Config path: [ log-level ]
                                    - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --namespace string            Namespace ownership metadata to apply to the resource (required)
      --no-telemetry                Disable telemetry for this command invocation. Overrides config and env.
                                    - Config path: [ telemetry.enabled ]
                                    - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                    - Default    : [ false ]
      --no-trunc                    Preserve full cell widths in static text tables beyond terminal width.
                                    Does not change column selection, UUID formatting, or explicit string slices.
                                    - Config path: [ text.no-trunc ]
                                    - Default    : [ false ]
  -o, --output string               Configures the format of data written to STDOUT.
                                    - Config path: [ output ]
                                    - Allowed    : [ json|yaml|text ] (default "text")
      --overwrite-namespace         Overwrite existing namespace ownership metadata on the resource
      --pat string                  Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                    Setting this value overrides tokens obtained from the login command.
                                    - Config path: [ konnect.pat ]
  -p, --profile string              Specify the profile to use for this command. (default "default")
      --region string               Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                    - Config path: [ konnect.region ]
      --text-id-format string       Configure UUID rendering in static text-table ID columns.
                                    - Config path: [ text.id-format ]
                                    - Allowed    : [ compact|full ]
                                    - Default    : [ compact ]
      --text-layout string          Configure static text-table column selection.
                                    - Config path: [ text.layout ]
                                    - Allowed    : [ compact|auto|wide ]
                                    - Default    : [ compact ]

Use "kongctl adopt konnect ai-gateway [command] --help" for more information about a command.

```