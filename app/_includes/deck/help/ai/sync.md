```ansi
Usage:
  deck ai sync [flags] [ai-gateway-state-files...]

Flags:
  -h, --help                         help for sync
      --include-policy-definitions   allow deck to sync AI Gateway policy definitions.
                                     Policy definitions work with AI Gateway versions >= 2.2
      --json-output                  generate command execution report in a JSON format.
      --parallelism int              Maximum number of concurrent operations. (default 10)
  -w, --workspace string             Sync configuration to a specific workspace (Kong Enterprise only).
                                     This takes precedence over _workspace fields in state files.
      --yes yes                      assume yes to prompts and run non-interactively.

```