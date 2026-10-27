```ansi
Usage:
  kongctl get mesh [flags]
  kongctl get mesh [command]

Examples:
  # List the resource types a control plane serves
  kongctl get mesh resource-types --control-plane-id <id>

  # List dataplanes without specifying the product
  kongctl get mesh dataplanes --control-plane-id <id>

Available Commands:
  control-planes List the Kong Mesh control planes available to you
  resource-types List the resource types a Kong Mesh control plane serves


Flags:
      --all-meshes                   List mesh scoped resources across every mesh instead of one. Ignored for global types.
                                     - Config path: [ konnect.mesh.all-meshes ]
      --base-url string              Base URL for Konnect API requests.
                                     - Config path: [ konnect.base-url ]
                                     - Default   : [ https://us.api.konghq.com ]
      --ca-cert-file string          Path to a CA certificate that verifies a self managed control plane.
                                     - Config path: [ konnect.mesh.control-plane.ca-cert-file ]
      --client-cert-file string      Path to a client certificate presented to a self managed control plane.
                                     - Config path: [ konnect.mesh.control-plane.client-cert-file ]
      --client-key-file string       Path to the key for --client-cert-file.
                                     - Config path: [ konnect.mesh.control-plane.client-key-file ]
      --color-theme string           Configures the CLI UI/theme (prompt, tables, TUI elements).
                                     - Config path: [ color-theme ]
                                     - Examples   : [ auto, 3024_day, 3024_night, aardvark_blue, abernathy ]
                                     - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "auto")
      --columns stringArray          Select text columns as HEADER=.field (repeatable or comma-separated).
                                     Supports nested fields, quoted keys, array indexes, and string slices.
      --config-file string           Path to the configuration file to load.
                                     - Environment variable: KONGCTL_CONFIG_FILE (overridden by this flag)
                                     - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --control-plane-id string      ID of the Konnect Kong Mesh control plane to use.
                                     - Config path: [ konnect.mesh.control-plane.id ]
      --control-plane-name string    Name of the Konnect Kong Mesh control plane to use.
                                     - Config path: [ konnect.mesh.control-plane.name ]
      --control-plane-token string   Bearer token for a self managed control plane. Not used for a Konnect hosted one.
                                     - Config path: [ konnect.mesh.control-plane.token ]
      --control-plane-url string     API URL of a self managed Kong Mesh control plane. Provide only one control plane selector flag.
                                     - Config path: [ konnect.mesh.control-plane.url ]
  -h, --help                         help for mesh
      --jq string                    Filter JSON responses using jq expressions (powered by gojq for full jq compatibility)
      --jq-color string              Controls colorized output for jq filter results.
                                     - Config path: [ jq.color.enabled ]
                                     - Allowed    : [ auto|always|never ] (default "auto")
      --jq-color-theme string        Select the color theme used for jq filter results.
                                     - Config path: [ jq.color.theme ]
                                     - Examples   : [ friendly, github-dark, dracula ]
                                     - Reference  : [ https://xyproto.github.io/splash/docs/ ] (default "friendly")
  -r, --jq-raw-output                Output string jq results without JSON quotes (like jq -r).
                                     - Config path: [ jq.raw-output ]
      --log-file string              Write execution logs to the specified file instead of STDERR.
                                     - Config path: [ log-file ]
      --log-level string             Configures the logging level. Execution logs are written to STDERR.
                                     - Config path: [ log-level ]
                                     - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -m, --mesh string                  Mesh that mesh scoped resources belong to.
                                     - Config path: [ konnect.mesh.mesh ] (default "default")
      --no-telemetry                 Disable telemetry for this command invocation. Overrides config and env.
                                     - Config path: [ telemetry.enabled ]
                                     - Env var    : [ KONGCTL_NO_TELEMETRY ]
                                     - Default    : [ false ]
      --no-trunc                     Preserve full cell widths in static text tables beyond terminal width.
                                     Does not change column selection, UUID formatting, or explicit string slices.
                                     - Config path: [ text.no-trunc ]
                                     - Default    : [ false ]
  -o, --output string                Configures the format of data written to STDOUT.
                                     - Config path: [ output ]
                                     - Allowed    : [ json|yaml|text ] (default "text")
      --page-size int                Max number of results to include per response page for get and list operations.
                                     - Config path: [ konnect.page-size ] (default 10)
      --pat string                   Konnect Personal Access Token.
                                     - Config path: [ konnect.pat ]
  -p, --profile string               Specify the profile to use for this command. (default "default")
      --region string                Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                                     - Config path: [ konnect.region ]
      --text-id-format string        Configure UUID rendering in static text-table ID columns.
                                     - Config path: [ text.id-format ]
                                     - Allowed    : [ compact|full ]
                                     - Default    : [ compact ]
      --text-layout string           Configure static text-table column selection.
                                     - Config path: [ text.layout ]
                                     - Allowed    : [ compact|auto|wide ]
                                     - Default    : [ compact ]
      --tls-skip-verify              Do not verify a self managed control plane's certificate. Prefer --ca-cert-file.
                                     - Config path: [ konnect.mesh.control-plane.tls-skip-verify ]

Use "kongctl get mesh [command] --help" for more information about a command.

```