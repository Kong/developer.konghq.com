```ansi
Usage:
  kongctl list konnect ai-gateway [flags]
  kongctl list konnect ai-gateway [command]

Aliases:
  ai-gateway, ai-gateways, aigw, AIGW

Examples:
  # List all AI Gateways for the organization
  kongctl get ai-gateway
  # Get details for an AI Gateway with a specific ID
  kongctl get ai-gateway 22cd8a0b-72e7-4212-9099-0764f8e9c5ac
  # Get details for an AI Gateway with a specific display name
  kongctl get ai-gateway "Customer Support Gateway"
  # Get all AI Gateways using command aliases
  kongctl get aigw

Available Commands:
  agents                  List or get Agents for a Konnect AI Gateway
  auth-strategies         List or get auth strategies for a Konnect AI Gateway
  ca-certificates         List or get CA certificates for a Konnect AI Gateway
  certificates            List or get runtime TLS certificates for a Konnect AI Gateway
  config-stores           List or get Config Stores for a Konnect AI Gateway
  consumer-groups         List or get Consumer Groups for a Konnect AI Gateway
  consumers               List or get Consumers for a Konnect AI Gateway
  credentials             List or get Consumer Credentials for a Konnect AI Gateway Consumer
  data-plane-certificates List or get data plane certificates for a Konnect AI Gateway
  mcp-servers             List or get MCP Servers for a Konnect AI Gateway
  model-providers         List or get model providers for a Konnect AI Gateway
  models                  List or get models for a Konnect AI Gateway
  nodes                   List or get data plane Nodes for a Konnect AI Gateway
  policies                List or get Policies for a Konnect AI Gateway
  snis                    List or get SNIs for a Konnect AI Gateway
  vaults                  List or get Vaults for a Konnect AI Gateway


Flags:
      --base-url string         Base URL for Konnect API requests.
                                - Config path: [ konnect.base-url ]
                                - Default   : [ https://us.api.konghq.com ]
      --color-theme string      Configures the CLI UI/theme (prompt, tables, TUI elements).
                                - Config path: [ color-theme ]
                                - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --columns stringArray     Select text columns as HEADER=.field (repeatable or comma-separated).
                                Supports nested fields, quoted keys, array indexes, and string slices.
      --config-file string      Path to the configuration file to load.
                                - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                    help for ai-gateway
      --jq string               Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string         Controls colorized output for jq filter results.
                                - Config path: [ jq.color.enabled ]
                                - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string   Select the color theme used for jq filter results.
                                - Config path: [ jq.color.theme ]
                                - Examples   : [ friendly, github-dark, dracula ]
                                - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output           Output string jq results without JSON quotes (like jq -r).
                                - Config path: [ jq.raw-output ]
      --log-file string         Write execution logs to the specified file instead of STDERR.
                                - Config path: [ log-file ]
      --log-level string        Configures the logging level. Execution logs are written to STDERR.
                                - Config path: [ log-level ]
                                - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --no-telemetry            Disable telemetry for this command invocation. Overrides config and env.
                                - Config path: [ telemetry.enabled ]
                                - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                - Default    : [ false ]
  -o, --output string           Configures the format of data written to STDOUT.
                                - Config path: [ output ]
                                - Allowed    : [ json|yaml|text ] (default "text")
      --page-size int           Max number of results to include per response page for get and list operations.
                                - Config path: [ konnect.page-size ] (default 10)
      --pat string              Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                Setting this value overrides tokens obtained from the login command.
                                - Config path: [ konnect.pat ]
  -p, --profile string          Specify the profile to use for this command. (default "default")
      --region string           Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                - Config path: [ konnect.region ]
      --text-id-format string   Configure UUID rendering in static text-table ID columns.
                                - Config path: [ text.id-format ]
                                - Allowed    : [ compact|full ]
                                - Default    : [ compact ]
      --text-layout string      Configure static text-table column selection.
                                - Config path: [ text.layout ]
                                - Allowed    : [ compact|auto|wide ]
                                - Default    : [ compact ]

Use "kongctl list konnect ai-gateway [command] --help" for more information about a command.

```