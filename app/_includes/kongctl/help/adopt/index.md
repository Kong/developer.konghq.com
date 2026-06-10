```ansi
Usage:
  kongctl adopt [flags]
  kongctl adopt [command]

Examples:
  # Adopt a portal by name into the "team-alpha" namespace
  kongctl adopt portal my-portal --namespace team-alpha
  # Move an already adopted portal to a different namespace
  kongctl adopt --namespace platform --overwrite-namespace portal my-portal
  # Adopt a control plane by ID
  kongctl adopt control-plane 22cd8a0b-72e7-4212-9099-0764f8e9c5ac --namespace platform
  # Adopt a dashboard by ID
  kongctl adopt analytics dashboard 22cd8a0b-72e7-4212-9099-0764f8e9c5ac --namespace analytics
  # Adopt a DCR provider by name
  kongctl adopt dcr-provider my-dcr-provider --namespace team-alpha
  # Adopt an API explicitly via the konnect product
  kongctl adopt konnect api my-api --namespace team-alpha

Available Commands:
  analytics     Adopt Konnect Analytics resources into namespace management
  api           Adopt an existing Konnect API into namespace management
  auth-strategy Adopt an existing Konnect auth strategy into namespace management
  control-plane Adopt an existing Konnect control plane into namespace management
  dcr-provider  Adopt an existing Konnect DCR provider into namespace management
  event-gateway Adopt an existing Konnect Event Gateway Control Plane into namespace management
  konnect       Manage Konnect resources
  organization  Adopt organization resources into namespace management
  portal        Adopt an existing Konnect portal into namespace management


Flags:
      --base-url string       Base URL for Konnect API requests.
                              - Config path: [ konnect.base-url ]
                              - Default   : [ https://us.api.konghq.com ]
      --color-theme string    Configures the CLI UI/theme (prompt, tables, TUI elements).
                              - Config path: [ color-theme ]
                              - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                              - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string    Path to the configuration file to load.
                              - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                  help for adopt
      --log-file string       Write execution logs to the specified file instead of STDERR.
                              - Config path: [ log-file ]
      --log-level string      Configures the logging level. Execution logs are written to STDERR.
                              - Config path: [ log-level ]
                              - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --namespace string      Namespace label to apply to the resource (required)
      --no-telemetry          Disable telemetry for this command invocation. Overrides config and env.
                              - Config path: [ telemetry.enabled ]
                              - Env var    : [ KONGCTL_NO_TELEMETRY ]
                              - Default    : [ false ]
  -o, --output string         Configures the format of data written to STDOUT.
                              - Config path: [ output ]
                              - Allowed    : [ json|yaml|text ] (default "text")
      --overwrite-namespace   Overwrite an existing namespace label on the resource
      --pat string            Konnect Personal Access Token (PAT) used to authenticate the CLI.
                              Setting this value overrides tokens obtained from the login command.
                              - Config path: [ konnect.pat ]
  -p, --profile string        Specify the profile to use for this command. (default "default")
      --region string         Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                              - Config path: [ konnect.region ]

Use "kongctl adopt [command] --help" for more information about a command.

```