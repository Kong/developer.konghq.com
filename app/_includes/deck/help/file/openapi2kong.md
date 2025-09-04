```bash
Usage:
  deck file openapi2kong [flags]

Examples:
# Convert an OAS file, adding 2 tags, with inso compatibility enabled
cat service_oas.yml | deck file openapi2kong --inso-compatible --select-tag=serviceA,teamB

Flags:
      --format string            output format: yaml or json (default "yaml")
      --generate-security        generate OpenIDConnect plugins from the security directives
  -h, --help                     help for openapi2kong
      --ignore-circular-refs     ignore circular $ref errors in the OpenAPI spec (dangerous, use with caution)
      --ignore-security-errors   ignore errors for unsupported security schemes
  -i, --inso-compatible          This flag will enable Inso compatibility. The generated entity names will be
                                 the same, and no 'id' fields will be generated.
      --no-id                    Setting this flag will skip UUID generation for entities (no 'id' fields
                                 will be added, implicit if '--inso-compatible' is set).
  -o, --output-file string       Output file to write. Use - to write to stdout. (default "-")
      --select-tag strings       Select tags to apply to all entities. If omitted, uses the "x-kong-tags"
                                 directive from the file.
  -s, --spec string              OpenAPI spec file to process. Use - to read from stdin. (default "-")
      --uuid-base string         The unique base-string for uuid-v5 generation of entity IDs. If omitted,
                                 uses the root-level "x-kong-name" directive, or falls back to 'info.title'.)

```