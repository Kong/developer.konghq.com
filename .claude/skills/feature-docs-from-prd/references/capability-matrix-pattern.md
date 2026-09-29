# Adding a new capability/enum value to an existing support matrix

This is the one pattern this skill has actually verified end-to-end, from a
real PRD (`Kong/platform-api#3398`, adding a `skills` capability to
`AIGatewayModelAPI`) against the real "before" state of every file it
touches. Treat this as a literal template, not inspiration — the actual
Liquid and YAML blocks below are copy-templates, not just descriptions of
what to write.

## Recognize this shape

You're looking at this pattern when the spec diff adds one new value to an
existing `enum` on a construct that already has several other values (e.g.
`capabilities: [batches, files]` → `[batches, files, skills]`), **and**
there's a corresponding entity reference page in this repo whose prose
already enumerates that same enum's values in a bullet list and/or a table.
Search for the enum's other existing values (e.g. `batches`, `files`) across
`app/_ai_gateway_entities/`, `app/_data/`, and `app/_includes/md/` — if they
appear in multiple files with a clearly repeated per-value block shape, this
is the matrix pattern.

## The four places to check (using the AI Model / `skills` case as the concrete example)

1. **The entity reference page** — `app/_ai_gateway_entities/<entity>.md`
   (here: `ai-model.md`). Update:
   - The prose bullet list that enumerates the enum's values for its type (e.g. the `**\`api\` type**: ... Available capabilities: \`batches\`, \`files\`` line — add the new value).
   - The capabilities table (a `{% table %}` block listing each capability, its default path, and a one-line description) — add one row.
   - **Check the "formats" table too, not just the capabilities table.** This entity page usually has a second table listing each `formats[].type` value's *native* capabilities in prose (e.g. "`anthropic` format: Messages, batch processing."). If the new capability is something a provider's *native* format now passes through natively (not just something the OpenAI-shaped model exposes), that provider's native-capabilities row needs the new value appended too — this is easy to miss because it's a different table from the one you're already editing, and it's a real content gap, not a style nit: a reader picking `formats: [{type: anthropic}]` needs to know native skills passthrough is one of the things they get. Check this even when you're confident you've already covered "the capabilities table" — they're two separate, both-real edits.
   - **If the new capability needs a worked example and none exists yet for its type**, author one: a new `###` section plus an `{% entity_example %}` block. Don't treat "no existing example to copy field values from" as a reason to skip this — it means you need to go find the entity's *schema*, not that no source material exists. Check the entity page's own auto-generated `## Schema` section (rendered from a JSON schema file, typically under `app/_schemas/<product>/entities/` or similar — grep for the entity's construct name) for the real, current field list, types, and required-ness before writing the example. Use `how-to-starter`'s `references/scaffold-patterns.md` for the tag syntax (`{% entity_example %}` vs `{% entity_examples %}`, `!ref`/`!lookup` scoping) rather than re-deriving it. Base every field value only on what the schema, spec, or PRD states — never invent a config shape, but "I don't have a sibling example to copy" is not the same as "I have no source" when the schema itself is one Read call away.

