# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Useful Commands

```bash
make install              # Install all dependencies (mise, gems, yarn, npm)
make run                  # Validate frontmatter, then start Jekyll + Vite dev server
make run-debug            # Same as run but with JEKYLL_LOG_LEVEL=debug
make build                # Production build via exe/build
make clean                # Remove dist/, Jekyll cache, Vite cache
make vale                 # Lint changed .md files against style guide
make kill-ports           # Kills the servers
```

The dev server starts at `http://localhost:8888` (via Netlify CLI). To build only a subset of products:

```bash
KONG_PRODUCTS=ai-gateway,gateway make run
```

## Architecture

This is a **Jekyll 4 static site** (source in `app/`) built with:
- **Ruby plugins** (`app/_plugins/`) — 250+ `.rb` files implementing custom Liquid blocks, tags, filters, generators, hooks, and drops
- **Vite + Vue 3 + Tailwind** for frontend assets, compiled via `jekyll-vite`
- **Netlify** for hosting, preview builds, and edge functions

### Key directories

| Path | Purpose |
|------|---------|
| `app/_plugins/blocks/` | Custom Liquid block tags (`{% table %}`, `{% entity_example %}`, etc.) |
| `app/_plugins/generators/` | Page generation from specs and schemas |
| `app/_plugins/tags/` | Custom Liquid tags (`{% how_to_list %}`, `{% plugin %}`, etc.) |
| `app/_plugins/hooks/` | Jekyll lifecycle hooks (post-render HTML processing, page filtering) |
| `app/_kong_plugins/*/` | Plugin documentation (index.md + schema.json + examples/) |
| `app/_how-tos/` | How-to guides collection |
| `app/_gateway_entities/` | Gateway entities documentation collection |
| `app/_references/` | **Auto-generated** — do not edit |
| `app/_data/products/` | Product configs: versions, release dates, topologies, distributions |
| `app/_data/` | Navigation, glossary, series, plugins support matrix, tooltips |
| `tools/` | Build tooling: frontmatter validator, scaffold-plugin, broken-link-checker, automated tests |

### Dev build performance

`jekyll-dev.yml` skips expensive generators by default: plugin schema pages, mesh policy generation, LLM markdown pages, search indices, auto-generated references, and kuma-to-mesh conversion. To build the full site locally, comment out the `skip:` section in `jekyll-dev.yml`.

## Page types and frontmatter

Frontmatter is validated against JSON schemas in `app/_data/schemas/frontmatter/`. `base.json` defines shared fields; each `content_type` has its own schema file (e.g. `how_to.json`, `reference.json`, `landing_page.json`, `plugin.json`, `concept.json`, `policy.json`, `support.json`). Read the relevant schema before adding or modifying frontmatter on any page.

For body formatting standards, see `app/contributing/index.md`.

## Content to never edit

These files are auto-generated from external sources:
- `app/_references/`
- `app/_data/changelogs/`
- `app/_kong_plugins/*/changelog.json` and `*/schema.json`
- `app/_schemas/gateway/plugins/`
- `app/_includes/deck/help/`
- `app/_includes/kongctl/help/`
- `app/_api/`
- `api-specs/`

## UI steps formatting

When writing UI steps, follow the formats in `docs/ui-steps-standards.md`.

## Tags

When adding frontmatter `tags:`, follow the schema in `docs/update-tag-schema.md`.

## PR review standards

- Provide GitHub suggestions with actionable code, not vague feedback.
- Comment only when >80% confident an issue exists.
- Do not flag `DECK_`-prefixed variable name differences between prerequisite exports and `entity_examples` blocks — this prefix is auto-appended at render time.
- Do not flag trailing whitespace in Markdown files.
