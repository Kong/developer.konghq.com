```ansi
Usage:
  kongctl get ai-gateway ca-certificates [certificate-id|name] [flags]

Aliases:
  ca-certificates, ca-certificate, ca-cert, ca-certs

Examples:
kongctl get ai-gateway ca-certificates --gateway-id <gateway-id>


Flags:
      --base-url string              Base URL for Konnect API requests.
                                     - Config path: [ konnect.base-url ]
                                     - Default   : [ https://us.api.konghq.com ]
      --ca-certificate-id string     The ID of the AI Gateway CA certificate to retrieve.
                                     - Config path: [ konnect.ai-gateway.ca-certificate.id ]
      --ca-certificate-name string   The name of the AI Gateway CA certificate to retrieve.
                                     - Config path: [ konnect.ai-gateway.ca-certificate.name ]
      --color-theme string           Configures the CLI UI/theme (prompt, tables, TUI elements).
                                     - Config path: [ color-theme ]
                                     - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                     - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --columns stringArray          Select text columns as HEADER=.field (repeatable or comma-separated).
                                     Supports nested fields, quoted keys, array indexes, and string slices.
      --config-file string           Path to the configuration file to load.
                                     - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --gateway-id string            The ID of the AI Gateway that owns the resource.
                                     - Config path: [ konnect.ai-gateway.id ]
      --gateway-name string          The name or display_name of the AI Gateway that owns the resource.
                                     - Config path: [ konnect.ai-gateway.name ]
  -h, --help                         help for ca-certificates
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
      --no-telemetry                 Disable telemetry for this command invocation. Overrides config and env.
                                     - Config path: [ telemetry.enabled ]
                                     - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                     - Default    : [ false ]
  -o, --output string                Configures the format of data written to STDOUT.
                                     - Config path: [ output ]
                                     - Allowed    : [ json|yaml|text ] (default "text")
      --page-size int                Max number of results to include per response page for get and list operations.
                                     - Config path: [ konnect.page-size ] (default 10)
      --pat string                   Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                     Setting this value overrides tokens obtained from the login command.
                                     - Config path: [ konnect.pat ]
  -p, --profile string               Specify the profile to use for this command. (default "default")
      --region string                Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                     - Config path: [ konnect.region ]
      --text-id-format string        Configure UUID rendering in static text-table ID columns.
                                     - Config path: [ text.id-format ]
                                     - Allowed    : [ compact|full ]
                                     - Default    : [ compact ]
      --text-layout string           Configure static text-table column selection.
                                     - Config path: [ text.layout ]
                                     - Allowed    : [ compact|auto|wide ]
                                     - Default    : [ compact ]

```