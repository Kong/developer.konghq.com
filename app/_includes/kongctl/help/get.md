```bash
Usage:
  kongctl get [flags]
  kongctl get [command]

Aliases:
  get, g, G

Examples:
  # Retrieve Konnect portals
  kongctl get portals
  # Retrieve Konnect APIs
  kongctl get apis
  # Retrieve Konnect auth strategies
  kongctl get auth-strategies
  # Retrieve Konnect control planes (Konnect-first)
  kongctl get gateway control-planes
  # Retrieve Konnect control planes (explicit)
  kongctl get konnect gateway control-planes
  # Retrieve Konnect Event Gateways
  kongctl get event-gateways

Available Commands:
  api           List or get Konnect APIs
  auth-strategy List or get Konnect authentication strategies
  catalog       Manage Konnect catalog resources
  event-gateway List or get Konnect Event Gateways
  gateway       Manage Konnect Kong Gateway resources
  konnect       Manage Konnect resources
  me            Get current user information
  organization  Get current organization information
  portal        List or get Konnect portals
  profile       Manage CLI profiles
  regions       List available Konnect regions

Flags:
      --base-url string   Base URL for Konnect API requests.
                          - Config path: [ konnect.base-url ]
                          - Default   : [ https://us.api.konghq.com ]
  -h, --help              help for get
      --page-size int     Max number of results to include per response page for get and list operations.
                          - Config path: [ konnect.page-size ] (default 10)
      --pat string        Konnect Personal Access Token (PAT) used to authenticate the CLI.
                          Setting this value overrides tokens obtained from the login command.
                          - Config path: [ konnect.pat ]
      --region string     Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                          - Config path: [ konnect.region ]

```