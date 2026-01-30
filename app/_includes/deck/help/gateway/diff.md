```bash
Usage:
  deck gateway diff [flags] [kong-state-files...]

Flags:
      --consumer-group-policy-overrides       allow deck to diff consumer-group policy overrides.
                                              This allows policy overrides to work with Kong GW versions >= 3.4
                                              Warning: do not mix with consumer-group scoped plugins
  -h, --help                                  help for diff
      --json-output                           generate command execution report in a JSON format
      --no-mask-deck-env-vars-value           do not mask DECK_ environment variable values at diff output.
      --non-zero-exit-code                    return exit code 2 if there is a diff present,
                                              exit code 0 if no diff is found,
                                              and exit code 1 if an error occurs.
      --parallelism int                       Maximum number of concurrent operations. (default 10)
      --rbac-resources-only                   sync only the RBAC resources (Kong Enterprise only).
      --select-tag strings                    only entities matching tags specified via this flag are diffed.
                                              When this setting has multiple tag values, entities must match each of them.
      --silence-events                        disable printing events to stdout
      --skip-ca-certificates                  do not diff CA certificates.
      --skip-consumers                        do not diff consumers or any plugins associated with consumers
      --skip-consumers-with-consumer-groups   do not show the association between consumer and consumer-group.
                                              If set to true, deck skips listing consumers with consumer-groups,
                                              thus gaining some performance with large configs.
                                              Usage of this flag without apt select-tags and default-lookup-tags can be problematic.
                                              This flag is not valid with Konnect.
  -w, --workspace string                      Diff configuration with a specific workspace (Kong Enterprise only).
                                              This takes precedence over _workspace fields in state files.
      --yes yes                               assume yes to prompts and run non-interactively.

```