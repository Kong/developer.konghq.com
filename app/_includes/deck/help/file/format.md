```ansi
Usage:
  deck file format [flags] deck|dbless filename

Examples:
# Convert a DBless file to decK format
deck file format deck dbless.yaml

# Convert a decK file to DBless format
deck file format dbless deck.yaml

Flags:
      --format string        Output file format: yaml or json. (default "yaml")
  -h, --help                 help for format
  -o, --output-file string   Output file to write to. Use - to write to stdout. (default "-")

```