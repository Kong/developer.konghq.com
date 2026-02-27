```bash
Usage:
  kongctl get portal [flags]
  kongctl get portal [command]

Aliases:
  portal, portals, p, ps, P, PS

Examples:
  # List all the portals for the organization
  kongctl get portals
  # Get a specific portal
  kongctl get portal <id|name>
  # List portals using aliases
  kongctl get ps

Available Commands:
  application-registrations Manage portal application registrations for a Konnect portal
  applications              Manage portal applications for a Konnect portal
  assets                    Retrieve portal assets (logo, favicon)
  auth-settings             Retrieve portal authentication settings
  developers                Manage portal developers for a Konnect portal
  email-domains             List portal email domains configured for the organization
  pages                     Manage portal pages for a Konnect portal
  snippets                  Manage portal snippets for a Konnect portal
  team-roles                List portal team role assignments for a Konnect portal
  teams                     Manage portal teams for a Konnect portal


Flags:
      --base-url string         Base URL for Konnect API requests.
                                - Config path: [ konnect.base-url ]
                                - Default   : [ https://us.api.konghq.com ]
      --color-theme string      Configures the CLI UI/theme (prompt, tables, TUI elements).
                                - Config path: [ color-theme ]
                                - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string      Path to the configuration file to load.
                                - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                    help for portal
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

Use "kongctl get portal [command] --help" for more information about a command.

```