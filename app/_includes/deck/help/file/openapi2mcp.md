```ansi
Usage:
  deck file openapi2mcp [flags]

Flags:
      --format string            output format: yaml or json (default "yaml")
  -h, --help                     help for openapi2mcp
      --ignore-security-errors   Ignore errors for unsupported security schemes or missing x-kong-mcp-acl extensions.
      --include-direct-route     Also generate non-MCP routes for direct API access.
  -m, --mode string              ai-mcp-proxy mode: 'conversion' (client mode) or 'conversion-listener' (server mode). (default "conversion-listener")
      --no-id                    Do not generate UUIDs for entities.
  -o, --output-file string       Output file to write. Use - to write to stdout. (default "-")
  -p, --path-prefix string       Custom path prefix for the MCP route (default: /{service-name}-mcp).
      --select-tag strings       Select tags to apply to all entities. If omitted, uses the "x-kong-tags"
                                 directive from the file.
  -s, --spec string              OpenAPI spec file to process. Use - to read from stdin. (default "-")
      --uuid-base string         The unique base-string for uuid-v5 generation of entity IDs. If omitted,
                                 uses the root-level "x-kong-name" directive, or falls back to 'info.title'.

```