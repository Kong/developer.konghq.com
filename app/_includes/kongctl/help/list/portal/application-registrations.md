```bash
Usage:
  kongctl list portal application-registrations [flags]

Aliases:
  application-registrations, registration, registrations, application-registration, application-registrations

Examples:
  # List registrations for a portal by ID
  kongctl get portal application registrations --portal-id <portal-id>
  # List registrations for a portal by name
  kongctl get portal application registrations --portal-name my-portal
  # List registrations for an application by name
  kongctl get portal application registrations --portal-name my-portal --application-name checkout-app
  # Get a specific registration by ID
  kongctl get portal application registrations --portal-name my-portal <registration-id>


Flags:
      --application-id string     Scope to a specific application by ID (optional for list, required for get/delete if registration lookup fails)
      --application-name string   Scope to a specific application by name
      --base-url string           Base URL for Konnect API requests.
                                  - Config path: [ konnect.base-url ]
                                  - Default   : [ https://us.api.konghq.com ]
      --color-theme string        Configures the CLI UI/theme (prompt, tables, TUI elements).
                                  - Config path: [ color-theme ]
                                  - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                  - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string        Path to the configuration file to load.
                                  - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --developer-id string       Filter registrations by developer ID
  -h, --help                      help for application-registrations
      --jq string                 Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string           Controls colorized output for jq filter results.
                                  - Config path: [ jq.color.enabled ]
                                  - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string     Select the color theme used for jq filter results.
                                  - Config path: [ jq.color.theme ]
                                  - Examples   : [ friendly, github-dark, dracula ]
                                  - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output             Output string jq results without JSON quotes (like jq -r).
                                  - Config path: [ jq.raw-output ]
      --log-file string           Write execution logs to the specified file instead of STDERR.
                                  - Config path: [ log-file ]
      --log-level string          Configures the logging level. Execution logs are written to STDERR.
                                  - Config path: [ log-level ]
                                  - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string             Configures the format of data written to STDOUT.
                                  - Config path: [ output ]
                                  - Allowed    : [ json|yaml|text ] (default "text")
      --page-size int             Max number of results to include per response page for get and list operations.
                                  - Config path: [ konnect.page-size ] (default 10)
      --pat string                Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                  Setting this value overrides tokens obtained from the login command.
                                  - Config path: [ konnect.pat ]
      --portal-id string          The ID of the portal that owns the resource.
                                  - Config path: [ konnect.portal.id ]
      --portal-name string        The name of the portal that owns the resource.
                                  - Config path: [ konnect.portal.name ]
  -p, --profile string            Specify the profile to use for this command. (default "default")
      --region string             Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                  - Config path: [ konnect.region ]
      --status string             Filter registrations by status (approved, pending, revoked, rejected)

```