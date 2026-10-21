---
name: release-changelog
description: Use this skill when the user runs "/release-changelog", asks to "generate a release changelog", "write release PR description", "build preview links for release", or wants to summarize all docs changed in a release PR as a grouped list of links. Supports Kong Gateway (default) and Event Gateway, and is extensible to other products.
version: 2.0.0
---

# Release Changelog Skill

Generates a grouped, formatted changelog of new and updated docs for a product release. New docs are listed as-is. Updated docs include a description of *what changed*, derived from the git diff.

The generic workflow lives in this file. Everything product-specific (path filters, URL rules, grouping, special pages, output filename) lives in a product profile under `products/`.

## Invocation

```
/release-changelog [PRODUCT] <VERSION> [BASE_BRANCH]
```

- `PRODUCT`: product profile name. Optional. Defaults to `gateway`. Available profiles:
  - `gateway`: Kong Gateway, see [products/gateway.md](products/gateway.md)
  - `event-gateway`: Kong Event Gateway, see [products/event-gateway.md](products/event-gateway.md)
- `VERSION`: release version number (e.g. `3.14`, `1.3`). Used in the output filename and heading.
- `BASE_BRANCH`: branch to diff from. Defaults to `main`.

Parsing: if the first argument matches a version number (digits and dots), treat it as `VERSION` and use `PRODUCT=gateway`. Otherwise the first argument is `PRODUCT`. If the user does not name a product, infer it from the current branch name (`event-gateway` in the branch means `event-gateway`) and say which profile you picked. If the product has no profile, tell the user and offer to create one (see "Adding a product").

## Step-by-Step Instructions

### 1. Load the product profile

Read `products/{PRODUCT}.md`. It defines: path filters, URL derivation rules, grouping, special pages, auto-generated references, and the output filename. Use those values wherever the steps below say "per the profile".

### 2. Check current branch

Run:
```bash
git branch --show-current
```

If the branch name does not look like a release branch for this product (e.g. `release/3.14`, `release/event-gateway-1.3`, `feat/3.14-docs`), warn the user:

> Warning: current branch is `{branch}`. This may not be the release branch. The changelog will reflect all differences from `{BASE}` on this branch. Continue anyway or switch branches first.

Then proceed.

### 3. Get new vs updated files

Diff against the merge base, not the tip of the base branch. Use the three-dot form so that docs merged to the base branch after this branch was cut do not show up as reverse changes:

```bash
BASE=origin/main   # or origin/{BASE_BRANCH}

# Newly added files
git diff $BASE...HEAD --name-only --diff-filter=A

# Modified existing files
git diff $BASE...HEAD --name-only --diff-filter=M
```

Pipe each through the path filters from the profile. All profiles share these baseline exclusions: drop `app/_includes/` and `app/assets/`, and keep only `.md`, `.yaml`, and `.yml` files under `app/`. Do not include tests, tooling, workflows, or Ruby plugin code even if they changed.

If both lists are empty, fall back to `git diff HEAD~1 --name-only` with the same filters.

Keep the two lists separate. Added files go under `## New docs`, modified files go under `## Updated docs`.

Renamed files: run `git diff $BASE...HEAD --name-status -M` once. Treat a rename as an update to the new path, and mention the rename in the annotation.

### 4. For each MODIFIED file, read the diff to understand what changed

This is the most important step for updated files. For each modified page file, run:

```bash
git diff $BASE...HEAD -- <file>
```

From the diff output, extract:
- **New headings**: lines matching `^\+#{1,4}\s+`. These are new sections added to the page.
- **Removed headings**: lines matching `^\-#{1,4}\s+`. Sections removed.
- **Significant new content blocks**: large additions that indicate a new feature, example, or reference was documented.
- **Frontmatter changes**: if `title` changed, note the rename.

Use this to write a short, specific annotation for the link, e.g.:
- `: new section: Conditional plugin execution`
- `: new examples: token exchange`
- `: updated: supported algorithms list (SHA1 removed)`

