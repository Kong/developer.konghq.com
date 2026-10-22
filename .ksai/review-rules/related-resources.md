# Docs review rules: related resources

Applies to entries added or changed in the frontmatter `related_resources` list, and in a landing page `type: related_resources` block. Comment only on changed entries, and only when you can write the exact replacement. Silence is the default.

## Always flag

- **Self-link.** An entry's `url` points at the page itself, including a same-page `#anchor`. The page's URL is its frontmatter `permalink` when set, otherwise its path under `app/` (`index.md` maps to its directory, a trailing slash is ignored). Suggest deleting the entry.
- **Duplicate URL.** Two entries in the same list share a `url`, whatever the `text`. Suggest deleting the later one. Not a violation: the same page linked once under `next_steps` and once under `related_resources`.

Post at most one finding per rule per PR. List every affected entry in the same comment.

## Raise as a question, never a suggestion

- **Tangential entry.** The target page is not about the topic in this page's title, description or tldr. Typical cases: a generic landing page, a different product's page, a broad overview, or a topic this page only mentions in passing. Ask whether the reader of this page needs it, and name what the target page covers. Raise it only after reading the target page or its frontmatter. Never guess from the URL alone.
- Raise at most three tangential questions per page.

## Flag only when you can show it is wrong

- **Link text that does not describe the target.** The `text` names a different page or feature than the target covers, or a how-to is described as a reference. Suggest corrected text from the target's title.

## Not a violation

- The parent reference page or landing page for the product area the page belongs to.
- The entity, policy or plugin the page configures.
- The next logical guide in a series, or the prerequisite guide.
- External links to the specification or documentation of a tool, protocol or provider the page uses.
- Liquid in `text` (for example `{{site.base_gateway}}`). Compare only `url`.
- Entries on unchanged lines.
- Links whose target is added by a sibling PR.
- Broken links and missing trailing slashes. The link checker and the build report those.
