---
name: ai-gateway-migration-review
description: >
  Reviews AI Gateway documentation files for correctness during the v1 → v2 migration.
  Use this skill whenever you need to audit or fix AI Gateway docs for migration issues —
  whether reviewing specific files or all AI Gateway files across how-tos, landing pages,
  and reference pages. Triggers on requests like "review this ai-gateway file", "check
  my migration", "audit ai-gateway docs for v2", "find v1 references in ai-gateway pages",
  "update this file for AI Gateway v2", or any time someone is working on AI Gateway
  content under app/_how-tos/ai-gateway, app/_landing-pages/ai-gateway, or app/ai-gateway.
---

# AI Gateway Migration Review Skill

This skill audits and optionally fixes AI Gateway documentation files for the v1 → v2 migration.

## Step 1: Ask the user two questions upfront

Before doing any work, ask (you can ask both in one message):

1. **Scope**: Do they want to review a specific files or directories or all AI Gateway files?
   - If specific files or directories, ask for the path.
   - If all files, you'll scan these directories:
     - `app/_how-tos/ai-gateway/`
     - `app/_landing_pages/ai-gateway/`
     - `app/ai-gateway/`

2. **Mode**: Should you make changes directly, or produce a report of issues to fix?

## Step 2: Perform the review

Apply the rules below. For **report mode**, collect all findings and present them as a structured report at the end. For **edit mode**, apply fixes directly and summarize what changed.

---

## Rules for v1 files (under any `v1/` subdirectory)

These files are the legacy v1 content. They need their own internal consistency:

- **Breadcrumbs and links**: Any breadcrumbs or links starting with `/ai-gateway/` must use `/ai-gateway/v1/` (not the bare `/ai-gateway/` path).
- **Permalinks**: If the file has a `permalink:` frontmatter field, it must contain `/v1/` in the path.
- **Include and data file references**: References to AI Gateway include files (`{% include_content ... %}`, `{% include ... %}`) and data files must use the `/v1/` variant, e.g. `ai-gateway/v1/some-include` not `ai-gateway/some-include`.

---

## Rules for v2 files (current, non-v1 AI Gateway files)

### Frontmatter requirements

Every v2 AI Gateway page must have this exact frontmatter shape for these fields:

```yaml
products:
    - ai-gateway          # Only ai-gateway, no other products
works_on:
    - konnect             # Only konnect, no on-prem
tools:
    - konnect-api         # Optional field, if it exists, must be only konnect-api
min_version:
    ai-gateway: '2.0'
```

Flag any deviation:
- `products` containing anything other than `ai-gateway`
- `works_on` containing `on-prem` or anything other than `konnect`
- `tools` containing `deck`, `admin-api`, or anything other than `konnect-api`
- Missing or wrong `min_version` (must be `ai-gateway: '2.0'`)

### Plugin → AI Policy migration

Plugins have been replaced by AI Policies in v2. The four plugins that do **not** exist as policies are exceptions:
- AI A2A Proxy
- AI MCP Proxy
- AI Proxy
- AI Proxy Advanced

For everything else:

- **Rename in prose**: Replace "X plugin" with "X Policy". For example:
  - "AI Request Transformer plugin" → "AI Request Transformer Policy"
  - "AI Prompt Guard plugin" → "AI Prompt Guard Policy"

- **Links to plugins**: Replace `/plugins/` path with `/ai-gateway/policies/`. For example:
  - `/plugins/ai-prompt-guard/` → `/ai-gateway/policies/ai-prompt-guard/`

