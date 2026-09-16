---
name: prose-drafting
description: >
  Draft or revise the prose of a page on developer.konghq.com — how-to, reference,
  or landing page, for any product. This covers sentence-level writing: turning an
  outline, brain dump, or a how-to-starter scaffold's placeholder sentences into
  real copy, and copy-editing or tightening prose that already exists. Use whenever
  someone asks to write, draft, revise, tighten, or copy-edit prose for one of these
  page types, or hands over an outline/brain dump to turn into finished copy. Do not
  use this for scaffolding a brand-new how-to's structure/frontmatter (use
  how-to-starter instead) or for the full domain-specific drafting flows owned by
  kong-identity-how-to, dcgw-terraform-how-to, or third-party-plugin — this skill
  only touches the prose of pages those skills already own, when asked to. Not for
  AI cookbooks (app/_cookbooks/), which have a different narrative structure this
  skill doesn't cover.
---

# Prose drafting

This skill owns the sentence-level writing on developer.konghq.com: turning an
outline or scaffold into real prose, and revising prose that already exists. It
does not scaffold whole-page structure or pick frontmatter/tools — that's
`how-to-starter`'s job for how-tos, and the domain skills' job for their
niches. On reference pages, which nothing else scaffolds, this skill also
drafts the Liquid blocks (`entity_examples`, config examples, generic steps)
that interweave with the prose, not just the sentences around them.

Read all three reference files before drafting or revising anything:
- `references/prose-mechanics.md` — sentence and word-level rules
- `references/page-shape.md` — what a how-to, reference, or landing page's
  content should actually contain, and how that differs by page type
- `references/editorial-judgment.md` — process/judgment calls made while
  drafting (source handling, terminology authority, scope calibration)

`app/contributing/style-guide.md` and `docs/ui-steps-standards.md` govern
voice, tone, grammar, and UI naming — read those too, since
`prose-mechanics.md` doesn't repeat what's already stated there.

**This skill is not a substitute for the writer understanding the feature.**
If the writer can't produce an outline, a brain dump, or a clear statement of
what they want changed and why, that's a sign the underlying feature isn't
understood well enough yet to write about — stop and say so rather than
filling the gap with invented structure or content.

## Step 1: Determine mode

Ask (or infer from what's already been shared): is this **new prose** (a new
page, a substantial new section, or filling in a scaffold's placeholder
sentences), or a **revision** (copy-editing or tightening prose that already
exists)? This determines which gate below applies.

## Step 2a: New prose — gate before drafting

Required before writing anything:

- **A new page** needs an outline of the major headings, plus a sentence or
  two per heading describing what belongs there — including whether a
  diagram, table, or specific example is wanted. A one-line "write about X"
  is not an outline.
- **A new section on an existing page** needs a sentence or two of intent —
  lighter than a full-page outline, but still content direction.
- **Any supporting source material** (spec, screenshots, PRD, Slack thread,
  ticket) linked or handed over — read it in full before drafting. See
  `references/editorial-judgment.md` for how to handle in-development specs,
  multiple spec variants, and PRD drift.
- If the writer can't produce the outline/intent or the source material, say
  so plainly and stop. Don't invent structure or facts to fill the gap.

**Draft the structure in Plan Mode.** Once the gate above is satisfied, enter
Claude Code's Plan Mode and lay out the section-by-section structure and key
talking points as the plan — not fully wordsmithed prose yet. This lets the
writer see and correct the shape (a missing section, a wrong emphasis, a
section that shouldn't exist) before any tokens go into full sentences. Only
write the actual file content once that plan is approved.

## Step 2b: Revision — gate before touching the file

No outline is required, but confirm two things before editing:

- **What specifically needs to change** — not just what prompted the
  request (a PR comment, a stale claim, a tone pass).
- **Roughly what the writer wants it to say instead.**

If either is missing, ask. "Make this better" isn't enough to start from.

## Step 3: Draft or flag

**New prose**: draft using `references/prose-mechanics.md` for sentence/word
rules, `references/page-shape.md` for what content the relevant page type
needs, and `references/editorial-judgment.md` for the judgment calls that
come up while writing (terminology authority, precedent-checking, scope).

**Revision**: read the existing passage in full, then flag anything that:
- violates a rule in `references/prose-mechanics.md`
- reads as an AI-tell (see that file's list)
- is missing the interpretive framing `references/page-shape.md` requires
  for that page type (most commonly: a reference page that's become a
  glorified schema dump with no opinion about when to use what)

Present each flagged item as three things: the problem, the fix, and a
one-line reason. Wait for go-ahead, then apply only what's confirmed — never
batch-rewrite a passage silently, even when every flagged item seems
obviously right.

## Step 4: After edits

Run `vale` on changed files. If frontmatter changed, run
`node tools/frontmatter-validator/index.js <files>`.
