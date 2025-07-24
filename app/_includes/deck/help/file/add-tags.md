```bash
Usage:
  deck file add-tags [flags] tag [...tag]

Examples:
# adds tags 'tag1' and 'tag2' to all services in file 'kong.yml'
cat kong.yml | deck file add-tags --selector='services[*]' tag1 tag2

Flags:
      --format string          Output format: json or yaml (default "yaml")
  -h, --help                   help for add-tags
  -o, --output-file string     Output file to write to. Use - to write to stdout. (default "-")
      --selector stringArray   JSON path expression to select objects to add tags to.
                               Defaults to all Kong entities. Repeat for multiple selectors.
  -s, --state string           decK file to process. Use - to read from stdin. (default "-")

```