# UI inventory lists

Applies to prose added or changed by the PR. Comment only on changed lines.

## Flag

A sentence or list whose only job is to inventory what a UI screen shows or lets you do: its columns, fields, filters, sort options, tabs, or available actions. Examples:

- "The key list shows each key's name, holder, type, expiry, and creation date."
- "You can search the list by name, filter it by type, and delete keys one at a time."
- "The identity providers list shows each provider's name, issuer URL, and last update date."

These lists add nothing that the reader cannot see on screen. They go stale whenever the UI changes. What a reader sees can also depend on their role.

Suggest deleting the sentence or list. If deleting it leaves a lead-in sentence ending in a colon, or an empty section, include that in the suggestion.

Post at most one finding per page. List every affected line in the same comment.

## Not a violation

- A table or list that adds information the UI does not show. For example: what each field means, valid values, defaults, limits, or which role can see it.
- A UI detail the reader needs to act or decide. For example: a limit ("Rotating a key is not supported"), a consequence, or where to find something non-obvious ("open the user's details and go to **Remote credentials**").
- UI steps in a how-to or in a `ui` tab that tell the reader which field to fill in or which button to click. Those follow `docs/ui-steps-standards.md`.
- Field and parameter lists for an API, a schema, a CLI, or a configuration file.
- Lines the PR did not change.
