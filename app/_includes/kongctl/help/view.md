```bash
Usage:
  kongctl view [flags]

Aliases:
  view, v, V

Examples:
  # Launch the Konnect interactive viewer
  kongctl view

Flags:
      --base-url string   Base URL for Konnect API requests.
                          - Config path: [ konnect.base-url ]
                          - Default   : [ https://us.api.konghq.com ]
  -h, --help              help for view
      --page-size int     Max number of results to include per response page.
                          - Config path: [ konnect.page-size ] (default 10)
      --pat string        Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                          Setting this value overrides tokens obtained from the login command.
                          - Config path: [ konnect.pat ]
      --region string     Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                          - Config path: [ konnect.region ]

```