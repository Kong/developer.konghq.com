```bash
Usage:
  kongctl api <endpoint> [field=value ...] [flags]
  kongctl api [command]

Examples:
  # Get the current user
  kongctl api /v3/users/me
  
  # Explicit GET
  kongctl api get /v3/users/me
  
  # Create a resource with JSON fields
  kongctl api post /v3/apis name=my-api config:={"enabled":true}
  
  # Update a resource
  kongctl api put /v3/apis/123 name="my-updated-api"
  
  # Partially update a resource
  kongctl api patch /v3/apis/123 config:={"enabled":false}
  
  # Delete a resource
  kongctl api delete /v3/apis/123

Available Commands:
  delete      Send an HTTP DELETE request to a Konnect endpoint
  get         Send an HTTP GET request to a Konnect endpoint
  patch       Send an HTTP PATCH request to a Konnect endpoint
  post        Send an HTTP POST request to a Konnect endpoint
  put         Send an HTTP PUT request to a Konnect endpoint


Flags:
      --base-url string            Base URL for Konnect API requests.
                                   - Config path: [ konnect.base-url ]
                                   - Default   : [ https://us.api.konghq.com ]
  -f, --body-file string           Read request body from file ('-' to read from standard input)
      --color-theme string         Configures the CLI UI/theme (prompt, tables, TUI elements).
                                   - Config path: [ color-theme ]
                                   - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                   - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string         Path to the configuration file to load.
                                   - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                       help for api
      --include-response-headers   Include response headers in error output
      --jq string                  Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string            Controls colorized output for jq filter results.
                                   - Config path: [ jq.color.enabled ]
                                   - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string      Select the color theme used for jq filter results.
                                   - Config path: [ jq.color.theme ]
                                   - Examples   : [ friendly, github-dark, dracula ]
                                   - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output              Output string jq results without JSON quotes (like jq -r).
                                   - Config path: [ jq.raw-output ]
      --log-file string            Write execution logs to the specified file instead of STDERR.
                                   - Config path: [ log-file ]
      --log-level string           Configures the logging level. Execution logs are written to STDERR.
                                   - Config path: [ log-level ]
                                   - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string              Configures the format of data written to STDOUT.
                                   - Config path: [ output ]
                                   - Allowed    : [ json|yaml|text ] (default "text")
      --pat string                 Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                   Setting this value overrides tokens obtained from the login command.
                                   - Config path: [ konnect.pat ]
  -p, --profile string             Specify the profile to use for this command. (default "default")
      --region string              Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                   - Config path: [ konnect.region ]

Use "kongctl api [command] --help" for more information about a command.

```