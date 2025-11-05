```bash
Usage:
  deck gateway dump [flags]

Flags:
      --all-workspaces                        dump configuration of all Workspaces (Kong Enterprise only).
      --consumer-group-policy-overrides       allow deck to dump consumer-group policy overrides.
                                              This allows policy overrides to work with Kong GW versions >= 3.4
                                              Warning: do not mix with consumer-group scoped plugins
      --format string                         output file format: json or yaml. (default "yaml")
  -h, --help                                  help for dump
  -o, --output-file -                         file to which to write Kong's configuration.Use - to write to stdout. (default "-")
      --rbac-resources-only                   export only the RBAC resources (Kong Enterprise only).
      --sanitize                              dumps a sanitized version of the gateway configuration.
                                              This feature hashes passwords, keys and other sensitive details.
      --select-tag strings                    only entities matching tags specified with this flag are exported.
                                              When this setting has multiple tag values, entities must match every tag.
      --skip-ca-certificates                  do not dump CA certificates.
      --skip-consumers                        skip exporting consumers, consumer-groups and any plugins associated with them.
      --skip-consumers-with-consumer-groups   do not show the association between consumer and consumer-group.
                                              If set to true, deck skips listing consumers with consumer-groups,
                                              thus gaining some performance with large configs. This flag is not valid with Konnect.
      --skip-defaults                         skip exporting default values.
      --with-id                               write ID of all entities in the output
  -w, --workspace string                      dump configuration of a specific Workspace(Kong Enterprise only).
      --yes yes                               assume yes to prompts and run non-interactively.

```