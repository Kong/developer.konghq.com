---
name: third-party-plugin
description: >
  Create complete documentation for a new third-party Kong Gateway plugin on developer.konghq.com.
  Use this skill whenever the user asks to document, write, or create a new third-party Kong Gateway
  plugin page, including index.md, schema.json, or example YAML files.
  Also use it when someone shares a plugin schema (Lua or JSON), a GitHub repo, or vendor plugin assets
  and asks for help turning them into developer.konghq.com documentation.
  Trigger even if the user only says "write docs for my plugin", "add a plugin page", or "document this schema".
---

# Third-party plugin documentation skill

This skill guides you through creating complete documentation for a new third-party Kong Gateway plugin on developer.konghq.com.
The output is a new directory under `app/_kong_plugins/<plugin-slug>/` containing `index.md`, `schema.json`, and at least one `examples/*.yaml` file.

Use the Skyflow De-identify plugin as the canonical worked example of a complex plugin, and the Noma Runtime Protection and TrendAI API Security plugins as examples of simpler ones.

Read `references/patterns.md` before drafting anything. It contains the front matter schema, body section order, navtab patterns, style rules, and schema.json structure.

---

## Step 1: Gather source material

Do not draft anything until this step is complete and confirmed. The interview is mandatory.

Collect the following. Where information is ambiguous, ask rather than assume.

**Plugin identity**
- Display name (shown to users)
- Plugin slug: the kebab-case `name` field from the plugin's `schema.lua` or `schema.json` — this becomes the directory name and the value in the `name:` front matter field
- LuaRock name and current version string, for example `my-plugin-1.2.0-1` (needed for the `luarocks make` command)
- Publisher identifier: kebab-case company name (for example `skyflow`, `noma`, `trend-micro`)

**URLs and metadata**
- Support URL
- Source code URL (GitHub repo, if public)
- Tags (for example `security`, `ai`, `logging`)
- Search aliases (alternative names users might search for)
- Minimum supported gateway version, if known — omit entirely if unknown, never use an empty string

**Products and deployment**
- Products: `gateway` and/or `ai-gateway`
- `works_on`: `on-prem` and/or `konnect`

**Schema**
- The plugin's schema, as either a `schema.lua` file (provide a path or URL) or a `schema.json` file
- If Lua: read the file, extract all `config` fields with their types, defaults, and descriptions, and produce a `schema.json` (see `references/patterns.md` for the JSON Schema structure)

**Installation**
- How is the plugin distributed? Options: LuaRock only, bare `schema.lua`/`handler.lua` files only, a custom Docker image, or a combination. Not every plugin uses LuaRocks.
- If distributed as a LuaRock: the LuaRock name and current version string (for example `my-plugin-1.2.0-1`), and the path to the `.rockspec` file relative to the repo root (for the `luarocks make` command).
- Does it support Konnect Streamed plugin upload? If so, what environment variables must be set on the data plane nodes?
- Runtime dependencies beyond those already in the Kong/OpenResty runtime.

**Examples**
- At least one example use case: which config fields are set, and what behavior does it produce?
- If the plugin has distinct modes or postures (for example de-identify only vs. de-identify + re-identify), each distinct mode should become its own example file

**Publisher check**
- Check whether the publisher slug already exists in `app/_data/plugin_publishers.yml`
- If not, ask for the publisher's display name and add an entry:
  ```yaml
  publisher-slug:
    name: Publisher Display Name
  ```

**Icon check**
- Check whether the icon file exists at `app/assets/icons/plugins/<icon-filename>.svg`
- The icon filename in the front matter should be `<publisher-slug>.svg` or `<plugin-slug>.svg`
- If the file is not present, note it as a gap in the pre-draft confirmation and tell the user:
  "The icon file `<filename>.svg` does not exist in `app/assets/icons/plugins/`. You'll need to obtain it from the vendor and add it before the plugin page will render correctly."
- Do not block drafting the docs on this — just flag it clearly.

---

## Step 2: Assess complexity

Use this classification to calibrate how much content to write.

**Simple plugin** (DataDome, Moesif, TrendAI pattern)
- Few flat config fields (1-5 API keys or settings)
- No multi-phase request/response lifecycle
- Installation is one or two commands
- One example file is sufficient
- No sequence diagram needed

**Complex plugin** (Noma, Skyflow, Impart, CrowdStrike pattern)
- Nested or many config fields
- Plugin acts in multiple Kong lifecycle phases (access, response, log)
- Request body is inspected and rewritten
- Installation has meaningful Konnect-specific steps
- Multiple example scenarios warranted
- Sequence diagram recommended; flowchart if topology is non-trivial

---

## Step 3: Pre-draft confirmation

Before writing anything, present a checklist of what you collected. Flag any gaps explicitly. Wait for the user to confirm or fill in what is missing.

Example format:

```
Ready to draft. Here's what I have:

Plugin identity
- Display name: Skyflow De-identify
- Slug: skyflow-ai-data-control
- LuaRock: skyflow-ai-data-control-0.7.0-1
- Publisher: skyflow (exists in plugin_publishers.yml)

Schema
- Source: schema.lua at [URL] — will convert to schema.json

Installation
- Self-managed: luarocks make + KONG_PLUGINS env var
- Konnect: streamed plugin (schema.lua + handler.lua upload)
  - Env vars: KONG_CUSTOM_PLUGIN_STREAMING_ENABLED=on, KONG_UNTRUSTED_LUA=lax, KONG_PLUGINS=bundled

Examples
- Example 1: de-identify only (reidentify.enabled = false)
- Example 2: de-identify + re-identify (default posture)

Gaps: none

Complexity: complex (multi-phase, nested config, Konnect streamed)

Proceed?
```

---

## Step 4: Draft all files

Draft in this order:

### 1. schema.json

Read `references/patterns.md` for the full JSON Schema structure. Every config field from the plugin's schema becomes a property in `config.properties`. Use the standard scope fields (consumer, consumer_group, route, service, protocols) unchanged.

Place at: `app/_kong_plugins/<slug>/schema.json`

### 2. index.md

Read `references/index-template.md` for the annotated template. Replace all `<!-- PLACEHOLDER -->` markers with real content.

Key rules:
- Never use em dashes
- `{{site.base_gateway}}` for "Kong Gateway" / "Kong"
- `{{site.konnect_short_name}}` for "Konnect"
- One sentence per line in prose
- No empty `min_version` — omit the field if unknown
- Bold only UI labels, not prose emphasis
- Sentence-case headings

Place at: `app/_kong_plugins/<slug>/index.md`

### 3. examples/*.yaml

Read `references/example-template.md` for the annotated template. One file per scenario.

Naming: `<verb>-<what-it-does>.yaml`, for example `deidentify-only.yaml`, `enable-noma-runtime-protection.yaml`.

Weight: 900 for the primary example, 901 for secondary, and so on.

Place at: `app/_kong_plugins/<slug>/examples/<name>.yaml`

### 4. reference.md stub

The platform renders the schema reference page automatically from `schema.json`. Create a minimal stub:

```markdown
See [schema reference](./reference/)
```

Place at: `app/_kong_plugins/<slug>/reference.md`

---

## Step 5: Review and iterate

Present the drafted files. Accept feedback and revise. Pay particular attention to:
- Config field descriptions: are they accurate to the actual schema?
- Example variable names: do they match what a user would actually set in their environment?
- Installation steps: are they complete enough for someone who has never installed a custom plugin?
