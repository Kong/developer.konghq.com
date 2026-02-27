---
applyTo: "changelog/**/*.yml"
---

# Copilot Instructions for Changelog Reviews

These instructions are intended for GitHub Copilot (or any automated reviewer) when reviewing
files under the `kong-ee/changelog` directory. They are **not** global; they only apply to
entries inside that directory.

## Allowed file format
Each changelog entry must be a YAML (`.yml`) file containing exactly the following fields:

```yaml
message: # "Description of your change" (required)
type: # One of "feature", "bugfix", "dependency", "deprecation", "breaking_change", "performance" (required)
scope: # One of "Core", "Plugin", "PDK", "Admin API", "Performance", "Configuration", "Clustering", "Portal", "CLI Command" (optional)
plugins: 
  - plugin-name # If the change concerns a plugin, list the plugin(s) here (required if `scope: Plugin`)
```

If `scope: Plugin`, the `plugin:` field is required. It is not necessary with any other scope.

### Forbidden keys
- `prs` or `jiras` may **not** appear in changelogs. The ticket number belongs in the
  commit message or PR description instead.

## Message style guidelines
The `message` field is the piece most likely to violate rules.  Apply the following checks:

1. **Past tense**: Write as if the change has already been made. Use past tense verbs, e.g. “Added support for …”, “Fixed an issue where …”.
2. **Capitalization**: Start the message with a capital letter.
3. **Structure**: Start with a verb and end with a period.
4. **Spelling**: Use correct English spelling.
5. **Pronouns**: When referring to a person using the software, say “you”/“your”, not “user”/
   “their”.
6. **Bugfix phrasing**:
   * Fixes that restore previous behaviour: “Fixed an issue where …”.
   * Fixes that change behaviour: describe how it works now, e.g. “[feature] now does …”.
7. **Breaking changes**: Explain what changed and how a user must adjust their
   environment.
8. **Deprecations/removals**: Explain what is being deprecated or removed and give a
   timeline.
9. **Grammar**: Use correct grammar and punctuation.
10. **Formatting**: Use markdown formatting where appropriate, e.g. backticks for code elements.
11. **Clarity**: Write clear, concise messages that are easy to understand.
