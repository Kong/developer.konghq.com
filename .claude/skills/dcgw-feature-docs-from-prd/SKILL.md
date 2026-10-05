---
name: dcgw-feature-docs-from-prd
description: >
  Bootstraps Dedicated Cloud Gateways (DCGW) documentation changes straight
  from a PRD and spec/API diff (and any shared engineering PR), before or
  alongside implementation. DCGW has no entity collection like AI Gateway
  does — it's reference pages, a landing page, an index, and how-tos
  (Terraform and non-Terraform) instead, so this skill classifies the shape
  of the change and edits the right DCGW-specific files rather than following
  `feature-docs-from-prd`'s entity/support-matrix pattern. Use whenever
  someone hands over a PRD together with a spec change for a DCGW feature and
  asks to draft, bootstrap, or write the docs for it — a new cloud provider
  or resource/attachment kind, an entirely new feature category (the
  `managed-cache` launch is the precedent shape), or a reference-only change
  (new limitation, FAQ, architecture detail). Distinct from
  `dcgw-terraform-how-to` (drafts a single Terraform-based DCGW how-to from
  an interview, no PRD required — this skill hands off to it for the
  Terraform-provisionable slice of a feature) and from `feature-docs-from-prd`
  (the AI Gateway 2.0 entity/support-matrix equivalent of this skill).
---

# Drafting DCGW docs from a PRD + spec diff

This skill turns a PRD and a spec change into real edits to this repo's
Dedicated Cloud Gateways (DCGW) docs. Same sourcing discipline as
`feature-docs-from-prd`: every claim must trace back to the PRD, the spec
diff, or an explicit engineering PR — never an invented inference. The
DCGW-specific part is **which files are changed**: there's no entity collection or
support matrix here, just topic reference pages, a DCGW-wide reference page,
a landing page, an index, and a how-to split between Terraform and
non-Terraform.

## Step 1: Intake

Ask for all of this up front, in one message, if it wasn't already given:

1. **The PRD** — a Google Doc link, a pasted doc, or a plain description.
   Read it in full before doing anything else.
2. **The spec/API change** — an OpenAPI diff, a GitHub PR against the
   relevant spec repo, or a raw schema snippet.
3. **Any shared engineering PR** — the actual implementation. When it
   disagrees with the PRD, the spec diff and the engineering PR both outrank
   the PRD; the PRD describes intent, these describe what's actually being
   built.
4. **Anything else** (optional) — a Slack thread, existing docs for a
   similar prior feature. Ask rather than silently proceeding if the PRD
   references something you don't have.
5. **Any outline or brain dump the writer already has** for the page(s) they
   have in mind — most often the new/changed topic reference page. This is
   additive, not exhaustive: see the callout under Step 4.

Don't start drafting on partial material. If the PRD references an
implementation PR or ticket you don't have and can't fetch, say so and ask
whether to proceed without it or wait.

