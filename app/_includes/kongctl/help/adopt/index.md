```bash
Usage:
  kongctl adopt [command]

Examples:
  # Adopt a portal by name into the "team-alpha" namespace
  kongctl adopt portal my-portal --namespace team-alpha
  # Adopt a control plane by ID
  kongctl adopt control-plane 22cd8a0b-72e7-4212-9099-0764f8e9c5ac --namespace platform
  # Adopt an API explicitly via the konnect product
  kongctl adopt konnect api my-api --namespace team-alpha

Available Commands:
  api           Adopt an existing Konnect API into namespace management
  auth-strategy Adopt an existing Konnect auth strategy into namespace management
  control-plane Adopt an existing Konnect control plane into namespace management
  konnect       Manage Konnect resources
  organization  Adopt organization resources into namespace management
  portal        Adopt an existing Konnect portal into namespace management


Flags:
      --base-url string      Base URL for Konnect API requests.
                             - Config path: [ konnect.base-url ]
                             - Default   : [ https://us.api.konghq.com ]
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                 help for adopt
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

Use "kongctl adopt [command] --help" for more information about a command.

```