**The annotation describes the feature, not the file change.** "New section: Conditional plugin execution" is good. "File updated" is useless.

If the diff adds multiple distinct things, list them: `: new sections: Token Exchange, Consumer Claims`.

If the diff is noise (whitespace, formatting, frontmatter version bumps), write `: minor updates`, or skip the entry entirely if it has no reader-visible effect.

### 5. For ADDED files, no diff annotation needed

New files speak for themselves. List them with just the title and link, grouped by feature. Optionally add a one-line description from the frontmatter `description` field if it adds useful context.

### 6. Read metadata for each file

**For `.md` page files**, read YAML frontmatter for:
- `title`: link text. Resolve Liquid variables such as `{{site.event_gateway}}` using the profile's product-name table.
- `permalink`: canonical URL path
- `description`: optional context for new files

**For example `.yaml`/`.yml` files**, read the top-level YAML fields directly (no frontmatter delimiters):
- `title`: link text. If absent, derive from the filename (replace hyphens with spaces, title-case).
- URL is derived from the path per the profile.

If `permalink` is missing, derive the URL from the path using the profile's URL table. Always prefer an explicit `permalink` over a path-derived URL.

### 7. Handle auto-generated reference files

Each profile lists auto-generated reference paths. Do not list those individually. Add a single line at the bottom of the output:

```
_Auto-generated references updated: [Reference name](URL), [Reference name](URL)_
```

### 8. Handle bulk include-driven changes

If 5+ pages were all modified because of the same `_includes` partial change, collapse them into a single inline list with a parenthetical note:

```markdown
**Logging plugins** (updated for custom log fields): [File Log](URL), [HTTP Log](URL), ...
```

For smaller cases, still include the link but annotate with what the include change means to the reader, not the implementation detail.

### 9. Construct live URLs

```
https://developer.konghq.com{permalink}
```

### 10. Group the links

Group by feature area, using the grouping rules in the product profile. Use the feature or capability as the group name, not the file type.

Nesting: if multiple files relate to the same feature, group under a named parent with sub-bullets:

```markdown
**Ollama provider:**
* [Ollama provider reference](URL)
* [How-to: Set up AI Proxy with Ollama](URL)
```

### 11. Output format

```markdown
## New and updated docs for the {PRODUCT NAME} {VERSION} release

## New docs

### [Feature Area]

**[Feature name]:**
* [Link text](URL)
* [Link text](URL)

### [Another area]
* [Link text](URL)

---

## Updated docs

### [Feature Area]

**[Feature name]:**
* [Link text](URL): new section: Feature Name
* [Link text](URL): updated: specific thing that changed

### [Another area]
* [Link text](URL): description of change

_Auto-generated references updated: [Reference](URL)_

## Changes
* [Breaking changes, deprecations, and known issues](URL)
```

Rules:
- `## New docs`: added files only.
- `## Updated docs`: modified files, each with a change annotation.
- `## Changes`: the product's breaking changes page, only if it changed, always last.
- Do not use em dashes anywhere in the output, including in group headings. Write `### Event Gateway: Policies`. Annotations use a colon: `: description`.
- Skip the annotation only if the diff is pure noise.
- Omit any section that would be empty.

### 12. Save the changelog

Write output to the path given by the profile (`docs/release-changelog/...`). Create the directory if needed.

### 13. Handle missing context

If the user pastes an existing PR description or list of PRs, use it to supplement grouping decisions and identify anchors to append to URLs.

## Adding a product

Copy [products/event-gateway.md](products/event-gateway.md) as a template, then fill in these sections: product name and Liquid variables, path filters, URL table, grouping rules, special pages, auto-generated references, output filename. Add the product to the list under "Invocation". To fill in the URL table, check real `permalink` values in the product's how-tos, references, and landing pages. Do not guess URL patterns.

## Notes

- Always prefer frontmatter `permalink` over path-derived URLs.
- Production base URL: `https://developer.konghq.com`.
- Breaking changes go under `## Changes`, never under new or updated docs.
