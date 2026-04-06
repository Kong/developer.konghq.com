---
name: release-changelog
description: Use this skill when the user runs "/release-changelog", asks to "generate a release changelog", "write release PR description", "build preview links for release", or wants to summarize all docs changed in a release PR as a grouped list of links.
version: 1.2.0
---

# Release Changelog Skill

Generates a grouped, formatted changelog of new and updated docs for a Kong Gateway release. New docs are listed as-is; updated docs include a description of *what changed*, derived from the git diff. Saves to `docs/release-changelog/{VERSION}.md`.

## Invocation

```
/release-changelog <VERSION> [BASE_BRANCH]
```

- `VERSION` — release version number (e.g. `3.14`). Used as the filename when saving.
- `BASE_BRANCH` — branch to diff against (default: `main`).

## Step-by-Step Instructions

### 1. Check current branch

Run:
```bash
git branch --show-current
```

If the branch name does not look like a release branch (e.g. `release/3.14`, `release-3.14`, `feat/3.14-docs`, or similar), warn the user:

> Warning: current branch is `{branch}` — this may not be the release branch. The changelog will reflect all differences from `main` on this branch. Continue anyway or switch branches first.

Then proceed.

### 2. Get new vs updated files

Run both of these, filtering to `.md` files under `app/` only (exclude `app/_includes/` and `app/assets/`):

```bash
# Newly added files
git diff origin/main --name-only --diff-filter=A | grep '^app/.*\.md$' | grep -v '^app/_includes/' | grep -v '^app/assets/'

# Modified existing files
git diff origin/main --name-only --diff-filter=M | grep '^app/.*\.md$' | grep -v '^app/_includes/' | grep -v '^app/assets/'
```

If the user specified a different base branch, replace `origin/main` accordingly.

If both return nothing, fall back to `git diff HEAD~1 --name-only` with the same filters.

Keep the two lists separate — added files go under `## New docs`, modified files go under `## Updated docs`.

### 3. For each MODIFIED file — read the diff to understand what changed

This is the most important step for updated files. For each modified page file, run:

```bash
git diff origin/main -- <file>
```

From the diff output, extract:
- **New headings**: lines matching `^\+#{1,4}\s+` — these are new sections added to the page
- **Removed headings**: lines matching `^\-#{1,4}\s+` — sections removed
- **Significant new content blocks**: large additions that indicate a new feature, example, or reference was documented
- **Frontmatter changes**: if `title` changed, note the rename

Use this to write a short, specific annotation for the link, e.g.:
- `— new section: Conditional plugin execution`
- `— new section: AI Plugin Partials`
- `— new examples: token exchange`
- `— updated: supported algorithms list (SHA1 removed)`
- `— new section: ACL evaluation logic`

**The annotation should describe the feature, not the file change.** "New section: Conditional plugin execution" is good. "File updated" is useless.

If the diff is large and adds multiple distinct things, list them:
- `— new sections: Token Exchange, Consumer Claims`

If the diff is noise (e.g. only whitespace, formatting, or frontmatter version bumps), skip annotation or write `— minor updates`.

### 4. For ADDED files — no diff annotation needed

New files speak for themselves. List them with just the title and link, grouped by feature. Optionally add a one-line description from the frontmatter `description` field if it's useful context.

### 5. Read frontmatter for each file

For each file (new or modified), read YAML frontmatter for:
- `title` — link text
- `permalink` — canonical URL path
- `description` — optional context for new files

If `permalink` is missing, derive from path:
- `app/_how-tos/*/foo.md` → `/how-to/foo/`
- `app/_kong_plugins/foo/index.md` → `/plugins/foo/`
- `app/_kong_plugins/foo/examples/bar.md` → `/plugins/foo/examples/bar/`
- `app/_gateway_entities/foo.md` → `/gateway/entities/foo/`
- `app/gateway/foo.md` → `/gateway/foo/`
- `app/ai-gateway/foo.md` → `/ai-gateway/foo/`
- `app/mesh/foo.md` → `/mesh/foo/`
- `app/kic/foo.md` → `/kic/foo/`
- `app/_landing_pages/foo.yaml` → read `permalink` field inside the file
- `app/_references/foo.md` → read `permalink` field

