# Plugin and reference page rules

## Example YAML wording

In `entity_examples` blocks and `app/_kong_plugins/*/examples/*.yaml`, check the `title:`, `description:`, `requirements:` and `extended_description:` fields. Suggest a rewrite when the text:

- is longer than needed,
- repeats the version (`min_version` already renders it),
- capitalizes a generic noun (control plane, data plane, plugin, header),
- spells an acronym only by its letters on first use,
- names an entity without linking it.

Not a violation: variable descriptions that already read as sentences.

## Schema field descriptions

A hand-written field description or type differs in form from its siblings ("to use" versus "used", `Int` versus `int`). Make them match. Not a violation: descriptions, tags or categories that are generated from the plugin source.

## Versions

A new field, parameter or behavior carries `{% new_in X %}`, and the page or example sets `min_version`. Do not add `{% new_in %}` to an example title or description when `min_version` is set.

## Links

The first mention in a section of a plugin, policy, endpoint, config field or entity that has a reference page links to it. Pick the closer anchor when one exists.

## Config identifiers

A literal config field, metric or CLI flag from the schema appears in plain prose, while sibling identifiers on the same page use code font. Use code font. Not a violation: algorithm and product names (SHA-256), words in headings.

## Values

Flag a default, limit, type or behavior only when the diff contradicts itself or contradicts a schema, spec or sibling page in the repo. Cite both as `file:line`.
