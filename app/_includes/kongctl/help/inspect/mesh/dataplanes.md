```ansi
Usage:
  kongctl inspect mesh dataplanes [flags]


Flags:
      --all-meshes                   List mesh scoped resources across every mesh instead of one. Ignored for global types.
                                     - Config path: [ konnect.mesh.all-meshes ]
      --base-url string              Base URL for Konnect API requests.
                                     - Config path: [ konnect.base-url ]
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
  -h, --help                         help for dataplanes
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
      --pat string                   Konnect Personal Access Token (PAT).
                                     - Config path: [ konnect.pat ]
  -p, --profile string               Specify the profile to use for this command. (default "default")
      --region string                Konnect region identifier (for example eu).
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

```