```ansi
Usage:
  kongctl get [flags]
  kongctl get [command]

Aliases:
  get, g, G

Examples:
  # Retrieve Konnect portals
  kongctl get portals
  # Retrieve Konnect APIs
  kongctl get apis
  # Retrieve Konnect Analytics dashboards
  kongctl get analytics dashboards
  # Retrieve Konnect auth strategies
  kongctl get auth-strategies
  # Retrieve Konnect DCR providers
  kongctl get dcr-providers
  # Retrieve Konnect control planes (Konnect-first)
  kongctl get gateway control-planes
  # Retrieve Konnect control planes (explicit)
  kongctl get konnect gateway control-planes
  # Retrieve Konnect audit-log destinations
  kongctl get audit-logs destinations

Available Commands:
  analytics     Manage Konnect Analytics resources
  api           List or get Konnect APIs
  audit-logs    Get Konnect audit-log destinations and webhook state
  auth-strategy List or get Konnect authentication strategies
  catalog       Manage Konnect catalog resources
  dcr-provider  List or get Konnect DCR providers
  event-gateway List or get Konnect Event Gateways
  extension     Get a kongctl CLI extension
  gateway       Manage Konnect Kong Gateway resources
  konnect       Manage Konnect resources
  me            Get current user information
  organization  Get current organization information
  pat           List or get Konnect personal access tokens
  portal        List or get Konnect portals
  profile       Manage kongctl profiles
  regions       List available Konnect regions
  spat          List or get Konnect system account access tokens


Flags:
      --base-url string         Base URL for Konnect API requests.
                                - Config path: [ konnect.base-url ]
                                - Default   : [ https://us.api.konghq.com ]
      --color-theme string      Configures the CLI UI/theme (prompt, tables, TUI elements).
                                - Config path: [ color-theme ]
                                - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string      Path to the configuration file to load.
                                - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                    help for get
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

Use "kongctl get [command] --help" for more information about a command.

```