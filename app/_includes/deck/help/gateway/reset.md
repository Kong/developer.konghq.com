```bash
Usage:
  deck gateway reset [flags]

Flags:
      --all-workspaces                reset configuration of all workspaces (Kong Enterprise only).
  -f, --force                         Skip interactive confirmation prompt before reset.
  -h, --help                          help for reset
      --json-output                   generate command execution report in a JSON format
      --no-mask-deck-env-vars-value   do not mask DECK_ environment variable values at diff output.
      --rbac-resources-only           reset only the RBAC resources (Kong Enterprise only).
      --select-tag strings            only entities matching tags specified via this flag are deleted.
                                      When this setting has multiple tag values, entities must match every tag.
      --skip-ca-certificates          do not reset CA certificates.
      --skip-consumers                do not reset consumers, consumer-groups or any plugins associated with consumers.
  -w, --workspace string              reset configuration of a specific workspace(Kong Enterprise only).

```