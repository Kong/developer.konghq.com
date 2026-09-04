# Example YAML field reference

Annotated reference for `app/_kong_plugins/<plugin-slug>/examples/<name>.yaml`.
The base scaffold template lives at `tools/scaffold-plugin/templates/examples/example.yaml`,
this file explains every field in more depth.

---

## Full annotated template

```yaml
# REQUIRED. One line, one sentence, no markdown formatting.
# Used for search metadata. Rendered on the page ONLY if extended_description is absent.
description: 'Cache responses to GET requests using the authenticated Principal to compose the cache key.'

# OPTIONAL. Multi-line, markdown allowed. If present, this fully REPLACES description
# on the rendered page; it does not render alongside it.
# Must restate everything description says, then add the extra detail. Never write it
# as a separate/additive block, or the reader misses whatever is only in description.
# extended_description: |
#   Cache responses to GET requests using the authenticated Principal to compose the
#   cache key, instead of the Consumer's UUID.
#
#   [Add the extra context here: why you'd choose this, what it assumes, trade-offs.]

# REQUIRED. Title case. Describes the scenario, not just the plugin name.
title: 'Cache by Principal'

# REQUIRED. Controls display order among sibling examples in the same directory.
# HIGHER weight sorts FIRST. 900 is the conventional primary/default example.
weight: 900

# OPTIONAL. Plain-sentence prerequisites. Markdown links allowed. Omit the whole key
# if there are none beyond "the plugin is installed".
# requirements:
#   - "[Authentication](/gateway/authentication/) configured"

# OPTIONAL. Only for values the reader must supply themselves (credentials, hostnames,
# IDs). Key: kebab-case. value: $UPPER_SNAKE_CASE for an env-var placeholder, or a
# hardcoded default for a stable value. description: one sentence.
# Reference inside config with ${variable-key}. Omit the whole key if nothing is
# reader-specific.
# variables:
#   directory-name:
#     value: $DIRECTORY_NAME
#     description: The name of the Kong Identity directory to look up principals in.

# REQUIRED. Mirror the plugin's schema field names and nesting exactly.
# Do not include name/enabled/route/service association; the renderer adds scope.
# Don't include fields already at their schema default unless it clarifies the example.
config:
  response_code:
  - 200
  request_method:
  - GET
  cache_ttl: 300
  cache_by_principal: true
  strategy: memory

# REQUIRED. Never omit. Never assume it inherits the plugin's own baseline min_version
# from index.md; write it explicitly every time.
# If this example only uses baseline fields, set it to the plugin's own baseline version.
# If it demonstrates a field newer than baseline, set it to that field's introduction
# version (check the schema directory it first appears in, or ask the user).
min_version:
  gateway: '3.16'

# REQUIRED. Which tool tabs to show for configuring this example: deck, admin-api,
# konnect-api, kic, terraform. Don't default to all five without checking; drop any
# tool that genuinely can't configure this scenario (for example a Redis-only strategy
# or a streamed/custom plugin unsupported in Konnect or DB-less mode).
tools:
  - deck
  - admin-api
  - konnect-api
  - kic
  - terraform
```
# Optional: Use this to group plugin examples by a category. See app/_kong_plugins/openid-connect/examples/override-jwks-endpoint.yaml for an example. The categories are then outlined in the frontmatter of the plugin's _index.md file like the following: 
# examples_groups:
#  - slug: identity
#    text: Using Kong Identity

# group: <name of group>
---

## Naming conventions

**File name**: `<verb-or-noun-phrase>-<what-it-does>.yaml`, describing the scenario, not
restating the plugin name.

- `cache-by-principal.yaml`, `allow-consumer-groups.yaml`, `monitor-mode.yaml`
- Not `example.yaml` or `<plugin-slug>.yaml`

**Weight**: `900` for the primary/default example. Since higher weight sorts first,
every other example needs a lower value: commonly stepped down by 100 (`800`, `700`, ...),
though smaller steps (`899`, `898`, ...) are also seen. What matters is that the example
you consider primary has the highest weight in the directory. Ties are fine across
examples that belong to different display groups.

---

## Multi-example patterns

When a plugin has distinct modes, postures, or strategies, create one file per scenario
rather than cramming alternatives into one file's `extended_description`.

**Two modes**: `monitor-mode.yaml` (weight 900, non-blocking posture) and
`blocking-mode.yaml` (weight 800 or 899, enforcement posture). Note the latency or
enforcement trade-off in the blocking example's `extended_description`.

**Two strategies**: `memory-strategy.yaml` (weight 900) and `redis-strategy.yaml`
(weight 800), each setting the relevant `strategy` value and only the config relevant
to that strategy.

---

## What NOT to include

- Do not include `name:` or `enabled:` at the top level. The renderer adds these.
- Do not include Route or Service association. Examples show plugin config only.
- Do not include credentials as literal values. Always use `${variable}` references
  backed by a `variables` entry.
- Do not add fields already at their schema default unless it makes the example clearer.
- Do not read or hand-edit `reference.md` or `changelog.json` in the plugin's directory.
  Both are autogenerated.
