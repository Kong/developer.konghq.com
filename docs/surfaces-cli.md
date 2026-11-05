# Surfaces CLI documentation guide

This guide tells contributors and their agents where Surfaces CLI documentation goes on developer.konghq.com. Surfaces CLI is registered as a tool, in the same way as kongctl. It is not a product.

The name "Surfaces CLI" is temporary. In page text, always write `{{site.surfaces_cli}}`. Do not type the product name. When the name changes, the team edits one variable.

## Directory structure

Copy the template that matches the page you write. Replace every `TODO` and delete the `TEMPLATE` comments.

| Page | Location | Template |
|------|----------|----------|
| Landing page (`/surfaces-cli/`) | `app/_landing_pages/surfaces-cli.yaml` | Edit the file. There is only one landing page. |
| Index (`/index/surfaces-cli/`) | `app/_indices/surfaces-cli.yaml` | Add a section for each new top-level command. |
| Top-level command reference | `app/surfaces-cli/<command>/index.md` | `app/surfaces-cli/example-command/index.md` |
| Subcommand reference | `app/surfaces-cli/<command>/<subcommand>.md` | `app/surfaces-cli/example-command/example-subcommand.md` |
| Command help output | `app/_includes/surfaces-cli/help/<command>/...` | `app/_includes/surfaces-cli/help/example-command/` |
| Get-started guide (`/surfaces-cli/get-started/`) | `app/_how-tos/surfaces-cli/get-started.md` | Edit the file. There is only one get-started guide. |
| How-to guide | `app/_how-tos/surfaces-cli/<slug>.md` | `app/_how-tos/surfaces-cli/example-how-to.md` |
| Install steps | `app/_includes/tools/surfaces-cli/install/<os>.md` | Edit the files. The landing page shows them as tabs. |
| How-to prerequisite box | `app/_includes/prereqs/tools/surfaces-cli.md` | Edit the file. Every how-to with `tools: [surfaces-cli]` shows it. |
| Tool data and releases | `app/_data/tools/surfaces-cli.yml` | After the CLI ships, add its releases. |

## Rules for every page

1. Read the frontmatter schema for the page type in `app/_data/schemas/frontmatter/` before you write frontmatter.
2. Set `tools: [surfaces-cli]` on every page.
3. On a how-to, set `products: [ai-gateway]`. The how-to schema requires a product. AI Management is not a separate product. Its pages also use `ai-gateway`.
4. On a command reference page in `app/surfaces-cli/`, do not set `products`. kongctl command pages follow the same rule.
5. A page that explains an AI Gateway or AI Management task with the CLI can live with that product instead, for example in `app/ai-gateway/`. Set both `products: [ai-gateway]` and `tools: [surfaces-cli]`. `app/ai-gateway/kongctl.md` is an example of this pattern.
6. Follow the formatting standards in `app/contributing/index.md`.
7. Use relative links, for example `/surfaces-cli/get-started/`.
8. For a new top-level command, add a section to `app/_indices/surfaces-cli.yaml`. Copy the `Example Command` section. Subcommand pages appear in the index without an edit, because of the `/*/**` path.
9. Delete the `example-command` folders and `example-how-to.md` after the first real page of each kind exists.

## How-to structure

Every how-to has the same parts. `app/_how-tos/surfaces-cli/example-how-to.md` shows each one.

1. Frontmatter with `products: [ai-gateway]`, `works_on: [konnect]`, and `tools: [surfaces-cli]`. The site uses these three fields to add the common prerequisites: a Konnect token, a running AI Gateway, and the Surfaces CLI install steps. Do not write these prerequisites in the page.
2. A `tldr` block. The how-to schema requires it.
3. An inline prerequisite for each external account, key, or file the guide needs.
4. A `cleanup` block. The template uses the standard AI Gateway cleanup.
5. One H2 for each step. Each heading starts with a verb.
6. A final `## Validate` step with a `{% validation %}` tag. Use `custom-command` to test CLI output. Use `request-check` to send traffic through AI Gateway.

## Command help output

Command reference pages do not contain the `--help` text. They include it from `app/_includes/surfaces-cli/help/` with `include_cached`. Today, you paste the help output into those files by hand.

Later, a sync workflow will generate these files from the CLI, the same way that `.github/workflows/sync-kongctl.yml` generates `app/_includes/kongctl/help/`. After that workflow exists, do not edit `app/_includes/surfaces-cli/help/` by hand.

## Check your pages before you submit

1. Start the local server with only this tool's pages. Use `PAGE_PATHS`, not `KONG_PRODUCTS`. `KONG_PRODUCTS` filters on the `products` field, so it skips tool pages.

   ```bash
   PAGE_PATHS=/surfaces-cli/,/index/surfaces-cli/ make run
   ```

2. Open each new page at `http://localhost:8888`.
3. The local server skips index pages. To see `/index/surfaces-cli/` locally, set `indices: false` under `skip:` in `jekyll-dev.yml`. Do not commit that change.
4. Run Vale on your changed files:

   ```bash
   make vale
   ```

The deploy preview on the pull request builds every page, including the index.

## Rename checklist

When the tool gets its final name, change these items:

1. The `surfaces_cli` variable value in `jekyll.yml` and `jekyll-dev.yml`.
1. The `name` in `app/_data/tools/surfaces-cli.yml`. Reference page titles use this value as a suffix.
2. If the slug also changes, rename `surfaces-cli` in each of these places:
   - The `tools` enum in `app/_data/schemas/frontmatter/base.json`
   - `app/_data/tools/surfaces-cli.yml`
   - `app/_landing_pages/surfaces-cli.yaml`
   - `app/_indices/surfaces-cli.yaml`
- The `Manage with {{site.surfaces_cli}}` section paths in `app/_indices/ai-gateway.yaml`
   - `app/surfaces-cli/`
   - `app/_how-tos/surfaces-cli/`
   - `app/_includes/surfaces-cli/`, `app/_includes/tools/surfaces-cli/`, and `app/_includes/prereqs/tools/surfaces-cli.md`
   - `tools: [surfaces-cli]` in the frontmatter of every page
   - Every permalink, breadcrumb, and link that starts with `/surfaces-cli/`
3. The binary name `surfaces-cli` in code blocks, page titles, and help output.
4. If the variable name also changes, rename `site.surfaces_cli` in every page.

Add redirects in `app/_redirects` for any URL that was already published.
