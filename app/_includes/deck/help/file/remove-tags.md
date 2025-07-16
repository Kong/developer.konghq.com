```bash
Usage:
  deck file remove-tags [flags] tag [...tag]

Examples:
# clear tags 'tag1' and 'tag2' from all services in file 'kong.yml'
cat kong.yml | deck file remove-tags --selector='services[*]' tag1 tag2

# clear all tags except 'tag1' and 'tag2' from the file 'kong.yml'
cat kong.yml | deck file remove-tags --keep-only tag1 tag2

Flags:
      --format string          Output format: json or yaml (default "yaml")
  -h, --help                   help for remove-tags
      --keep-empty-array       Keep empty tag arrays in output.
      --keep-only              Setting this flag will remove all tags except the ones listed.
                               If none are listed, all tags will be removed.
  -o, --output-file string     Output file to write. Use - to write to stdout. (default "-")
      --selector stringArray   JSON path expression to select objects to remove tags from.
                               Defaults to all Kong entities. Repeat for multiple selectors.
  -s, --state string           decK file to process. Use - to read from stdin. (default "-")

```