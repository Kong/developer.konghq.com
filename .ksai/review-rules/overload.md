# Information overload

Applies to hand-written concept and reference pages (`content_type: reference` or `concept`). Skip the page if it is a how-to, a plugin or entity page, a changelog, a glossary, or a lookup page whose length comes from one large table or schema-driven field list.

Post at most one finding per PR. Raise it as a question, never a rewrite.

## When to fire

Fire only when the PR makes a significant edit to the page. That means it adds or substantially rewrites a section: a new H2 or H3, roughly 150 or more added words of prose, a new code block, or a new tab group.

Do not fire on typo fixes, wording or link tweaks, renames, or small edits that leave the page structure unchanged. Do not fire when the PR only moves existing content.

## What counts as overloaded

Judge the page as it reads after the PR. Flag when it has at least one size signal and at least one mixed-jobs signal.

**Size signals** (the 95th percentile of reference pages is about 2,100 words and 18 headings):
- More than about 2,000 words of prose, not counting code blocks.
- More than 18 headings in total, or more than 8 H2s.
- More than 10 H3s on the page.

**Mixed-jobs signals.** The page does three or more of these jobs at once:
- Explains a concept.
- Provides a lookup table or field list.
- Helps the reader decide between options ("when to use X instead of Y").
- Describes behavior per product or platform.
- Walks through configuration, with steps or tabs.
- Lists limitations.

## How to report

Name the signals you measured, for example "about 3,400 words, 19 headings, and the page explains the concept, compares options, and walks through setup for four credential types". Ask whether the page should be split.

Suggest a split point only when the page itself supports it, such as step-by-step configuration that could be a how-to, or a decision guide that could stand alone. Do not write replacement text.

## Do not flag

- Length that existed before the PR when the diff adds no section.
- Pages that are long because they are generated or table-driven.
- Partner-authored third-party plugin prose.
- A page the PR is already splitting or trimming.
