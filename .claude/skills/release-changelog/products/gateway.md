# Profile: Kong Gateway (`gateway`)

- Product name in headings: `Kong Gateway`
- Output file: `docs/release-changelog/gateway/{VERSION}.md` (e.g. `gateway/3.16.md`)

## Path filters

Include everything under `app/` that passes the baseline exclusions, except any path matched by the **Path filters** of another profile in `products/`.

## URL derivation (when `permalink` is missing)

- `app/_how-tos/*/foo.md` -> `/how-to/foo/` (the product subdir is NOT in the URL)
- `app/_kong_plugins/foo/index.md` -> `/plugins/foo/`
- `app/_kong_plugins/foo/examples/bar.md` or `.yaml` -> `/plugins/foo/examples/bar/`
- `app/_gateway_entities/foo.md` -> `/gateway/entities/foo/`
- `app/gateway/foo.md` -> `/gateway/foo/`
- `app/ai-gateway/foo.md` -> `/ai-gateway/foo/`
- `app/mesh/foo.md` -> `/mesh/foo/`
- `app/kic/foo.md` -> `/kic/foo/`
- `app/_landing_pages/foo.yaml` -> `/foo/` (derived from the file path; the page declares no `permalink`)
- `app/_references/foo.md` -> read the `permalink` field

## Grouping rules

- **AI Gateway**: `ai-gateway/` files, `_kong_plugins/ai-*/`, AI how-tos. Sub-group by feature (A2A, providers, guardrails, semantic, MCP, partials).
- **Kong Gateway**: `gateway/` pages, entities, non-AI plugins, gateway how-tos.
- **OIDC plugin**: always under Kong Gateway, not AI Gateway. Files: `_kong_plugins/openid-connect/`, OIDC how-tos.
- **MCP**: MCP plugin docs and how-tos.
- **Observability**: `observability/` pages.
- **Konnect**: `catalog/`, Dev Portal, and Konnect-specific content.

## Special pages

- Breaking changes: `gateway/breaking-changes*`. Always its own `## Changes` section at the end.

## Auto-generated references

Files under `app/_references/gateway/pdk/` or `app/_references/gateway/cli/` are auto-generated version bumps. Collapse to:

```
_Auto-generated references updated: [Gateway CLI Reference](URL), [PDK Reference](URL)_
```
