```ansi
Usage:
  kongctl sync konnect [flags]

Aliases:
  konnect, k, K

Examples:
  # Synchronize Konnect resources from declarative configuration
  kongctl sync -f api.yaml
  
  # Synchronize using the explicit Konnect target form
  kongctl sync konnect -f api.yaml
  
  # Execute a reviewed plan without prompting
  kongctl sync --plan plan.json --auto-approve


Flags:
      --auto-approve                      Skip confirmation prompt
      --base-dir string                   Base directory boundary for !file resolution.
                                          Defaults to each -f source root (file: its parent dir, dir: the directory itself). For stdin, defaults to CWD.
                                          - Config path: [ konnect.declarative.base-dir ]
      --base-url string                   Base URL for Konnect API requests.
                                          - Config path: [ konnect.base-url ]
                                          - Default   : [ https://us.api.konghq.com ]
      --color-theme string                Configures the CLI UI/theme (prompt, tables, TUI elements).
                                          - Config path: [ color-theme ]
                                          - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                          - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string                Path to the configuration file to load.
                                          - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --dry-run                           Preview changes without applying them
      --execution-report-file string      Save execution report as JSON to file
  -f, --filename strings                  Filename or directory to files to use to create the resource (can specify multiple)
  -h, --help                              help for konnect
      --http-retry-backoff-factor float   Exponential backoff growth factor for retries (for example: 2.0).
                                          - Config path: [ konnect.http-retry-backoff-factor ]
      --http-retry-initial-interval int   Initial retry backoff interval in milliseconds (0 = use default).
                                          - Config path: [ konnect.http-retry-initial-interval ]
      --http-retry-max-attempts int       Maximum total attempts for retryable HTTP requests (0 = use default, 1 disables retries).
                                          - Config path: [ konnect.http-retry-max-attempts ]
      --http-retry-max-interval int       Maximum retry backoff interval in milliseconds (0 = use default).
                                          - Config path: [ konnect.http-retry-max-interval ]
      --http-retry-on-connection-errors   Retry selected retryable connection-level errors.
                                          - Config path: [ konnect.http-retry-on-connection-errors ]
      --log-file string                   Write execution logs to the specified file instead of STDERR.
                                          - Config path: [ log-file ]
      --log-level string                  Configures the logging level. Execution logs are written to STDERR.
                                          - Config path: [ log-level ]
                                          - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --max-concurrency int               Maximum number of concurrent API operations during execution (min 1, max 200).
                                          When the plan contains execution_groups, operations within each group run
                                          concurrently up to this limit. Use 1 for sequential execution.
                                          - Config path: [ konnect.declarative.max-concurrency ] (default 5)
      --no-telemetry                      Disable telemetry for this command invocation. Overrides config and env.
                                          - Config path: [ telemetry.enabled ]
                                          - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                          - Default    : [ false ]
  -o, --output string                     Configures the format of data written to STDOUT.
                                          - Config path: [ output ]
                                          - Allowed    : [ json|yaml|text ] (default "text")
      --pat string                        Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                          Setting this value overrides tokens obtained from the login command.
                                          - Config path: [ konnect.pat ]
      --plan string                       Path to existing plan file
  -p, --profile string                    Specify the profile to use for this command. (default "default")
  -R, --recursive                         Process the directory used in -f, --filename recursively
      --region string                     Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                          - Config path: [ konnect.region ]
      --require-any-namespace             Require explicit namespace on all resources (via kongctl.namespace or _defaults.kongctl.namespace).
                                          Cannot be used with --require-namespace.
                                          - Config path: [ konnect.declarative.require-any-namespace ]
      --require-namespace strings         Require specific namespaces. Accepts comma-separated list or repeated flags.
                                          Cannot be used with --require-any-namespace.
                                          Examples:
                                            --require-namespace=foo                          # Allow only 'foo' namespace
                                            --require-namespace=foo,bar                      # Allow 'foo' or 'bar' (comma-separated)
                                            --require-namespace=foo --require-namespace=bar  # Allow 'foo' or 'bar' (repeated flags)
                                          - Config path: [ konnect.declarative.require-namespace ]

```