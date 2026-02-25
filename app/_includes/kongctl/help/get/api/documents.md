```bash
Usage:
  kongctl get api documents [flags]

Aliases:
  documents, document, docs, doc

Examples:
  # List documents for an API by ID
  kongctl get api documents --api-id <api-id>
  # List documents for an API by name
  kongctl get api documents --api-name my-api
  # Get a specific document by ID
  kongctl get api documents --api-id <api-id> <document-id>
  # Get a specific document by slug
  kongctl get api documents --api-id <api-id> getting-started


Flags:
      --api-id string           The ID of the API that owns the resource.
                                - Config path: [ konnect.api.id ]
      --api-name string         The name of the API that owns the resource.
                                - Config path: [ konnect.api.name ]
      --base-url string         Base URL for Konnect API requests.
                                - Config path: [ konnect.base-url ]
                                - Default   : [ https://us.api.konghq.com ]
      --color-theme string      Configures the CLI UI/theme (prompt, tables, TUI elements).
                                - Config path: [ color-theme ]
                                - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string      Path to the configuration file to load.
                                - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                    help for documents
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

```