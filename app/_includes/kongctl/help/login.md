```bash
Usage:
  kongctl login [flags]
  kongctl login [command]

Examples:
  # Login to Kong Konnect (default)
  kongctl login
  
  # Login to Kong Konnect (explicit)
  kongctl login konnect

Available Commands:
  konnect     Login to Konnect

Flags:
      --auth-path string       URL path used to initiate Konnect Authorization.
                               - Config path: [ konnect.auth-path ]
                               - (default "/v3/internal/oauth/device/authorize")
      --base-auth-url string   Base URL used for Konnect Authorization requests.
                               - Config path: [ konnect.base-auth-url ]
                               - (default "https://global.api.konghq.com")
  -h, --help                   help for login
      --refresh-path string    URL path used to refresh the Konnect auth token.
                               - Config path: [ konnect.refresh-path ]
                               - (default "/kauth/api/v1/refresh")
      --token-path string      URL path used to poll for the Konnect Authorization response token.
                               - Config path: [ konnect.token-path ]
                               - (default "/v3/internal/oauth/device/token")

```