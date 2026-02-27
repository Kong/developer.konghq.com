```bash
Usage:
  kongctl get gateway service [flags]

Aliases:
  service, services, svc, svcs

Examples:
  # List all the Gateway Services for the a given control plane
  kongctl get konnect gateway service --control-plane-id <id>
  # Get a specific Kong Gateway Services for the a given control plane
  kongctl get konnect gateway service --control-plane-id <id> <service-name>


Flags:
      --base-url string             Base URL for Konnect API requests.
                                    - Config path: [ konnect.base-url ]
                                    - Default   : [ https://us.api.konghq.com ]
      --color-theme string          Configures the CLI UI/theme (prompt, tables, TUI elements).
                                    - Config path: [ color-theme ]
                                    - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                    - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string          Path to the configuration file to load.
                                    - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --control-plane-id string     The ID of the control plane to use for a gateway service command.
                                    - Config path: [ konnect.gateway.control-plane.id ]
      --control-plane-name string   The name of the control plane to use for a gateway service command.
                                    - Config path: [ konnect.gateway.control-plane.name ]
  -h, --help                        help for service
      --jq string                   Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string             Controls colorized output for jq filter results.
                                    - Config path: [ jq.color.enabled ]
                                    - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string       Select the color theme used for jq filter results.
                                    - Config path: [ jq.color.theme ]
                                    - Examples   : [ friendly, github-dark, dracula ]
                                    - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output               Output string jq results without JSON quotes (like jq -r).
                                    - Config path: [ jq.raw-output ]
      --log-file string             Write execution logs to the specified file instead of STDERR.
                                    - Config path: [ log-file ]
      --log-level string            Configures the logging level. Execution logs are written to STDERR.
                                    - Config path: [ log-level ]
                                    - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string               Configures the format of data written to STDOUT.
                                    - Config path: [ output ]
                                    - Allowed    : [ json|yaml|text ] (default "text")
      --page-size int               Max number of results to include per response page for get and list operations.
                                    - Config path: [ konnect.page-size ] (default 10)
      --pat string                  Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                    Setting this value overrides tokens obtained from the login command.
                                    - Config path: [ konnect.pat ]
  -p, --profile string              Specify the profile to use for this command. (default "default")
      --region string               Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                    - Config path: [ konnect.region ]

```