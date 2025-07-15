```bash
Usage:
  deck file validate [flags] [kong-state-files...]

Flags:
  -h, --help                           help for validate
      --konnect-compatibility          validate that the state file(s) are ready to be deployed to Konnect
      --online-entities-list strings   indicate the list of entities that should be validated online validation.
      --parallelism int                Maximum number of concurrent requests to Kong. (default 10)
      --rbac-resources-only            indicate that the state file(s) contains RBAC resources only (Kong Enterprise only).
  -w, --workspace string               validate configuration of a specific workspace (Kong Enterprise only).
                                       This takes precedence over _workspace fields in state files.

```