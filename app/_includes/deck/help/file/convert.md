```bash
Usage:
  deck file convert [flags]

Flags:
      --format string   output file format: json or yaml. (default "yaml")
      --from string     format of the source file, allowed formats: [kong-gateway kong-gateway-2.x 2.8 3.4]
  -h, --help            help for convert
      --input-file -    configuration file to be converted. Use - to read from stdin. (default "-")
  -o, --output-file -   file to write configuration to after conversion. Use - to write to stdout. (default "-")
      --to string       desired format of the output, allowed formats: [konnect kong-gateway-3.x 3.4 3.10]
      --yes yes         assume yes to prompts and run non-interactively.

```