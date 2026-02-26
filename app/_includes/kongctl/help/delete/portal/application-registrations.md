```bash
Usage:
  kongctl delete portal application-registrations <registration-id> [flags]

Aliases:
  application-registrations, registration, registrations, application-registration, application-registrations

Examples:
  # Delete a registration by ID
  kongctl delete portal application registration --portal-id <portal-id> <registration-id>
  # Delete a registration by ID with portal name
  kongctl delete portal application registration --portal-name my-portal <registration-id>


Flags:
      --application-id string     Scope to a specific application by ID (optional for list, required for get/delete if registration lookup fails)
      --application-name string   Scope to a specific application by name
      --auto-approve              Skip confirmation prompts for delete operations
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
      --force                     Force deletion even when related resources exist (not configurable)
  -h, --help                      help for application-registrations
      --log-file string           Write execution logs to the specified file instead of STDERR.
                                  - Config path: [ log-file ]
      --log-level string          Configures the logging level. Execution logs are written to STDERR.
                                  - Config path: [ log-level ]
                                  - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string             Configures the format of data written to STDOUT.
                                  - Config path: [ output ]
                                  - Allowed    : [ json|yaml|text ] (default "text")
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