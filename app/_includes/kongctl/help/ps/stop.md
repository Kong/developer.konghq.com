```bash
Usage:
  kongctl ps stop <pid> [flags]


Flags:
      --all                  Stop all tracked detached processes.
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                 help for stop
      --log-file string      Write execution logs to the specified file instead of STDERR.
                             - Config path: [ log-file ]
      --log-level string     Configures the logging level. Execution logs are written to STDERR.
                             - Config path: [ log-level ]
                             - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string        Configures the format of data written to STDOUT.
                             - Config path: [ output ]
                             - Allowed    : [ json|yaml|text ] (default "text")
  -p, --profile string       Specify the profile to use for this command. (default "default")
      --timeout duration     How long to wait for graceful process shutdown. (default 15s)

```