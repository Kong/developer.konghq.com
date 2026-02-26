```bash
Usage:
  kongctl listen [flags]
  kongctl listen [command]

Aliases:
  listen, lsn

Examples:
  # Konnect-first shorthand
  kongctl listen --public-url https://example.ngrok.app
  # Resource form
  kongctl listen audit-logs --public-url https://example.ngrok.app
  # Explicit product form
  kongctl listen konnect audit-logs --public-url https://example.ngrok.app

Available Commands:
  audit-logs  Create Konnect audit-log destination and listen for events locally
  konnect     Manage Konnect resources


Flags:
      --authorization string    Value for the Authorization header Konnect includes when sending audit logs. The local listener validates this same value when provided.
      --base-url string         Base URL for Konnect API requests.
                                - Config path: [ konnect.base-url ]
                                - Default   : [ https://us.api.konghq.com ]
      --color-theme string      Configures the CLI UI/theme (prompt, tables, TUI elements).
                                - Config path: [ color-theme ]
                                - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string      Path to the configuration file to load.
                                - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --configure-webhook       Automatically bind and enable the organization webhook with the created destination. (default true)
  -d, --detach                  Run listener in background as a detached kongctl process (not compatible with --tail).
      --endpoint string         Explicit destination endpoint URL used for Konnect destination creation.
  -h, --help                    help for listen
      --jq string               Filter streamed JSON records using a jq expression (only used with --tail).
      --listen-address string   HTTP listen address for incoming audit-log webhooks. (default "127.0.0.1:19090")
      --log-file string         Write execution logs to the specified file instead of STDERR.
                                - Config path: [ log-file ]
      --log-format string       Audit-log payload format. Allowed: cef|json|cps. (default "json")
      --log-level string        Configures the logging level. Execution logs are written to STDERR.
                                - Config path: [ log-level ]
                                - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --max-body-bytes int      Maximum accepted request body size in bytes. (default 1048576)
      --name string             Destination name. Default: kongctl-<hostname>-<pid>.
  -o, --output string           Configures the format of data written to STDOUT.
                                - Config path: [ output ]
                                - Allowed    : [ json|yaml|text ] (default "text")
      --pat string              Konnect Personal Access Token (PAT) used to authenticate the CLI.
                                Setting this value overrides tokens obtained from the login command.
                                - Config path: [ konnect.pat ]
      --path string             HTTP path that accepts webhook requests. (default "/audit-logs")
  -p, --profile string          Specify the profile to use for this command. (default "default")
      --public-url string       Externally reachable base URL for this listener; used to build destination endpoint when --endpoint is omitted.
      --region string           Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                - Config path: [ konnect.region ]
      --skip-ssl-verification   Skip TLS certificate verification for destination delivery.
      --tail                    Stream received audit-log records to stdout.

Use "kongctl listen [command] --help" for more information about a command.

```