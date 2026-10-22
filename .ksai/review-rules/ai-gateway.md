# AI Gateway page rules

## Names

- Use the current v2 entity names. A retired name (AI Provider where the current entity is AI Model Provider) is a finding. Suggest the current name.
- A Gateway or AI Gateway entity (AI Model, AI Model Provider, AI Consumer, Policy, Consumer, Route, Service) is capitalized elsewhere on the page but not on the changed line. Match the page. Not a violation: generic use ("principals"), or pages that lowercase it everywhere.
- Generic nouns stay lowercase mid-sentence: control plane, data plane, plugin, header, token plan, authorization server, and deployment (Kubernetes). Not a violation: Kong entity names that name the entity, product and UI labels, headings in title case.

## Examples

- Output-only blocks end with `{:.no-copy-code}` (see the output blocks rule).
- A new capability sets `min_version` on the page or example.

## Version markers

- Do not add `{% new_in %}` badges to AI Gateway pages, and do not suggest them. This overrides the version marker rules in the Core and Plugins and references packs. Flag an existing `{% new_in %}` on a changed line as a finding and suggest removing it.
