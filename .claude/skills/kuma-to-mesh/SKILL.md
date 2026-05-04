---
name: kuma-to-mesh
description: Convert a Kuma documentation page from the kuma-website repo into a Kong Mesh documentation page for developer.konghq.com. Use when converting, migrating, or porting a Kuma doc to Kong Mesh.
argument-hint: <path-to-kuma-source-file>
allowed-tools: Read Write Edit Bash
---

The arguments are: `<path-to-kuma-source-file>`. Parse it as the first space-separated token of `$ARGUMENTS`.

Convert the Kuma documentation file into a Kong Mesh documentation page.

## Repositories

- **Kuma source root**: https://github.com/kumahq/kuma-website/tree/master/app/_src
- **Kong Mesh reference target root**: `/developer.konghq.com/app/mesh/`
- **Kong Mesh how-to target root**: `/developer.konghq.com/app/_how-tos/mesh`
- **Kong Mesh policy target root**: `/developer.konghq.com/app/_mesh_policies`
- **Conversion config**: `/developer.konghq.com/app/_data/kuma_to_mesh/config.yaml`

---

## Step 1 — Check config for an existing entry

Read the conversion config. Search the `pages:` list for an entry whose `path` matches the source file (relative to the kuma-website root, e.g. `app/_src/introduction/architecture.md`).

If a config entry is found, use its values as the authoritative source for:
- `title`
- `description`
- `url` (determines the target filename)
- `related_resources`
- `min_version`
- `tags`

---

## Step 2 — Read the source file

Read the Kuma source file. Note its existing frontmatter fields (`title`, `description`, `keywords`, `content_type`, `category`) and full body content. Identify the type of content: if it contains mostly step-by-step instructions, it's a how-to. If the category is policy, it's a policy. Otherwise it's a reference.

---

## Step 3 — Determine the target file path

- If a config entry exists: derive the filename from its `url` field.
  - Example: `url: '/mesh/architecture/'` → target file is `architecture.md`
- Otherwise: use the source file's basename.
- If the page is a reference: write it to `developer.konghq.com/app/mesh/<filename>.md`
- If the page is a how-to: write it to `developer.konghq.com/app/_how-tos/mesh/<filename>.md`
- If the page is a policy: write it to `developer.konghq.com/app/_mesh_policies/<policy_name>/index.md` and add `developer.konghq.com/app/_mesh_policies/<policy_name>/examples/<example_name>.yaml`

Check whether the target file already exists. If it does, show the user the existing content and ask whether to overwrite before proceeding.

Do NOT add anything to the `/mesh/policies/` folder. For example, `/mesh/policies/mutual-tls.md` should be migrated to `/mesh/mutual-tls.md`.

If the URL changes as a result, set a permalink. For example:
```yaml
permalink: /mesh/policies/mutual-tls/
```

---

## Step 4 — Build the new frontmatter

Construct the frontmatter block with these rules:

**Always include (from config entry if available, otherwise derive):**
```yaml
title: "<title with 'Kuma' replaced by {{site.mesh_product_name}}>"
description: "<description with 'Kuma' replaced by {{site.mesh_product_name}}>"
products:
  - mesh
breadcrumbs:
  - /mesh/
```

**Include if the page is reference content:**
```yaml
content_type: reference
layout: reference
permalink: <config url when the desired URL does not match the default URL from app/mesh/<filename>.md>
```

**Include if the page is a policy:**
```yaml
name: <CRD kind, usually plural, e.g. MeshFaultInjections or MeshAccessLogs>
content_type: plugin
type: policy
icon: policy.svg
```

Do NOT include `breadcrumbs` or `layout` for policies.

**Include if the page is a how-to guide:**
```yaml
content_type: how_to
permalink: <based on the original url>
works_on:
  - on-prem        # always for Universal/VM guides; add konnect if the guide applies there too
tldr:
  q: <question form of the page title, e.g. "How do I deploy X?">
  a: <one-sentence summary of what the reader achieves by following this guide>
prereqs:
  inline:
    - title: <prerequisite title>
      content: |
        <prerequisite content — see Step 5g for how to extract this from the body>
cleanup:
  inline:
    - title: <cleanup title>
      content: |
        <cleanup steps — see Step 5g for how to extract this from the body>
```

Omit `prereqs` or `cleanup` if the source page has no corresponding section.  
Omit `works_on` only if scope cannot be determined.  
The `tldr.a` value should complete the sentence "By the end of this guide, 

**Include if available:**
```yaml
tags:
  - <converted from source `keywords:` field, plus any tags from config entry, and remove any tags not present in app/_data/schemas/frontmatter/tags.json>

related_resources:
  - text: ...
    url: /mesh/...

min_version:
  mesh: 'X.Y'   # from config entry only
```

**Do NOT carry over:** `keywords`, `category`, the original `content_type`, or any Kuma build-system fields.

**Title/description "Kuma" replacement rules:**
- Replace standalone `Kuma` (the product) with `{{site.mesh_product_name}}`
- Do NOT replace inside: `kumactl`, `kuma-cp`, `kuma-dp`, `kuma.io`, `kumahq`

---

## Step 5 — Transform the content body

Apply the following transformations to the Markdown body in order:

### 5a. Base URL replacement
Replace all occurrences of `/docs/{{ page.release }}/` and `/docs/{{page.release}}/` with relative links to the page.

