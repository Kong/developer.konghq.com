```bash
Usage:
  deck file namespace [flags]

Examples:
# Apply namespace to a deckfile, path and host:
deck file namespace --path-prefix=/kong --host=konghq.com --state=deckfile.yaml

# Apply namespace to a deckfile, and write to a new file
# Example file 'kong.yaml':
routes:
- paths:
  - ~/tracks/system$
  strip_path: true
- paths:
  - ~/list$
  strip_path: false

# Apply namespace to the deckfile, and write to stdout:
cat kong.yaml | deck file namespace --path-prefix=/kong

# Output:
routes:
- paths:
  - ~/kong/tracks/system$
  strip_path: true
  hosts:
  - konghq.com
- paths:
  - ~/kong/list$
  strip_path: false
  hosts:
  - konghq.com
  plugins:
  - name: pre-function
    config:
      access:
      - "local ns='/kong' -- this strips the '/kong' namespace from the path\nlocal <more code here>"



Flags:
      --allow-empty-selectors   Do not error out if the selectors return empty
  -c, --clear-hosts             Clear existing hosts.
      --format string           Output format: yaml or json. (default "yaml")
  -h, --help                    help for namespace
      --host stringArray        Hostname to add for host-based namespacing. Repeat for multiple hosts.
  -o, --output-file string      Output file to write. Use - to write to stdout. (default "-")
  -p, --path-prefix string      The path based namespace to apply.
      --selector stringArray    json-pointer identifying element to patch. Repeat for multiple selectors. Defaults to selecting all routes.
  -s, --state string            decK file to process. Use - to read from stdin. (default "-")

```