```ansi
Usage:
  kongctl get event-gateway backend-clusters [flags]

Aliases:
  backend-clusters, backend-cluster, bc, bcs

Examples:
  # List backend clusters for an event gateway by ID
  kongctl get event-gateway backend-clusters --gateway-id <gateway-id>
  # List backend clusters for an event gateway by name
  kongctl get event-gateway backend-clusters --gateway-name my-gateway
  # Get a specific backend cluster by ID (positional argument)
  kongctl get event-gateway backend-clusters --gateway-id <gateway-id> <cluster-id>
  # Get a specific backend cluster by name (positional argument)
  kongctl get event-gateway backend-clusters --gateway-id <gateway-id> my-cluster
  # Get a specific backend cluster by ID (flag)
  kongctl get event-gateway backend-clusters --gateway-id <gateway-id> --backend-cluster-id <cluster-id>
  # Get a specific backend cluster by name (flag)
  kongctl get event-gateway backend-clusters --gateway-name my-gateway --backend-cluster-name my-cluster


Flags:
      --backend-cluster-id string     The ID of the backend cluster to retrieve.
                                      - Config path: [ konnect.event-gateway.backend-cluster.id ]
      --backend-cluster-name string   The name of the backend cluster to retrieve.
                                      - Config path: [ konnect.event-gateway.backend-cluster.name ]
      --base-url string               Base URL for Konnect API requests.
                                      - Config path: [ konnect.base-url ]
                                      - Default   : [ https://us.api.konghq.com ]
      --color-theme string            Configures the CLI UI/theme (prompt, tables, TUI elements).
                                      - Config path: [ color-theme ]
                                      - Examples   : [ 3024_day, 3024_night, aardvark_blue, abernathy, adventure ]
                                      - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string            Path to the configuration file to load.
                                      - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --gateway-id string             The ID of the event gateway that owns the resource.
                                      - Config path: [ konnect.event-gateway.id ]
      --gateway-name string           The name of the event gateway that owns the resource.
                                      - Config path: [ konnect.event-gateway.name ]
  -h, --help                          help for backend-clusters
      --jq string                     Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string               Controls colorized output for jq filter results.
                                      - Config path: [ jq.color.enabled ]
                                      - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string         Select the color theme used for jq filter results.
                                      - Config path: [ jq.color.theme ]
                                      - Examples   : [ friendly, github-dark, dracula ]
                                      - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output                 Output string jq results without JSON quotes (like jq -r).
                                      - Config path: [ jq.raw-output ]
      --log-file string               Write execution logs to the specified file instead of STDERR.
                                      - Config path: [ log-file ]
      --log-level string              Configures the logging level. Execution logs are written to STDERR.
                                      - Config path: [ log-level ]
                                      - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string                 Configures the format of data written to STDOUT.
                                      - Config path: [ output ]
                                      - Allowed    : [ json|yaml|text ] (default "text")
      --page-size int                 Max number of results to include per response page for get and list operations.
                                      - Config path: [ konnect.page-size ] (default 10)
      --pat string                    Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                      Setting this value overrides tokens obtained from the login command.
                                      - Config path: [ konnect.pat ]
  -p, --profile string                Specify the profile to use for this command. (default "default")
      --region string                 Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                      - Config path: [ konnect.region ]

```