2. **The per-target/per-provider data file** — `app/_data/<product>/<version>/providers.yaml`
   (here: `app/_data/ai-gateway/v2/providers.yaml`). This file has one entry per provider/target, each with a `capabilities:` map keyed by capability name. Read one existing sibling capability's block in full (e.g. `grep -n "batches:" -A6` on a couple of providers) to get the exact field set — it varies slightly by whether a provider truly supports it:

   ```yaml
   # Sibling shape for a SUPPORTED capability (real data — only for providers the PRD/spec names):
   skills:
     supported: true
     streaming: false
     upstream_path: '`/v1/skills`'
     model_example: 'n/a'
     min_version: '2.1'
     note:
       content: 'Only supports native format passthrough (openai-to-openai); no cross-provider translation.'

   # Sibling shape for an UNSUPPORTED capability (placeholder — every other provider, verbatim):
   skills:
     supported: false
     streaming: false
     model_example: ''
     min_version: ''
   ```

   Add a `skills:`-style block to **every** provider entry in the file, not just the ones the PRD names. Only the providers the PRD/spec explicitly scopes to get the real, `supported: true` block with actual field values (`upstream_path`, `min_version`, `note.content` if there's a real caveat to note) — copy those values from the PRD/spec text, don't invent them. Every other provider gets the placeholder block, byte-for-byte the same shape as an existing unsupported capability on that same provider (don't vary streaming/model_example/min_version formatting between providers).

   **On `min_version` specifically**: this field tracks the AI Gateway *product* version (the same `'2.0'`/`'2.1'`-style values used throughout this file), which is a different thing from a Kong-EE gateway PR number or a Jira ticket. If the PRD doesn't state the product version directly, check whether the spec diff itself bumps a version number (e.g. an OpenAPI `info.version` field going from `2.0.0` to `2.1.0` in the same diff) — in the one validated case here, that bump *did* correspond to the correct `min_version` value (`'2.1'`) for the newly-supported providers. Don't assume this correspondence holds for every product line without checking, but it's a real, non-obvious lead worth checking before defaulting to leaving the field blank — an unfilled `min_version` on a `supported: true` row is a bigger reader-facing gap than it looks, since every other row in this table has one.

3. **The shared rendering include** — `app/_includes/md/ai-gateway/v2/providers.md`
   (or the equivalent shared include for whatever entity's matrix this is).
   This file turns the YAML above into rendered tables, and has ~5 places
   that each need one parallel addition when a new capability key is added:
   - A `{%- capture <capability>_label -%}...{%- endcapture -%}` near the top, alongside the other capability labels.
   - The new key added to the `all_capability_keys` split-string list (used to build the "Upstream paths" summary table).
   - A new `{% when '<capability>' %}` branch in the `{% case cap %}` block right after it, setting `cap_label`/`cap_path_template`/`cap_description` for that row.
   - A new `{%- assign <capability>_note_num = 0 %}...{%- endif -%}` note-numbering line, and its `compare_<capability>_note_num` counterpart, alongside the others.
   - A new `{%- assign has_<capability> = false -%}` plus its `{%- if provider.capabilities.<capability>.supported or compare_provider.capabilities.<capability>.supported %}{% assign has_<capability> = true %}{% endif -%}` line.
   - **The full rendering section**: find the most similar existing sibling's `{% if has_<sibling> %} ... {%- endif -%}` block (e.g. `{% if has_files %}` at `app/_includes/md/ai-gateway/v2/providers.md:676-731` as of this writing — re-locate it by name if line numbers have drifted) and copy the **entire block**, substituting the sibling's capability name for the new one throughout (the table, the note-content lines, and the closing `{:.warning}` callout). Update the callout's own prose too (e.g. "Create a dedicated AI Model exclusively for batches and files" → "...for batches, files, and skills") — don't leave the old capability list stale in copied prose.
   - Insert the new block in the same relative position it'd have in `all_capability_keys` (after its nearest sibling, before the next section), so the page's capability ordering stays consistent.

4. **Any UI-walkthrough include that lists the enum's values in prose** —
   search `app/_includes/components/` for the entity's UI walkthrough (here:
   `entity_example/format/ui_ai.md`) for a sentence enumerating the same
   values (e.g. "options are Batches and Files") and extend it the same way
   ("...are Batches, Files, and Skills").

   **Don't skip this because the PRD says "no Konnect UI change."** A PRD's
   "no UI" non-goal almost always means *no new, dedicated UI surface* for
   the feature (e.g. no screen for browsing or uploading skill content) —
   it does not mean the *existing, generic* form that already enumerates
   this exact enum (here: the "New model" form's Capabilities checkbox
   list) should stay silently out of sync with an enum it already renders
   from. If the enum value is real and selectable via the API, the generic
   form that lists that enum's options needs to know about it too, even
   though nobody built anything new for it. Read the PRD's non-goal
   narrowly (what specific new UI is it ruling out?) rather than broadly
   (does the word "UI" appear near "no"?) before deciding this file is out
   of scope.

## After drafting

Grep the whole diff for the new capability name and check every hit renders
sensibly in context — it's easy to add the YAML block but miss one of the
five Liquid touchpoints in the shared include, and a missed touchpoint
fails silently (the capability just doesn't show up in that one summary
table) rather than erroring the build. Then run this repo's frontmatter
validator and, if the entity page's `{% entity_example %}` config uses
fields you're not fully sure about, cross-check them against the relevant
schema file under `app/_schemas/` before finalizing.
