```bash
Usage:
  kongctl lint [flags]

Aliases:
  lint, li

Examples:
  # Lint a single file
  kongctl lint -f config.yaml -r ruleset.yaml
  
  # Lint all YAML files in a directory
  kongctl lint -f ./configs/ -r ruleset.yaml
  
  # Lint recursively with JSON output
  kongctl lint -f ./configs/ -R -r ruleset.yaml --output json
  
  # Only show errors (not warnings/info/hints)
  kongctl lint -f config.yaml -r ruleset.yaml --fail-severity error -D
  
  # Fail on warnings and above
  kongctl lint -f config.yaml -r ruleset.yaml --fail-severity warn
  
  # Read from stdin
  cat config.yaml | kongctl lint -f - -r ruleset.yaml


Flags:
      --color-theme string      Configures the CLI UI/theme (prompt, tables, TUI elements).
                                - Config path: [ color-theme ]
                                - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                                - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string      Path to the configuration file to load.
                                - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -D, --display-only-failures   Only output results with severity equal to or greater than --fail-severity
  -F, --fail-severity string    Results of this severity or above will trigger a failure exit code. Allowed: [ error | warn | info | hint ] (default "error")
  -f, --filename strings        Input file(s) or directory to lint. Use '-' to read from stdin.
  -h, --help                    help for lint
      --log-file string         Write execution logs to the specified file instead of STDERR.
                                - Config path: [ log-file ]
      --log-level string        Configures the logging level. Execution logs are written to STDERR.
                                - Config path: [ log-level ]
                                - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string           Configures the format of data written to STDOUT.
                                - Config path: [ output ]
                                - Allowed    : [ json|yaml|text ] (default "text")
  -p, --profile string          Specify the profile to use for this command. (default "default")
  -R, --recursive               Process the directory used in -f, --filename recursively
  -r, --ruleset string          Path to a Spectral-compatible linting ruleset file (YAML or JSON)

```