# Updating Claude Code release known issues

Maintainer instructions for updating `## Confirmed issues` in `app/ai-gateway/claude-code-known-issues.md`.

## Adding and removing entries

When a tested Claude Code release fails in a provider mode, replace the paragraph that starts with "No tested" with one bullet per release and mode.
Include the release, the mode, what breaks, how to avoid it, and, once it ships, the release with the fix.

Keep the bullet after the fix ships so developers who still run the failing release see it.
Remove the bullet when Kong no longer supports the failing release.
