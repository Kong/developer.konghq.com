```ansi
Usage:
  deck gateway apply [flags] [kong-state-files...]

Flags:
      --db-update-propagation-delay db_update_propagation   artificial delay (in seconds) that is injected between insert operations 
                                                            for related entities (usually for Cassandra deployments).
                                                            See db_update_propagation in kong.conf.
  -W, --errors-as-warnings string                           Treat the given comma-separated diagnostic codes as warnings.
  -h, --help                                                help for apply
      --json-output                                         generate command execution report in a JSON format
      --parallelism int                                     Maximum number of concurrent operations. (default 10)
      --silence-events                                      disable printing events to stdout
      --skip-hash-for-basic-auth                            do not sync hash for basic auth credentials.
                                                            This flag is only valid with Konnect.
  -E, --warnings-as-errors string                           Treat the given comma-separated diagnostic codes as errors.
  -w, --workspace string                                    Apply configuration to a specific workspace (Kong Enterprise only).
                                                            This takes precedence over _workspace fields in state files.

```