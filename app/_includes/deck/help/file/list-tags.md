```bash
Usage:
  deck file list-tags [flags]

Examples:
# list all tags used on services
cat kong.yml | deck file list-tags --selector='services[*]'

Flags:
      --format string          Output format: json, yaml, or PLAIN (default "PLAIN")
  -h, --help                   help for list-tags
  -o, --output-file string     Output file to write to. Use - to write to stdout. (default "-")
      --selector stringArray   JSON path expression to select objects to scan for tags.
                               Defaults to all Kong entities. Repeat for multiple selectors.
  -s, --state string           decK file to process. Use - to read from stdin. (default "-")

```