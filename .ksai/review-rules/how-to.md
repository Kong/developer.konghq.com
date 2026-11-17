# How-to review rules

## UI steps

UI steps follow `docs/ui-steps-standards.md`: one action per step, location before action, and the exact UI label. Use these forms:

- Field: In the **Field** field, enter `value`.
- Checkbox: Select the **X** checkbox.
- Toggle: Enable or Disable **X**.
- Button: Click **X**.
- Dropdown: From the **X** dropdown menu, select "value".
- Icon: Click the X icon.
- Tab: Click the **Tab name** tab.
Do not move a label between bold and backticks. One-sentence inline UI summaries in an FAQ, table or prose are allowed.

## Runnable API examples

A fenced `curl` or raw HTTP example for a Konnect or Admin API call could use `{% konnect_api_request %}` or `{% control_plane_request %}`. Suggest the tag, in prose. Not a violation: pages with no on-prem and Konnect toggle for `control_plane_request`, or examples that pass a JSON file the tag parser would unescape.

## Command and API-call lead-ins

The sentence before a `curl`, `deck`, `kongctl`, `terraform` or API block names the resource it creates or changes and, briefly, why. Flag "Run the following:", "Run this command:" and "Use the following request:" when the block shows what to name. Suggest the lead-in, for example "Create an auth server using the [`/v1/auth-servers` endpoint](...):". Not a violation: a lead-in that already names the resource.

## Branching

A how-to is linear. Raise as a question, never a suggestion, any "Option 1 / Option 2", "Alternatively" or "If you prefer X, do Y instead" inside numbered steps. Ask whether the alternative belongs on the reference page's "Configure" section, or as a note or FAQ. Not a violation: a tool switch that the page's `tools` frontmatter renders as tabs, and a prerequisite choice made once.

## Validation

A how-to ends with a validation step that shows the reader how to confirm the result. Flag a how-to that adds a configuration or command change and has none.

## Examples that must be run

If a `curl`, `deck`, `kongctl`, `terraform` or `entity_examples` block changes and the diff or a repo file contradicts its expected result (a request expects 302 while the text and sibling pages say 200, or sample output shows two scopes while the text says one), flag it and cite both places as `file:line`. Do not flag an example only because you cannot run it.
