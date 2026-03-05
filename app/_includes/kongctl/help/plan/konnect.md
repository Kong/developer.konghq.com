```bash
Usage:
  kongctl plan konnect [flags]

Aliases:
  konnect, k, K

Examples:
  # Retrieve the Konnect Kong Gateway control planes from the current organization
  kongctl get konnect gateway control-planes


Flags:
      --base-dir string             Base directory boundary for !file resolution.
                                    Defaults to each -f source root (file: its parent dir, dir: the directory itself). For stdin, defaults to CWD.
                                    - Config path: [ konnect.declarative.base-dir ]
      --base-url string             Base URL for Konnect API requests.
                                    - Config path: [ konnect.base-url ]
                                    - Default   : [ https://us.api.konghq.com ]
      --color-theme string          Configures the CLI UI/theme (prompt, tables, TUI elements).
                                    - Config path: [ color-theme ]
                                    - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                    - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string          Path to the configuration file to load.
                                    - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -f, --filename strings            Filename or directory to files to use to create the resource (can specify multiple)
  -h, --help                        help for konnect
      --log-file string             Write execution logs to the specified file instead of STDERR.
                                    - Config path: [ log-file ]
      --log-level string            Configures the logging level. Execution logs are written to STDERR.
                                    - Config path: [ log-level ]
                                    - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --mode string                 Plan generation mode (sync|apply|delete) (default "sync")
  -o, --output string               Configures the format of data written to STDOUT.
                                    - Config path: [ output ]
                                    - Allowed    : [ json|yaml|text ] (default "text")
      --output-file string          Save plan artifact to file
      --pat string                  Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                    Setting this value overrides tokens obtained from the login command.
                                    - Config path: [ konnect.pat ]
  -p, --profile string              Specify the profile to use for this command. (default "default")
  -R, --recursive                   Process the directory used in -f, --filename recursively
      --region string               Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                    - Config path: [ konnect.region ]
      --require-any-namespace       Require explicit namespace on all resources (via kongctl.namespace or _defaults.kongctl.namespace).
                                    Cannot be used with --require-namespace.
                                    - Config path: [ konnect.declarative.require-any-namespace ]
      --require-namespace strings   Require specific namespaces. Accepts comma-separated list or repeated flags.
                                    Cannot be used with --require-any-namespace.
                                    Examples:
                                      --require-namespace=foo                          # Allow only 'foo' namespace
                                      --require-namespace=foo,bar                      # Allow 'foo' or 'bar' (comma-separated)
                                      --require-namespace=foo --require-namespace=bar  # Allow 'foo' or 'bar' (repeated flags)
                                    - Config path: [ konnect.declarative.require-namespace ]

```