```bash
Usage:
  kongctl delete [command]

Aliases:
  delete, d, D, del, rm, DEL, RM

Examples:
  # Delete a Konnect Kong Gateway control plane (Konnect-first)
  kongctl delete gateway control-plane <id>
  # Delete a Konnect Kong Gateway control plane (explicit)
  kongctl delete konnect gateway control-plane <id>
  # Delete a Konnect portal by ID (Konnect-first)
  kongctl delete portal 12345678-1234-1234-1234-123456789012
  # Delete a Konnect portal by name
  kongctl delete portal my-portal

Available Commands:
  gateway     Manage Konnect Kong Gateway resources
  konnect     Manage Konnect resources
  portal      Delete a Konnect portal

Flags:
      --approve           Skip confirmation prompts for delete operations (not configurable)
      --base-url string   Base URL for Konnect API requests.
                          - Config path: [ konnect.base-url ]
                          - Default   : [ https://us.api.konghq.com ]
      --force             Force deletion even when related resources exist (not configurable)
  -h, --help              help for delete
      --pat string        Konnect Personal Access Token (PAT) used to authenticate the CLI.
                          Setting this value overrides tokens obtained from the login command.
                          - Config path: [ konnect.pat ]
      --region string     Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                          - Config path: [ konnect.region ]

```