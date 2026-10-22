```ansi
Usage:
  deck ai dump [flags]

Flags:
      --format string                output file format: json or yaml. (default "yaml")
  -h, --help                         help for dump
      --include-policy-definitions   allow deck to dump AI Gateway policy definitions.
                                     Policy definitions work with AI Gateway versions >= 2.2
  -o, --output-file -                file to which to write AI Gateway configuration. Use - to write to stdout. (default "-")
  -w, --workspace string             dump configuration of a specific Workspace (Kong Enterprise only).
      --yes yes                      assume yes to prompts and run non-interactively.

```