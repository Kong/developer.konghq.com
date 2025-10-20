```bash
Usage:
  deck gateway sync [flags] [kong-state-files...]

Flags:
      --consumer-group-policy-overrides                     allow deck to sync consumer-group policy overrides.
                                                            This allows policy overrides to work with Kong GW versions >= 3.4
                                                            Warning: do not mix with consumer-group scoped plugins
      --db-update-propagation-delay db_update_propagation   artificial delay (in seconds) that is injected between insert operations 
                                                            for related entities (usually for Cassandra deployments).
                                                            See db_update_propagation in kong.conf.
  -h, --help                                                help for sync
      --json-output                                         generate command execution report in a JSON format
      --no-mask-deck-env-vars-value                         do not mask DECK_ environment variable values at diff output.
      --parallelism int                                     Maximum number of concurrent operations. (default 10)
      --rbac-resources-only                                 diff only the RBAC resources (Kong Enterprise only).
      --select-tag strings                                  only entities matching tags specified via this flag are synced.
                                                            When this setting has multiple tag values, entities must match every tag.
                                                            All entities in the state file will get the select-tags assigned if not present already.
      --silence-events                                      disable printing events to stdout
      --skip-ca-certificates                                do not sync CA certificates.
      --skip-consumers                                      do not sync consumers, consumer-groups or any plugins associated with them.
      --skip-consumers-with-consumer-groups                 do not show the association between consumer and consumer-group.
                                                            If set to true, deck skips listing consumers with consumer-groups,
                                                            thus gaining some performance with large configs.
                                                            Usage of this flag without apt select-tags and default-lookup-tags can be problematic.
                                                            This flag is not valid with Konnect.
      --skip-hash-for-basic-auth                            do not sync hash for basic auth credentials.
                                                            This flag is only valid with Konnect.
  -w, --workspace string                                    Sync configuration to a specific workspace (Kong Enterprise only).
                                                            This takes precedence over _workspace fields in state files.
      --yes yes                                             assume yes to prompts and run non-interactively.

```