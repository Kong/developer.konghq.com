```ansi
Usage:
  kongctl install extension <source> [flags]


Flags:
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                 help for extension
      --log-file string      Write execution logs to the specified file instead of STDERR.
                             - Config path: [ log-file ]
      --log-level string     Configures the logging level. Execution logs are written to STDERR.
                             - Config path: [ log-level ]
                             - Allowed    : [ trace|debug|info|warn|error ] (default "error")
      --no-telemetry         Disable telemetry for this command invocation. Overrides config and env.
                             - Config path: [ telemetry.enabled ]
                             - Env var    : [ KONGCTL_NO_TELEMETRY ]
                             - Default    : [ false ]
  -o, --output string        Configures the format of data written to STDOUT.
                             - Config path: [ output ]
                             - Allowed    : [ json|yaml|text ] (default "text")
  -p, --profile string       Specify the profile to use for this command. (default "default")
      --ref string           GitHub release tag, branch, or source ref to install.
      --yes                  Accept the remote extension trust prompt.

```