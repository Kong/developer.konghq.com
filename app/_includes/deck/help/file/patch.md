```bash
Usage:
  deck file patch [flags] [...patch-files]

Examples:
# update the read-timeout on all services
cat kong.yml | deck file patch --selector="$..services[*]" --value="read_timeout:10000"

Flags:
      --format string          Output format: yaml or json. (default "yaml")
  -h, --help                   help for patch
  -o, --output-file string     Output file to write. Use - to write to stdout. (default "-")
      --selector stringArray   json-pointer identifying element to patch. Repeat for multiple selectors.)
  -s, --state string           decK file to process. Use - to read from stdin. (default "-")
      --value stringArray      A value to set in the selected entry in <key:value> format. Can be specified multiple times.

```