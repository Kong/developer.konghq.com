```bash
Usage:
  deck file kong2tf [flags]

Flags:
  -g, --generate-imports-for-control-plane-id deck gateway dump --with-id   Generate terraform import statements for the control plane ID.Typically used after deck gateway dump --with-id to obtain the IDs of all entities.
  -h, --help                                                                help for kong2tf
      --ignore-credential-changes                                           Enable flag to add a 'lifecycle' block to each consumer credential, that ignores any changes from local to remote state.
  -o, --output-file string                                                  Output file to write. Use - to write to stdout. (default "-")
  -s, --state string                                                        decK file to process. Use - to read from stdin. (default "-")

```