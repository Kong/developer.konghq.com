```ansi
Usage:
  kongctl dump [flags]
  kongctl dump [command]

Aliases:
  dump, d, D

Examples:
  # Export all portals as Terraform import blocks to stdout
  kongctl dump tf-import --resources=portal
  
  # Export all portals and their child resources (documents, specifications, pages, settings)
  kongctl dump tf-import --resources=portal --include-child-resources
  
  # Export all portals as Terraform import blocks to a file
  kongctl dump tf-import --resources=portal --output-file=portals.tf
  
  # Export all APIs with their child resources and include debug logging
  kongctl dump tf-import --resources=api --include-child-resources --log-level=debug
  
  # Export declarative configuration with a default namespace
  kongctl dump declarative --resources=portal,api --default-namespace=team-alpha
  
  # Export all organization teams
  kongctl dump declarative --resources=organization.teams
  
  # Filter by name (exact match)
  kongctl dump declarative --resources=portal --filter-name=my-dev-portal
  
  # Filter by name (substring match using wildcards)
  kongctl dump declarative --resources=portal --filter-name='*dev*'
  
  # Filter by ID
  kongctl dump declarative --resources=portal --filter-id=abc12345-def6-7890-abcd-ef1234567890

Available Commands:
  declarative Export resources as kongctl declarative configuration
  tf-import   Export resources as Terraform import blocks


Flags:
      --color-theme string   Configures the CLI UI/theme (prompt, tables, TUI elements).
                             - Config path: [ color-theme ]
                             - Examples   : [ 3024_day, 3024_night, aardvark_blue, abernathy, adventure ]
                             - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string   Path to the configuration file to load.
                             - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
  -h, --help                 help for dump
      --log-file string      Write execution logs to the specified file instead of STDERR.
                             - Config path: [ log-file ]
      --log-level string     Configures the logging level. Execution logs are written to STDERR.
                             - Config path: [ log-level ]
                             - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string        Configures the format of data written to STDOUT.
                             - Config path: [ output ]
                             - Allowed    : [ json|yaml|text ] (default "text")
  -p, --profile string       Specify the profile to use for this command. (default "default")

Use "kongctl dump [command] --help" for more information about a command.

```