- **Exception — flag these**: Any reference to AI A2A Proxy, AI MCP Proxy, AI Proxy, or AI Proxy Advanced as plugins should be flagged for manual review (these don't have policy equivalents).

- **Landing page plugin blocks**: In YAML landing pages (`.yaml` files under `_landing_pages/`), replace `type: plugin` blocks with `type: aigw_policy`. Example:
  ```yaml
  # Before (v1)
  - type: plugin
    config:
      slug: ai-prompt-guard
  
  # After (v2)
  - type: aigw_policy
    config:
      slug: ai-prompt-guard
  ```

### Include and data file references

References to AI Gateway include files and data files must use `/v2/`. For example:
- `ai-gateway/circuit-breaker` → `ai-gateway/v2/circuit-breaker`
- `_includes/md/ai-gateway/circuit-breaker.md` → `_includes/md/ai-gateway/v2/circuit-breaker.md`

Flag any `{% include /plugins/` tags — v2 AI Gateway pages must not pull in plugin includes. These should be removed or replaced with the appropriate AI Policy equivalent.

### Code block style

Example codeblocks in how-to guides should use `{% konnect_api_request %}` rather than raw curl or deck commands where they're making API calls. Flag any `curl` commands or `deck` commands in example steps that should be `{% konnect_api_request %}` blocks.

### Konnect-only deployments

v2 AI Gateway is Konnect-only. Flag any references to on-premises deployments, self-hosted Kong Gateway, or any instructions that only apply to on-prem.

### Kong Gateway → AI Gateway

References to Kong Gateway or `{{site.base_gateway}}` should be replaced with `{{site.ai_gateway}}`.

### AI Gateway entity names

All AI Gateway entity names (from `app/_ai_gateway_entities/`) must be capitalized and prefixed with "AI". Known entities:
- AI Agent
- AI Consumer
- AI Consumer Credential
- AI Consumer Group
- AI Data Plane Certificate
- AI Data Plane Node
- AI Gateway
- AI MCP Server
- AI Model
- AI Policy
- AI Provider
- AI Vault

Flag any references to these entities without the "AI" prefix (e.g., "model" instead of "AI Model", "provider" instead of "AI Provider", "policy" instead of "AI Policy"). **Check the entire file including frontmatter** — FAQs, `related_resources` links, and all entity references in link text must use the full "AI" prefix (e.g., `[AI Policy entity]` not `[Policy entity]`).

### Links to unmigrated how-to guides

Not all v1 how-to guides have been migrated to v2. The only migrated v2 how-to is currently:
- `get-started-with-ai-gateway`

Any link in a v2 file that points to a how-to guide URL not directly in `app/_how-tos/ai-gateway/` should be flagged. Links to v1 how-tos (containing `/v1/`) should either be removed or flagged.

### v1 release tracking (`app/_config/releases/ai-gateway/v1.yml`)

This file tracks every v1 page and whether a v2 equivalent has been written. Each entry looks like:

```yaml
app/_how-tos/ai-gateway/v1/some-guide.md:
  status: pending       # still needs a v2 equivalent
  canonical_url:        # should point to the v2 page once written
```

When a new v2 page is created, the corresponding v1 entry in this file must be updated:
- Remove `status: pending`
- Set `canonical_url` to the new v2 page's permalink

When reviewing a newly created v2 file, check whether its v1 counterpart exists in `v1.yml` and still has `status: pending`. If so, flag it: the reviewer should remove `status: pending` and set `canonical_url` to the new page's permalink.

When reviewing all files, read `app/_config/releases/ai-gateway/v1.yml` and report all entries that still have `status: pending` — these are v1 pages that have not yet been migrated.

---

## Reporting format

When producing a **report**, structure it like this for each file reviewed:

```
### <filepath>

**Frontmatter issues:**
- <issue description>

**Plugin → AI Policy issues:**
- <issue description>

**Include/data file references (including `{% include /plugins/` tags):**
- <issue description>

**Unmigrated how-to links:**
- <link> — not yet migrated, remove or update

**v1 release tracking (`v1.yml`):**
- <v1 file path> — still has `status: pending`, set `canonical_url` to <v2 permalink>

**On-prem references:**
- Line N: <quote> — flag for removal

**Entity naming:**
- <issue description>

**No issues found** (if clean)
```

For a **single-file edit**, after making changes, produce a brief summary of every change made.

For **all-files edit**, process files one at a time and produce a per-file summary at the end.
