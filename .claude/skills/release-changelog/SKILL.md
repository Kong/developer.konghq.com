---
name: release-changelog
description: Use this skill when the user runs "/release-changelog", asks to "generate a release changelog", "write release PR description", "build preview links for release", or wants to summarize all docs changed in a release PR as a grouped list of links.
version: 1.1.0
---

# Release Changelog Skill

Generates a grouped, formatted changelog of new and updated docs for a Kong Gateway release. Splits content into new docs vs updated docs, and saves to `docs/release-changelog/{VERSION}.md`.

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

Run both of these, filtering to `.md` files under `app/` only:

```bash
# Newly added files
git diff origin/main --name-only --diff-filter=A | grep '^app/.*\.md$'

# Modified existing files
git diff origin/main --name-only --diff-filter=M | grep '^app/.*\.md$'
```

If the user specified a different base branch, replace `origin/main` accordingly.

If both return nothing, fall back to `git diff HEAD~1 --name-only` for both filters.

Keep the two lists separate — they map to `### New docs` and `### Updated docs` in the output.

### 3. Read frontmatter for each changed file

For each `.md` file in both lists, read its YAML frontmatter to extract:
- `title` — used as link text
- `permalink` — the canonical URL path

If `permalink` is missing, derive it from the file path:
- `app/_how-tos/*/foo.md` → `/how-to/foo/`
- `app/_kong_plugins/foo/index.md` → `/plugins/foo/`
- `app/_kong_plugins/foo/examples/bar.md` → `/plugins/foo/examples/bar/`
- `app/_gateway_entities/foo.md` → `/gateway/entities/foo/`
- `app/gateway/foo.md` → `/gateway/foo/`
- `app/ai-gateway/foo.md` → `/ai-gateway/foo/`
- `app/mesh/foo.md` → `/mesh/foo/`
- `app/kic/foo.md` → `/kic/foo/`
- `app/_landing_pages/foo.yaml` → read the `permalink` field inside the file
- `app/_references/foo.md` → read the `permalink` field

If `title` is missing, derive it from the filename (replace hyphens with spaces, title-case).

### 4. Handle auto-generated reference files

Files under `app/_references/gateway/pdk/` or `app/_references/gateway/cli/` are auto-generated version bumps. Do not list them individually. Instead, add a single line at the bottom of the output:

```
_Auto-generated references updated: [Gateway CLI Reference](URL), [PDK Reference](URL)_
```

### 5. Note on `_includes`-driven changes

Some files in the modified list may have changed only because a shared `_includes` partial was updated (e.g., all logging plugins changing when a log format partial changes). These are still real doc changes — include them — but if a large batch of similar files all changed together (5+ plugins of the same category), group them under a single collapsed bullet rather than listing each separately:

```markdown
**Logging plugins** (updated for custom log fields): [File Log](URL), [HTTP Log](URL), [Kafka Log](URL), [Loggly](URL), [Syslog](URL), [TCP Log](URL), [UDP Log](URL)
```

### 6. Construct live URLs

Always use the production base URL:
```
https://developer.konghq.com{permalink}
```

### 7. Identify anchors

If the user's input includes anchor references (e.g. `#token-exchange`), append them to the relevant URL. Otherwise omit anchors.

### 8. Group the links

Use your judgment to group links by product/feature area. Common groupings:

- **AI Gateway** — `ai-gateway/` files, `_kong_plugins/ai-*/`, AI-related how-tos
- **OIDC plugin** — `_kong_plugins/openid-connect/`, OIDC how-tos
- **Datakit** — `_kong_plugins/datakit/`
- **Kong Gateway** — `gateway/` pages, entities, expressions
- **Plugins** (other) — remaining `_kong_plugins/` not covered above
- **MCP** — MCP plugin docs and how-tos
- **Observability** — `observability/` pages
- **Changes** — `gateway/breaking-changes*` (always its own section, never under New or Updated)

Nesting rule: if multiple files relate to the same feature (plugin doc + examples + how-to), group them under one named parent bullet with sub-bullets:

```markdown
**Ollama provider:**
* [Ollama provider reference](URL)
* [How-to: Set up AI Proxy with Ollama](URL)
```

### 9. Output format

```markdown
## New and updated docs for the [VERSION] release

## New docs

### [Product/Feature Area]

**[Feature Group]:**
* [Link text](URL)
* [Link text](URL)

### [Another Area]
* [Link text](URL)

## Updated docs

### [Product/Feature Area]

**[Feature Group]:**
* [Link text](URL)

_Auto-generated references updated: [Gateway CLI Reference](URL), [PDK Reference](URL)_

## Changes
* [Breaking changes, deprecations, and known issues](URL)
```

- `## New docs` — files that did not exist on `main` (added)
- `## Updated docs` — files that existed and were modified
- `## Changes` — breaking changes pages only; always last

### 10. Save the changelog

Write the output to:
```
docs/release-changelog/{VERSION}.md
```

Create `docs/release-changelog/` if it doesn't exist. The file contains only the markdown body — no extra metadata.

### 11. Handle missing context

If the user provides a PR description or list of PRs as context, extract groupings from it to supplement the git diff (helpful when the release branch bundles multiple feature PRs).

If the user pastes an existing PR description, offer to reformat it with updated live URLs.

## Notes

- Always prefer the frontmatter `permalink` over path-derived URLs — the frontmatter is authoritative
- How-tos: `app/_how-tos/{product}/{name}.md` → `/how-to/{name}/` (product subdirectory is NOT part of the URL)
- Plugin examples: `app/_kong_plugins/{plugin}/examples/{name}.md` → `/plugins/{plugin}/examples/{name}/`
- Breaking changes pages go under `## Changes`, never under new or updated docs
- Production base URL is always `https://developer.konghq.com`
