```ansi
Usage:
  kongctl adopt ai-gateway vaults [name|id] [flags]

Aliases:
  vaults, vault

Examples:
  kongctl adopt ai-gateway vaults existing-child --gateway-name shared-gateway --namespace team-a
  kongctl adopt ai-gateway vaults --all --gateway-name shared-gateway --namespace team-a
  kongctl adopt ai-gateway vaults --name-pattern 'team-*' --gateway-name shared-gateway --namespace team-a
  kongctl adopt ai-gateway vaults --name-pattern 'legacy-*' --gateway-name shared-gateway --namespace team-a --parent-ref shared-gateway --declarative-output adopted.yaml


Flags:
      --all                         Adopt all children in this family within the selected parent
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
      --declarative-output string   Write selected adopted resources as declarative YAML to a new file
      --dry-run                     Validate adoption and show ownership metadata changes without writing resources
      --gateway-id string           Parent AI Gateway UUID
      --gateway-name string         Exact parent AI Gateway name or display name
  -h, --help                        help for vaults
      --log-file string             Write execution logs to the specified file instead of STDERR.
                                    - Config path: [ log-file ]
      --log-level string            Configures the logging level. Execution logs are written to STDERR.
                                    - Config path: [ log-level ]
                                    - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --name-pattern string         Adopt children with names matching a quoted glob (*, ?, [abc])
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
      --parent-ref string           Existing parent ref for exported !ref links; requires --declarative-output
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
      --vault-id string             Exact child UUID
      --vault-name string           Exact child name (including UUID-shaped names)

```