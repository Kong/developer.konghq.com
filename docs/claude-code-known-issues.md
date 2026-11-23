# Updating Claude Code release known issues

Maintainer instructions for updating `## Confirmed issues` in `app/ai-gateway/claude-code-known-issues.md`.

## Adding and removing entries

When a tested Claude Code release fails in a provider mode, replace the sentence that starts with "No tested" with one bullet per release and mode.
Keep the second sentence about releases that might not have a test result yet, and place the bullets before that sentence.

Each bullet must include the release, the provider mode, what breaks, and how to avoid it:

```markdown
* **2.1.330 (Microsoft Foundry)**: Tool calls fail when the request includes `output_config`.
  Roll back to `2.1.329` until a fix ships.
```

When a fix ships, replace the last line with `Update to 2.1.331 or later, which fixes the issue.` (using the fixed release number).
Keep each bullet after the fix ships so developers who still run the failing release see it.
Remove a bullet when the failing release is older than the oldest Claude Code release that `kong-harnesses doctor` accepts.
When you remove the last bullet, restore the sentence:

```markdown
No tested {{ site.claude_code }} release has a confirmed issue in the provider modes that Kong tests.
```
