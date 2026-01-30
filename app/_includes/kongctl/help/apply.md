```bash
Usage:
  kongctl apply [flags]
  kongctl apply [command]

Aliases:
  apply, a, A

Examples:
  kongctl apply -f api.yaml
  kongctl apply -f ./configs/ --recursive
  kongctl apply --plan plan.json
  
  Use "kongctl help apply" for detailed documentation

Available Commands:
  konnect     Apply configuration changes (create/update only)

Flags:
      --auto-approve                   Skip confirmation prompt
      --base-dir string                Base directory boundary for !file resolution.
                                       Defaults to each -f source root (file: its parent dir, dir: the directory itself). For stdin, defaults to CWD.
                                       - Config path: [ konnect.declarative.base-dir ]
      --base-url string                Base URL for Konnect API requests.
                                       - Config path: [ konnect.base-url ]
                                       - Default   : [ https://us.api.konghq.com ]
      --dry-run                        Preview changes without applying
      --execution-report-file string   Save execution report as JSON to file
  -f, --filename strings               Filename or directory to files to use to create the resource (can specify multiple)
  -h, --help                           help for apply
  -o, --output string                  Output format (text|json|yaml) (default "text")
      --pat string                     Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                                       Setting this value overrides tokens obtained from the login command.
                                       - Config path: [ konnect.pat ]
      --plan string                    Path to existing plan file
  -R, --recursive                      Process the directory used in -f, --filename recursively
      --region string                  Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                       - Config path: [ konnect.region ]
      --require-any-namespace          Require explicit namespace on all resources (via kongctl.namespace or _defaults.kongctl.namespace).
                                       Cannot be used with --require-namespace.
                                       - Config path: [ konnect.declarative.require-any-namespace ]
      --require-namespace strings      Require specific namespaces. Accepts comma-separated list or repeated flags.
                                       Cannot be used with --require-any-namespace.
                                       Examples:
                                         --require-namespace=foo                          # Allow only 'foo' namespace
                                         --require-namespace=foo,bar                      # Allow 'foo' or 'bar' (comma-separated)
                                         --require-namespace=foo --require-namespace=bar  # Allow 'foo' or 'bar' (repeated flags)
                                       - Config path: [ konnect.declarative.require-namespace ]

```