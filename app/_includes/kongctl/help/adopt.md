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
  # Adopt an Event Gateway explicitly via the konnect product
  kongctl adopt konnect event-gateway my-egw --namespace team-alpha

Available Commands:
  api           Adopt an existing Konnect API into namespace management
  auth-strategy Adopt an existing Konnect auth strategy into namespace management
  control-plane Adopt an existing Konnect control plane into namespace management
  event-gateway Adopt an existing Konnect Event Gateway Control Plane into namespace management
  konnect       Manage Konnect resources
  portal        Adopt an existing Konnect portal into namespace management

Flags:
      --base-url string   Base URL for Konnect API requests.
                          - Config path: [ konnect.base-url ]
                          - Default   : [ https://us.api.konghq.com ]
  -h, --help              help for adopt
      --pat string        Konnect Personal Access Token (PAT) used to authenticate the CLI.
                          Setting this value overrides tokens obtained from the login command.
                          - Config path: [ konnect.pat ]
      --region string     Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                          - Config path: [ konnect.region ]

```