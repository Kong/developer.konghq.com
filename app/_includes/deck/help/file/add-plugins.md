```bash
Usage:
  deck file add-plugins [flags] [...plugin-files]

Examples:
# adds a plugin to all services in a deck file, except if it is already present
cat kong.yml | deck file add-plugins --selector='services[*]' \
               --config='{"name":"my-plugin","config":{"my-property":"value"}}'

# same, but now overwriting plugins if they already exist and reading from files
cat kong.yml | deck file add-plugins --overwrite plugin1.json plugin2.yml

Flags:
      --config stringArray     JSON snippet containing the plugin configuration to add. Repeat to add
                               multiple plugins.
      --format string          Output format: json or yaml (default "yaml")
  -h, --help                   help for add-plugins
  -o, --output-file string     Output file to write to. Use - to write to stdout. (default "-")
      --overwrite              Specify this flag to overwrite plugins by the same name if they already
                               exist in an array. The default behavior is to skip existing plugins.
      --selector stringArray   JSON path expression to select plugin-owning objects to add plugins to.
                               Defaults to the top-level (selector '$'). Repeat for multiple selectors.
  -s, --state string           decK file to process. Use - to read from stdin. (default "-")

```