# How-to review rules

## UI steps

UI steps follow `docs/ui-steps-standards.md`: one action per step, location before action, and the exact UI label. Use these forms:

- Field: In the **Field** field, enter `value`.
- Checkbox: Select the **X** checkbox.
- Toggle: Enable or Disable **X**.
- Button: Click **X**.
- Dropdown: From the **X** dropdown menu, select "value".
- Icon: Click the X icon.

Do not move a label between bold and backticks. One-sentence inline UI summaries in an FAQ, table or prose are allowed.

## Runnable API examples

A fenced `curl` or raw HTTP example for a Konnect or Admin API call could use `{% konnect_api_request %}` or `{% control_plane_request %}`. Suggest the tag, in prose. Not a violation: pages with no on-prem and Konnect toggle for `control_plane_request`, or examples that pass a JSON file the tag parser would unescape.

## Validation

A how-to ends with a validation step that shows the reader how to confirm the result. Flag a how-to that adds a configuration or command change and has none.

## Examples that must be run

If a `curl`, `deck`, `kongctl`, `terraform` or `entity_examples` block changes and the diff or a repo file contradicts its expected result (a request expects 302 while the text and sibling pages say 200, or sample output shows two scopes while the text says one), flag it and cite both places as `file:line`. Do not flag an example only because you cannot run it.