### 6. Handle auto-generated reference files

Files under `app/_references/gateway/pdk/` or `app/_references/gateway/cli/` are auto-generated version bumps. Do not list them individually. Add a single line at the bottom of the output:

```
_Auto-generated references updated: [Gateway CLI Reference](URL), [PDK Reference](URL)_
```

### 7. Handle bulk include-driven changes

If 5+ plugin `index.md` files were all modified and trace back to the same `_includes` partial change (e.g. all logging plugins changed when `log-custom-fields-by-lua.md` was modified), collapse them to a single inline list with a parenthetical note:

```markdown
**Logging plugins** (updated for custom log fields): [File Log](URL), [HTTP Log](URL), ...
```

For other cases where a plugin index changed because of an include, still include the link but annotate with what the include change means to the reader, not the implementation detail.

### 8. Construct live URLs

```
https://developer.konghq.com{permalink}
```

### 9. Group the links

Group by product/feature area. Use the feature or capability as the group name, not the file type.

**Grouping rules:**
- **AI Gateway** — `ai-gateway/` files, `_kong_plugins/ai-*/`, AI how-tos. Sub-group by feature (A2A, providers, guardrails, semantic, MCP, partials).
- **Kong Gateway** — `gateway/` pages, entities, non-AI plugins, gateway how-tos
- **OIDC plugin** — always under Kong Gateway, not AI Gateway. Files: `_kong_plugins/openid-connect/`, OIDC how-tos
- **MCP** — MCP plugin docs and how-tos
- **Observability** — `observability/` pages
- **Konnect** — `catalog/`, Dev Portal, and Konnect-specific content
- **Changes** — `gateway/breaking-changes*` always its own section at the end

Nesting: if multiple files relate to the same feature, group under a named parent with sub-bullets:

```markdown
**Ollama provider:**
* [Ollama provider reference](URL)
* [How-to: Set up AI Proxy with Ollama](URL)
```

### 10. Output format

```markdown
## New and updated docs for the [VERSION] release

## New docs

### [Product/Feature Area]

**[Feature name]:**
* [Link text](URL)
* [Link text](URL)

### [Another area]
* [Link text](URL)

---

## Updated docs

### [Product/Feature Area]

**[Feature name]:**
* [Link text](URL) — new section: Feature Name
* [Link text](URL) — updated: specific thing that changed

### [Another area]
* [Link text](URL) — description of change

_Auto-generated references updated: [Gateway CLI Reference](URL), [PDK Reference](URL)_

## Changes
* [Breaking changes, deprecations, and known issues](URL)
```

Rules:
- `## New docs` — added files only
- `## Updated docs` — modified files, each with a change annotation
- `## Changes` — breaking changes page only, always last
- Annotations use em dash: `— description`
- Skip annotation only if the diff is pure noise (whitespace, version bumps)

### 11. Save the changelog

Write output to `docs/release-changelog/{VERSION}.md`. Create the directory if needed.

### 12. Handle missing context

If the user pastes an existing PR description or list of PRs, use it to supplement grouping decisions and identify anchors to append to URLs.

## Notes

- Always prefer frontmatter `permalink` over path-derived URLs
- How-tos: `app/_how-tos/{product}/{name}.md` → `/how-to/{name}/` (product subdir is NOT in the URL)
- Plugin examples: `app/_kong_plugins/{plugin}/examples/{name}.md` → `/plugins/{plugin}/examples/{name}/`
- OIDC is a Kong Gateway plugin, not an AI Gateway plugin — always group it under Kong Gateway
- Breaking changes go under `## Changes`, never under new or updated docs
- Production base URL: `https://developer.konghq.com`
