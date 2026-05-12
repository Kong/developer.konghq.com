# URL Derivation Rules

Path-to-URL mapping when frontmatter `permalink` is missing. Always prefer `permalink` when present.

Production base URL: `https://developer.konghq.com`

| Source path pattern | URL |
|---|---|
| `app/_how-tos/*/foo.md` | `/how-to/foo/` (product subdir is NOT in the URL) |
| `app/_kong_plugins/foo/index.md` | `/plugins/foo/` |
| `app/_kong_plugins/foo/examples/bar.yaml` | `/plugins/foo/examples/bar/` |
| `app/_gateway_entities/foo.md` | `/gateway/entities/foo/` |
| `app/gateway/foo.md` | `/gateway/foo/` |
| `app/ai-gateway/foo.md` | `/ai-gateway/foo/` |
| `app/mesh/foo.md` | `/mesh/foo/` |
| `app/kic/foo.md` | `/kic/foo/` |
| `app/_landing_pages/foo.yaml` | Read `permalink` field inside the file |
| `app/_references/foo.md` | Read `permalink` field inside the file |
