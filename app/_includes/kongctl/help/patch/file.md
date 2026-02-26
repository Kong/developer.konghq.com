```bash
Usage:
  kongctl patch file <input-file> [patch-files...] [flags]

Examples:
  # Set timeouts on all services
  kongctl patch file kong.yaml -s '$..services[*]' -v 'read_timeout:30000'
  
  # Set multiple values
  kongctl patch file kong.yaml -s '$..services[*]' -v 'read_timeout:30000' -v 'write_timeout:30000'
  
  # Remove a key from the root object
  kongctl patch file config.yaml -s '$' -v 'debug:'
  
  # Append to an array
  kongctl patch file kong.yaml -s '$..routes[*].methods' -v '["OPTIONS"]'
  
  # Apply a patch file
  kongctl patch file kong.yaml patches.yaml
  
  # Apply multiple patch files in order
  kongctl patch file kong.yaml base.yaml env.yaml team.yaml
  
  # Read from stdin, write to a file
  cat kong.yaml | kongctl patch file - -s '$' -v 'version:"2.0"' --output-file output.yaml
  
  # Output as JSON
  kongctl patch file kong.yaml patches.yaml --format json --output-file output.json


Flags:
      --color-theme string     Configures the CLI UI/theme (prompt, tables, TUI elements).
                               - Config path: [ color-theme ]
                               - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                               - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string     Path to the configuration file to load.
                               - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --format string          Output format: yaml or json (default "yaml")
  -h, --help                   help for file
      --log-file string        Write execution logs to the specified file instead of STDERR.
                               - Config path: [ log-file ]
      --log-level string       Configures the logging level. Execution logs are written to STDERR.
                               - Config path: [ log-level ]
                               - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string          Configures the format of data written to STDOUT.
                               - Config path: [ output ]
                               - Allowed    : [ json|yaml|text ] (default "text")
      --output-file string     Output file path (default: stdout) (default "-")
  -p, --profile string         Specify the profile to use for this command. (default "default")
  -s, --selector stringArray   JSONPath expression to select target nodes (repeatable)
  -v, --value stringArray      Value to set: "key:json-value", "key:" (remove), or "[values]" (append). Repeatable.

```