Read the PRD structurally the same way `feature-docs-from-prd` does: Problem
& motivation, Goals (what to document as supported), Non-goals (hard
exclusions, not throwaway color), Proposed solution (the field-level
mechanics), a rollout/coverage checklist if present, and Open Questions
(never resolve these yourself — leave the area undocumented or draft the
PRD's stated default and flag the open question in your summary).

**Spec location, DCGW-specific:** the shipped spec is
`api-specs/konnect/cloud-gateways/v2/openapi.yaml`. A new capability's diff
often shows up first in `platform-api`, which may hold dev/internal/public
variants — confirm which variant is authoritative before drafting, don't
assume the first copy found. If the feature hasn't shipped yet, a
handed-over spec file is the only source; don't go hunting this repo for a
stale copy instead. Flag `x-enum-dev`/`x-enum-internal`/feature-flagged
surfaces before drafting anything public, same as `feature-docs-from-prd`
Step 4.

## Step 2: Classify the shape of the change

No entity/support-matrix pattern exists for DCGW. Read
`references/dcgw-doc-map.md` for the full file map, then classify into one
of:

- **(a) New provider or new resource/attachment kind for an existing feature
  category** (a new peering type, a new provider added to managed cache). Touches the
  matching topic reference page (picked by feature, not guessed — see the
  doc map), `app/dedicated-cloud-gateways/reference.md` if it lists
  supported providers/features, and the landing page's cards if it
  advertises provider coverage. Also needs a new how-to (Step 3).
- **(b) An entirely new feature category** (no existing topic page or how-to
  family — the `managed-cache` launch is the precedent shape). New reference
  content (check existing precedent before inventing a new top-level page vs.
  a new section on an existing one), a new landing page section, and a new
  how-to.
- **(c) Reference-only change** — a new limitation, FAQ, or architecture
  detail with no new how-to. Identify and edit only the relevant
  reference/landing page(s).

**`app/dedicated-cloud-gateways/reference.md` almost always needs a touch.**
It follows a mixed, size-driven pattern (see the doc map for both shapes
with real examples): a small, self-contained feature gets a full section
living only on this page; a bigger feature gets a short section here that
links out to its own dedicated topic page. Match existing precedent, don't
default to one shape.

**Index entry.** Any new or renamed page needs a line in
`app/_indices/gateway.yaml`'s "Dedicated Cloud Gateways" section — match the
existing entry format (see the doc map).

## Step 3: Terraform vs. non-Terraform how-to split

When Step 2 calls for a new or revised how-to:

- **Terraform-provisionable** → hand off entirely to `dcgw-terraform-how-to`
  with the collected feature details (provider, resource, attachment kind,
  cloud-side steps). That skill runs its own interview and drafts the file;
  this skill does not draft Terraform how-to content itself.
- **Not Terraform-provisionable** (API/UI-driven — an Entra-consent-only
  step, a UI-only toggle) → hand off to `how-to-starter` to scaffold it, same
  as any other new how-to, but pass it the DCGW-specific context so the
  scaffold isn't generic: the frontmatter/structure conventions in
  `references/dcgw-doc-map.md` (prereqs includes, `{% konnect_api_request %}`
  blocks, a Validate step) and any relevant conventions from
  `dcgw-terraform-how-to`'s `references/dcgw-terraform-patterns.md`. This
  skill still owns filling in the real prose afterward (Step 5), the same as
  it does for the reference/landing page edits.

This skill always owns the surrounding reference/landing page edits from
Step 2, regardless of which branch the how-to takes.

## Step 4: Outline gate before drafting

For every reference/landing page edit, and for the non-Terraform how-to once
`how-to-starter` hands back its scaffold (Terraform how-tos are
`dcgw-terraform-how-to`'s own gate to run): **enter Claude Code's actual Plan
Mode** and lay out the heading list with a sentence of intent per heading —
not full prose — as the plan, exactly as `prose-drafting`'s Step 2a does.
Only write real sentences once that plan is approved.

**Writer outlines are additive, not exhaustive.** Use any outline the writer
handed over in Step 1 as-is for the pages it covers. But also suggest, in
this same plan, any additional pages or sections Step 2/3's classification
implies that the writer didn't mention (a landing page row, a `reference.md`
blurb, an index entry) — label these clearly as this skill's suggestion, not
something the writer asked for. Likewise, if the writer's own outline looks
like it's missing something the source material implies, flag it as a
suggested addition in the same plan rather than silently adding or dropping
it.

Before presentation, check `app/contributing/index.md`'s "Page types" and
"Core tenets" sections (and the style guide it points to) for structural
guidance that applies — notably, grouping content by intent rather than by
feature — so the suggested heading structure follows house conventions
rather than mirroring the PRD's own organization.

## Step 5: Draft

Follow `prose-drafting`'s reference files
(`.claude/skills/prose-drafting/references/prose-mechanics.md`,
`references/page-shape.md`, `references/editorial-judgment.md`) for sentence
mechanics and page shape rather than restating those rules here. Never
fabricate a per-provider/per-region support claim — use the sibling page's
exact "not supported" placeholder phrasing (see the doc map for a real
example), same discipline as `feature-docs-from-prd` Step 6.

## Step 6: Verify against style

Once everything is drafted (reference/landing pages and index entries here,
Terraform how-tos via `dcgw-terraform-how-to`, non-Terraform how-tos
scaffolded by `how-to-starter` and drafted here), invoke `prose-drafting` in
revision mode across all touched files to catch AI-tells and
mechanics/page-shape gaps this skill's own drafting might miss.

## Step 7: Summarize what you drafted and what's still open

End with: which files you changed, which claims came from the PRD vs. the
spec vs. the engineering PR vs. an explicit placeholder, any Open Questions
from the PRD you left unresolved, and whether Step 1's dev/internal-gating flag
applies.

## After edits

Run `vale` on changed files. If frontmatter changed, run
`node tools/frontmatter-validator/index.js <files>`.
