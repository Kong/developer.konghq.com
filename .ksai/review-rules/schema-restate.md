# Don't restate the schema

Applies to pages that already render a schema. These are Gateway, AI Gateway and Event Gateway entity pages (`{% entity_schema %}`), plugin and policy pages with generated schema or config tables, and pages that end in `{% kong_config_table %}` or `{% event_gateway_conf %}`.

The site renders the schema. Prose that repeats it is redundant, and it goes stale when the schema changes.

Comment only on changed lines. Silence is the default. Post at most one finding per PR and list every repeat in the same comment.

## Flag when the schema already says it

A changed sentence, bullet, table row or example description states a fact about a field that the rendered schema already conveys: name, type, default, required status, enum values, or its one-line description. Cite the schema location as `file:line`, next to the page line. The location is the page's `schema.json`, the entity schema, or the spec. Suggest deleting the sentence. If part of it adds information, suggest keeping only the part the schema lacks.

Typical shapes:
- "The `timeout` field is an integer that defaults to 60000."
- "Set `mode` to one of `strict`, `lenient` or `off`."
- "`name` is required and must be a string."
- A hand-written table or list that enumerates fields, types or defaults.

If you cannot cite the schema line, do not comment.

## Not a violation

Prose that says what the schema does not:
- When and why to use a setting, or how to choose between values.
- How fields interact, or a constraint that spans fields ("`a` and `b` must both be set").
- Runtime behavior, ordering, side effects and gotchas.
- Examples, and the lead-in that says what an example shows.
- A first mention that defines a field the reader needs before the next step, if the schema description is a one-word label or empty.

Also not a violation:
- Generated or auto-edited files: `schema.json`, `changelog.json`, `app/_references/**`.
- How-to steps that name a field because the reader must set it.
- Partner-authored third-party plugin prose.

## Raise as a question, never a suggestion

- A reference page change adds a new section that lists every field or mode and gives no guidance on when to pick one. Ask if the page can say when and why to choose each, and name what the schema does not cover.
- A schema description looks wrong or unclear next to the page prose. Ask the author to fix it in the schema source, not to cover for it in prose.
