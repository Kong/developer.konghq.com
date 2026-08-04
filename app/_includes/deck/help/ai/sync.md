```ansi
Usage:
  deck ai sync [flags] [ai-gateway-state-files...]

Flags:
  -h, --help               help for sync
      --json-output        generate command execution report in a JSON format.
      --parallelism int    Maximum number of concurrent operations. (default 10)
  -w, --workspace string   Sync configuration to a specific workspace (Kong Enterprise only).
                           This takes precedence over _workspace fields in state files.
      --yes yes            assume yes to prompts and run non-interactively.

```