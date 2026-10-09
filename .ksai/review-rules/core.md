# Docs review rules: all pages

Comment only on changed lines, and only when you can write the exact replacement. Silence is the default. Most docs PRs need few or no comments.

## Always flag

- **Version markers.** A capability introduced in this PR carries `{% new_in X %}` and the page or example sets `min_version`. A new section for a capability introduced in this version carries `{% new_in X %}` when sibling sections on the page do (cite one). Remove stale markers on changed lines. Docs are evergreen: no versioned prose. Do not add `{% new_in %}` to an example title or description when `min_version` is set.

## Flag only when the sentence is wrong, ambiguous, or at least three sibling pages follow the convention

Post at most one finding per rule per PR. List repeats in the same comment.

- **Restated content.** A sentence, bullet or step repeats the heading, the sentence before it, an adjacent bullet, an earlier step in the series, or a link already given in the same section. Suggest deleting it. Not a violation: intentional repeats (`next_steps` versus `related_resources`), definitions the reader needs before the next step, partner-authored text.
- **No-new-information asides.** A "for example" that adds nothing, a sentence that announces what follows or sells ("Unlike the other guide, ..."), or a trailing clause with no action. Not a violation: example values the reader must replace, warnings, version differences.
- **Active voice.** A passive sentence with an obvious actor ("you", the product). Not a violation: passive that reads better, reference descriptions.
- **Voice.** "We", "our" or "let's" speaking for the doc, software that "sits", "holds", "arrives" or "wants", or gendered pronouns for example people. Use "you", the product, or a neutral name. Not a violation: quoted dialog, partner text, demo-setup sentences you are not changing.
- **Awkward sentences.** A sentence you can show is hard to parse (double negatives, fragments like "Prefer X", a noun that reads as a typo). Suggest a full rewrite with the same meaning.
- **Undefined terms.** A term, condition or location the next step needs is undefined, or a heading such as "Example" is ambiguous on a page with several. Use only facts on the page or a linked reference. Not a violation: partner prose, terms defined in the same section.
- **Consistent names.** One concept has two names on the same page, or a retired entity name is used (AI Provider versus AI Model Provider). Use the current name. Not a violation: a feature name and a sidebar label that differ on purpose.
- **Link to reference pages.** The first mention in a section of a policy, plugin, endpoint, config field or entity that has a reference page is not linked. Do not require links to pages that do not exist or on every mention.
- **Repeated content.** The same text is repeated across tabs, providers or pages. Suggest extracting an include, in prose. Not a violation: text inside a step list where an include would break numbering.

## Raise as a question, never a suggestion

- Whether to split a long step, reorder a section, or move a limitation under its own heading, when the order clearly fights the reader's sequence.
- A new option, field or step says what it does but not why. Write a suggestion only if the page or a linked reference states the reason.
- A step or block looks wrong for a platform in `works_on` (for example, an on-prem command on a Konnect-only page).

## Values and behavior

Flag a value, default, version claim, behavior or scope only when the diff contradicts itself or contradicts a file in the repo (schema, spec, `kong.conf` reference, a sibling page). Cite both locations as `file:line`. Do not ask the author to "confirm" something you cannot check.

## Do not flag

- Alternatives the author hedged and did not adopt.
- Combined product names with no site variable (for example "Konnect Catalog").
- "Size" as a verb, "simpler" in a direct comparison.
- Docs organized by product instead of reader task.
- `{% kong_config_table %}` where the page intentionally differs from `kong.conf`.
- Bold versus backticks for UI labels, and bold lead-in labels in bullets.
- Site variables in `description:` fields.
- `DECK_` prefix differences between prerequisites and `entity_examples`. Trailing whitespace in Markdown.
- Links whose target is added by a sibling PR.
- Partner-authored third-party plugin prose.
- Anything the Vale rules, the frontmatter validator or the link checker already report: positional words, dashes, "currently", "e.g.", product-name variables, frontmatter schema, broad link sweeps.
- Pre-existing issues on unchanged lines.
