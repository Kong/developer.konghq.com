---
name: feature-docs-from-prd
description: >
  Bootstraps documentation changes for a feature straight from its PRD and
  spec/API diff, before or alongside implementation — drafting new content
  and editing existing reference pages using only what the PRD and spec
  actually say, never fabricating detail they don't support. Use this
  whenever someone hands over a PRD (a Google Doc, a pasted doc, or a link)
  together with a spec change (an OpenAPI diff, a GitHub PR against an API
  spec repo, or a schema snippet) and asks to draft, bootstrap, or write the
  docs for it — phrases like "draft docs for this PRD", "document this
  feature", "write docs for PR #NNNN", "add docs for the new X
  capability/field/enum value", or "here's the PRD and the spec change, can
  you get a docs PR going." Distinct from `how-to-starter` (scaffolds a
  brand-new tutorial from a use case, no PRD/spec required) and from
  `ai-gateway-migration-review` (audits existing docs for correctness, not
  drafting new content from a product spec).
---

# Drafting docs from a PRD + spec diff

This skill turns a PRD and a spec change into real edits to this repo's
docs — before the feature has necessarily shipped, sometimes before it's
even public. That means the discipline here is stricter than normal
drafting: every claim in the output must trace back to something the PRD or
spec actually says. A plausible-sounding sentence that isn't sourced from
the material you were handed is a fabrication, not a draft.

This is a new skill (built and validated against exactly one real case —
adding a `skills` capability to the AI Gateway `AIGatewayModelAPI`, from
`Kong/platform-api#3398` and its PRD). Expect to extend it as more PRDs come
through with shapes this version hasn't seen yet.

## Step 1: Intake

Ask for all of this up front, in one message, if it wasn't already given:

1. **The PRD** — a Google Doc link, a pasted doc, or a plain description. Read it in full before doing anything else.
2. **The spec/API change** — an OpenAPI diff, a GitHub PR against the relevant spec repo (e.g. `Kong/platform-api`), or a raw schema snippet. This is the source of truth for what's actually being added — the PRD describes intent, the spec describes the real, present-tense surface.
3. **Anything else** — an implementation PR (e.g. a gateway-side PR the PRD references), a Slack thread, existing docs for a similar prior feature. Not required, but ask rather than silently proceeding without it if the PRD references something you don't have.

Don't start drafting on partial material. If the PRD references an
implementation PR or a Jira ticket you don't have and can't fetch, say so
and ask whether to proceed without it or wait.

## Step 2: Read the PRD structurally

Don't skim a PRD as prose — pull out its actual sections and treat each one
as a specific kind of instruction, not just context:

- **Problem & motivation** — why this exists. Useful for framing an intro paragraph, not for inventing scope.
- **Goals** — what to document as real, supported behavior.
- **Non-goals** — exclusion rules, not throwaway color. If the PRD says "not supporting provider X" or "no UI for this," that's a hard boundary on what you write — don't imply support or a UI path that the PRD explicitly disclaims.
- **Proposed solution** — the actual mechanics (request/response transforms, new route types, new enum values, field-level detail). This is usually where the literal facts you need for tables/examples live.
- **A rollout/coverage checklist**, if present (this PRD's was called "CP-first coverage" — rollout default, breaking-change class, cross-product impact, UI change, consumer-tooling timeline). Read this even though it looks like an internal review checklist — it tells you things that directly affect what you can claim: whether this is opt-in or on-by-default, whether there's a Konnect UI for it yet (if not, don't write UI steps for it), which other products it does *not* touch.
- **Open questions** — never resolve these yourself. Either leave the related area undocumented, or draft it for the PRD's stated default while flagging the open question in your summary back to the human. Don't guess an answer and write it as settled fact.

## Step 3: Cross-check every claim against the spec diff

Same discipline as testing a doc against a live API (see `aigw-doc-testing`
if this is AI Gateway-specific): before writing that a field, value, or
provider is supported, confirm the spec diff actually adds it. The PRD
describes *intent*; the spec diff is what's *actually being built*. If they
disagree or the spec is narrower than the PRD's ambition, document the
spec's actual surface and flag the gap rather than documenting the PRD's
aspiration as if it were shipped.

## Step 4: Flag dev/internal-gated specs before drafting public docs

If the spec change marks the new surface as internal-only or dev-only
(OpenAPI extensions like `x-enum-dev`, `x-enum-internal`, a feature flag, or
prose saying the gateway-side implementation hasn't shipped yet), stop and
tell the human before drafting content for the public docs site. Whether a
not-yet-GA capability should be documented publicly now, staged behind
`published: false`, or held until GA is a publish-timing call for a person
to make — don't resolve it by drafting either way silently.

## Step 5: Classify the shape of the change

This determines which files move and which pattern to follow:

- **A new value added to an existing capability/enum on an entity that
  already has a per-provider (or per-target) support matrix** — this is the
  one validated pattern this skill has. Follow
  `references/capability-matrix-pattern.md` exactly; it names the real
  files, the real block shapes, and the rule for which providers get real
  data versus the placeholder shape.
- **A brand-new how-to guide** (new use case, no existing page to extend) —
  this isn't what this skill is for. Hand off to `how-to-starter` instead;
  it scaffolds new tutorials from a use case and source material, which is
  a different job than editing existing reference content from a PRD.
- **Anything else** (a new entity type, a schema-only change with no prose
  implications, a deprecation) — there's no proven playbook for this yet.
  Read 2-3 sibling pages for the closest existing pattern in this repo,
  draft conservatively, and say explicitly in your summary that this change
  shape hasn't been validated against a real example — that's a signal for
  whoever reviews the draft to look closer, and a candidate for the next
  round of iterating on this skill.

## Step 6: Never fabricate a per-provider or per-target support value

If the PRD/spec doesn't explicitly say a given provider, target, or format
supports the new thing, it doesn't. Use the sibling capability's exact
"not supported" placeholder shape for it — the same discipline
`how-to-starter` uses for frontmatter it can't infer (`<!-- TODO -->` rather
than a guess). A silently-invented `supported: true` is worse than an
admitted gap, because it reads as a verified fact to anyone who trusts the
docs.

## Step 7: Summarize what you drafted and what's still open

End with: which files you changed, which claims came from the PRD vs. the
spec vs. an explicit placeholder, any Open Questions from the PRD you left
unresolved, and whether Step 4's dev/internal-gating flag applies. The
person reviewing your draft should be able to tell, from your summary
alone, exactly which parts are sourced fact and which parts need their
judgment call.
