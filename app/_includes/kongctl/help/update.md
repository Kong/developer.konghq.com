```bash
Usage:
  kongctl [command]

Available Commands:
  adopt       Adopt existing Konnect resources into namespace management
  api         Call the Konnect API directly
  apply       Apply configuration changes (create/update only)
  completion  Generate the autocompletion script for the specified shell
  delete      Delete objects
  diff        Show configuration differences
  dump        Dump objects
  get         Retrieve objects
  help        Display extended help for a command
  list        Retrieve object lists
  login       Login to Kong Konnect
  logout      Logout from Kong Konnect
  plan        Preview changes to Kong Konnect resources
  sync        Full state synchronization (create/update/delete)
  version     Print the kongctl version
  view        Launch the Konnect resource viewer

Flags:
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                 help for kongctl
      --log-file string      Write execution logs to the specified file instead of STDERR.
                             - Config path: [ log-file ]
      --log-level string     Configures the logging level. Execution logs are written to STDERR.
                             - Config path: [ log-level ]
                             - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string        Configures the format of data written to STDOUT.
                             - Config path: [ output ]
                             - Allowed    : [ json|yaml|text ] (default "text")
  -p, --profile string       Specify the profile to use for this command. (default "default")

Use "kongctl [command] --help" for more information about a command.

```