```bash
Usage:
  kongctl delete konnect portal [flags]
  kongctl delete konnect portal [command]

Aliases:
  portal, portals, p, ps, P, PS

Examples:
  # Delete a portal by ID
  kongctl delete portal 12345678-1234-1234-1234-123456789012
  
  # Delete a portal by name
  kongctl delete portal my-portal
  
  # Force delete a portal with published APIs
  kongctl delete portal my-portal --force
  
  # Delete without confirmation prompt
  kongctl delete portal my-portal --auto-approve

Available Commands:
  application-registrations Delete portal application registrations for a Konnect portal
  applications              Delete portal applications for a Konnect portal


Flags:
      --auto-approve         Skip confirmation prompts for delete operations
      --base-url string      Base URL for Konnect API requests.
                             - Config path: [ konnect.base-url ]
                             - Default   : [ https://us.api.konghq.com ]
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --force                Force deletion even when related resources exist (not configurable)
  -h, --help                 help for portal
      --log-file string      Write execution logs to the specified file instead of STDERR.
                             - Config path: [ log-file ]
      --log-level string     Configures the logging level. Execution logs are written to STDERR.
                             - Config path: [ log-level ]
                             - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string        Configures the format of data written to STDOUT.
                             - Config path: [ output ]
                             - Allowed    : [ json|yaml|text ] (default "text")
      --pat string           Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                             Setting this value overrides tokens obtained from the login command.
                             - Config path: [ konnect.pat ]
  -p, --profile string       Specify the profile to use for this command. (default "default")
      --region string        Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                             - Config path: [ konnect.region ]

Use "kongctl delete konnect portal [command] --help" for more information about a command.

```