```bash
Usage:
  kongctl kai [flags]

Flags:
  -a, --ask               Send a single prompt to the agent and print the response
      --base-url string   Base URL for Konnect API requests.
                          - Config path: [ konnect.base-url ]
                          - Default   : [ https://us.api.konghq.com ]
      --color string      Controls colorized terminal output.
                          - Config path: [ color ]
                          - Allowed    : [ auto|always|never ] (default "auto")
  -h, --help              help for kai
      --pat string        Konnect Personal Access Token (PAT) used to authenticate the CLI.
                          Setting this value overrides tokens obtained from the login command.
                          - Config path: [ konnect.pat ]
      --region string     Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                          - Config path: [ konnect.region ]

```