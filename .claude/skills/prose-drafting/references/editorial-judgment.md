# Editorial judgment

Process and judgment calls that come up while drafting or revising, distinct
from sentence-level rules (`prose-mechanics.md`) or content shape
(`page-shape.md`). These patterns come from recurring corrections across real
drafting sessions — not hypothetical concerns.

## Source verification

Fetch and fully read every linked spec before writing a concrete technical
claim. When a repo or directory has multiple spec/build variants, confirm
which one is authoritative before relying on it — don't assume the first
copy found is the right one. When a claim can't be verified against a real
source, say "I don't know" rather than writing something plausible-sounding.

**In development specs**: if the writer directly hands over a spec — for example, one
still living in an in-development location like `platform-api`, not yet in
this repo's `api-specs/` — treat that handed file as authoritative and don't
go looking for a copy in this repo instead. A feature that hasn't shipped yet
has no repo copy to cross-check against; the handed file is the only source
that exists. Before deciding whether to cross-check a claim against this
repo's specs, confirm which situation applies: a shipped feature (the repo
spec is authoritative, cross-check freely) or one still in development (the
writer's handed material is the only source, and searching this repo for a
different copy will either find nothing or find something stale).

## PRD drift

PRDs and design docs often drift from what a feature actually became by
ship time. When starting from a PRD or similar planning document, ask the
writer or PM upfront whether known drift exists, rather than discovering it
mid-draft. This is especially worth asking for a feature that's still stabilizing.

## Citation readiness

Be ready to state exactly where a specific claim came from when asked. A
writer verifying a draft will sometimes not recognize where something in it
originated and want to check it against a human source — being able to point
to the exact spec, Slack thread, or doc section a claim traces back to is
part of making that verification possible.

## Terminology authority, in judgment form

When a page's own Liquid variables or established naming conventions
conflict with how an external document (a PRD, a Slack thread) phrases the
same thing, the page's own conventions win. External docs supply facts about
what a feature does; they don't set house style for what to call it.

## No new structural section without precedent

Before adding a section type that isn't already part of the common pattern
for that page type (see `page-shape.md`), check whether the same kind of
section already exists elsewhere in the same page type across the repo. If
there's no precedent, ask rather than inventing one — a section type that
looks reasonable in isolation can still be inconsistent with how every other
page of that type is built. FLAGGING

## API-primacy calibration

For a product with a real API, default to full API-primacy — including
prerequisites, not just the visible body steps — unless the feature is
genuinely UI-only. Don't treat a prerequisite or a linked setup step as
exempt from this by default just because it's not part of the main step
sequence; the same preference for reproducible, API-driven steps applies
there too.

## UI steps without screenshots

Missing screenshot coverage for a UI step is a stop, not something to
placeholder past with a TODO and continue. Pause and ask for the screenshot
rather than guessing at UI element labels or layout.

## Scope calibration

When a flagged issue turns out to recur elsewhere in the same page or the
same page set, check with the writer if you should extend the fix to cover all
of it rather than stopping at the
literally named file or line. The inverse also applies: don't invent new
sections, cross-links, or speculative content beyond what was actually
asked for, even when it seems like a reasonable addition — flag it and ask
instead of expanding scope unilaterally.