### 5b. Link rewriting — `kuma` → `kong-mesh`
In any URL (inside markdown links `(...)` or HTML href `"..."`), where the URL starts with `/` or `#`:
- Replace `kuma` with `kong-mesh`
- Exception: do NOT replace inside `kumactl`, `kuma-cp`, `kuma-dp`, `kuma.io`, `kumahq`

### 5c. Exact link replacements (from config `links:` section)
Apply these verbatim substitutions anywhere they appear in link targets:
- `/install/` → `/mesh/#install-kong-mesh`
- `/enterprise/` → `/mesh/`
- `/community/` → `https://konghq.com/community`
- `/policies/` → `/mesh/policies/`
- `/features/` → `/mesh/enterprise/`

When replacing relative links, check against https://developer.konghq.com/ that the URL doesn't return a 404 and that the anchor exists.

### 5d. Prose "Kuma" replacement
In body text (not inside code blocks, YAML examples, or annotations):
- Replace standalone `Kuma` (the product name) with `{{site.mesh_product_name}}`
- Preserve: `kumactl`, `kuma-cp`, `kuma-dp`, `kuma.io`, `kumahq`, and any `kuma.io/` annotation strings

### 5e. Version-gated content (`{% if_version %}` blocks)

- If an `{% if_version %}` block only applies to versions older than the `min_version`, (for example, `{% if_version lte:2.5.x %}` when `min_version` is `2.9`), remove the content.
- If an `{% if_version %}` block applies to the `min_version` and later versions, (for example, `{% if_version gte:2.6.x %}` when `min_version` is `2.9`), keep the content and remove the version gating.

In other cases, do NOT attempt to automatically resolve version gates. Instead:
- Leave the `{% if_version %}` / `{% endif_version %}` tags in place
- After writing the file, list every version gate found so the user can review them manually

### 5f. Block replacements
- Replace `{:.tip}` and `{:.note}` with `{:.info}`.
- Replace `{% tip %}` and `{% warning %}` blocks with `{:.info}` and `{:.warning}`, for example:
  ```
  {% tip %}
  If you want to configure version, ciphers or per service permissive / strict mode check out [`MeshTLS`](/mesh/policies/meshtls)
  {% endtip %}
  ```

  Should be replaced with:
  ```
  {:.info}
  > If you want to configure version, ciphers or per service permissive / strict mode check out [`MeshTLS`](/mesh/policies/meshtls)
  ```

- Replace {% tabs %} with {% navtabs %} and {% tab %} with {% navtab %}
  - {% navtabs %} should have a title in quotes, for example: {% navtabs "environment" %}
  - {% navtab %} titles should also be in quotes, for example: {% navtab "Kubernetes" %}

- Replace any markdown table with the {% table %} block, for example:
   ```
   {% table %}
   columns:
     - title: Name
       key: name
     - title: Description
       key: description
   rows:
     - name: Field name
       description: Field description
   {% endtable %}
   ```

### 5g. How-to structural transformations (how-to pages only)

**Prerequisites section:** If the body contains a `## Prerequisites` section, move its content into the `prereqs.inline` frontmatter field and remove the heading from the body. Each top-level list item in that section becomes a separate `- title: / content: |` entry.

**Cleanup section:** If the body contains a `## Cleanup` section, move its content (including any code blocks) into the `cleanup.inline` frontmatter field and remove the heading from the body. Use a `content: |` block scalar — code fences inside YAML block scalars are preserved correctly.

**Section heading style:** Rewrite section headings to use imperative mood:
- "Introduction to X" → "Introduce X"
- "Setting up X" / "Setup of X" → "Set up X"
- "Configuration of X" / "Configuring X" → "Configure X"
- "Enabling X" → "Enable X"

### 5h. Keep unchanged
- `{% mermaid %}` blocks
- `{% schema_viewer %}`, `{% policy_yaml %}` tags
- `{:.warning}`, `{:.info}` callouts
- All code blocks (content inside `` ``` `` fences)
- `kuma.io/` annotation strings inside YAML/code examples

---

## Step 6 — Write the output file

Write the fully transformed content to the target file path.

If the page is a policy, extract examples from the source file and write each one to `developer.konghq.com/app/_mesh_policies/<policy_name>/examples/<example_name>.yaml` using this format:

```yaml
title: 'Human readable title'
description: 'What this example does.'
weight: 900
namespace: kong-mesh-demo
config:
  type: <CRD kind>
  name: <example-name>
  mesh: default
  spec:
    ...
```

Then remove the examples from the policy reference page.
---

## Step 7 — Review text quality

Read the written file and suggest prose improvements. Do not apply them automatically — list them for the user to review. Use `.github/copilot-instructions.md` for reference.

Present the suggestions as a numbered list with the original text and proposed replacement.

---

## Step 8 — Update the conversion config

Remove the entry for the converted file from the conversion config.

---

## Step 9 — Report to the user

Show a summary with:
1. **Source** → **Target** file paths
2. Front matter fields added/changed
3. Content substitutions applied (counts are fine: "12 `Kuma` → `{{site.mesh_product_name}}` replacements")
4. **Manual review needed** — list any:
   - `{% if_version %}` blocks that were left in place
   - Links that couldn't be mapped (no `/mesh/` equivalent known)
   - Missing `related_resources` (if config had none and source had none)
   - Whether a `min_version` was set or needs to be determined

