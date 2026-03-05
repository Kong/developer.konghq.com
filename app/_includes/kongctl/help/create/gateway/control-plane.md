```bash
Usage:
  kongctl create gateway control-plane [new-cp-name] [flags]

Aliases:
  control-plane, control-planes, controlplane, controlplanes, cp, cps, CP, CPS

Examples:
  # Create a new control plane with default options and the name 'my-control-plane'
  kongctl create konnect gateway control-plane my-control-plane
  # Create a new control plane with the name 'my-control-plane' and specifying all the available options
  kongctl create konnect gateway control-plane my-control-plane --description "full description" --cluster-type hybrid


Flags:
      --auth-type string      Specifies the authentication type used to secure the control plane and data plane communication.
                              - Config path: [ konnect.gateway.control-plane.auth-type ]
                              - Allowed    : [ pinned|pki ] (default "pinned")
      --base-url string       Base URL for Konnect API requests.
                              - Config path: [ konnect.base-url ]
                              - Default   : [ https://us.api.konghq.com ]
      --cluster-type string   Specifies the Kong Gateway cluster type attached to the new control plane.
                              - Config path: [ konnect.gateway.control-plane.cluster-type ]
                              - Allowed    : [ hybrid|kic|group|serverless ] (default "hybrid")
      --color-theme string    Configures the CLI UI/theme (prompt, tables, TUI elements).
                              - Config path: [ color-theme ]
                              - Examples   : [ 3024_day, 3024_night, adventure, adventure_time, afterglow ]
                              - Reference  : [ https://github.com/lrstanley/bubbletint/blob/master/DEFAULT_TINTS.md ] (default "kong-light")
      --config-file string    Path to the configuration file to load.
                              - Default: [ $XDG_CONFIG_HOME/kongctl/config.yaml ]
      --description string    Extended description for the new control plane.
                              - Config path: [ konnect.gateway.control-plane.description ]
  -h, --help                  help for control-plane
      --is-cloud-gateway      Specifies whether the control plane attaches to cloud gateways.
                              - Config path: [ konnect.gateway.control-plane.is-cloud-gateway ]
      --labels strings        Assign metadata labels to the new control plane.
                              Labels are specified as [ key=value ] pairs and can be provided in a list.
                              - Config path: [ konnect.gateway.control-plane.labels ]
      --log-file string       Write execution logs to the specified file instead of STDERR.
                              - Config path: [ log-file ]
      --log-level string      Configures the logging level. Execution logs are written to STDERR.
                              - Config path: [ log-level ]
                              - Allowed    : [ trace|debug|info|warn|error ] (default "error")
  -o, --output string         Configures the format of data written to STDOUT.
                              - Config path: [ output ]
                              - Allowed    : [ json|yaml|text ] (default "text")
      --pat string            Konnect Personal Access Token (PAT) used to authenticate the CLI. 
                              Setting this value overrides tokens obtained from the login command.
                              - Config path: [ konnect.pat ]
  -p, --profile string        Specify the profile to use for this command. (default "default")
      --proxy-urls strings    Specifies URLs for which the data planes connected to this control plane can be reached.
                              Provide multiple URLs as a comma-separated list. URLs must be in the format: <protocol>://<host>:<port>
                              - Config path: [ konnect.gateway.control-plane.proxy-urls ]
      --region string         Konnect region identifier (for example "eu"). Used to construct the base URL when --base-url is not provided.
                              - Config path: [ konnect.region ]

```