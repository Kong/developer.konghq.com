# AI Gateway docs skills — quick reference

## Which one do I want?

| Situation | Skill |
|---|---|
| "I don't know where to start / where's X" | `aigw-doc-resources` |
| Feature has a PRD + spec, nothing's written yet | `feature-docs-from-prd` |
| A v1 doc needs to become a v2 doc | draft by hand using `aigw-doc-resources`'s pointers, then check it with `ai-gateway-migration-review` |
| Checking an existing file for v1→v2 correctness issues | `ai-gateway-migration-review` |
| "Does this doc actually work against a real gateway?" | `aigw-doc-testing` |
| Brand-new how-to, no existing page to build on, not AI Gateway-specific | `how-to-starter` |



- **`feature-docs-from-prd`** — Hand it a PRD (Google Doc or pasted) plus
  the spec/API diff for the feature, and it drafts the actual doc changes —
  new content and edits to existing reference pages — across the docs site,
  using only what you gave it. Use this when a feature is still in the
  PRD/spec stage and nothing's written yet. It asks up front if you're
  missing the spec diff or other material, and it'll refuse to invent
  details the PRD/spec doesn't state (flags a gap instead of guessing).

- **`ai-gateway-migration-review`** — Point it at an existing AI Gateway
  file (or all of them) and tell it report mode or edit mode, and it
  audits/fixes v1 → v2 migration correctness: frontmatter shape,
  plugin → Policy renaming, entity naming, stale links to unmigrated v1
  pages, filename/permalink conventions. **Note:** this reviews and fixes a
  file that already exists — it does not, by itself, take an old v1 doc and
  a spec and produce a brand-new v2 doc from scratch. That "migrate this
  doc" workflow (what actually happened for the RAG Injector doc this
  session) is: read the old doc for what to preserve, check the current
  policy schema for what changed, draft the new file, then run this skill
  against the result as a correctness check. If "hand it the old doc + spec
  and it migrates" turns out to be something you want often, that's a
  candidate for its own skill later — it doesn't exist yet.

- **`aigw-doc-resources`** — Not a doing skill, a pointing skill. Ask it
  "where's the AIGW spec," "where do v1 vs v2 docs live," "where's the test
  harness," or any "what do I have to work with here" question for AI
  Gateway docs work, and it tells you where to look and which other skill
  actually does the work. Reach for this first when you're not sure which
  of the others applies.

- **`aigw-doc-testing`** — Hand it a how-to doc and, if you have one, a
  running AI Gateway (local or a deployed test instance) plus credentials.
  It runs the doc end-to-end against the real gateway — applying the
  config, hitting the endpoints, checking responses match what the doc
  claims — and catches drift between the doc and the real API. Use this
  after a doc is drafted (by hand, by `feature-docs-from-prd`, or by
  migration) to confirm it actually works, not just that it reads well.

- **`how-to-starter`** — Give it a use case plus whatever source material
  you have (a PRD, an API spec, an Aha ticket, raw config, a curl command),
  and it scaffolds a brand-new how-to's skeleton: real frontmatter where it
  can infer it, `<!-- TODO -->` where it can't, placeholder steps, the right
  platform tags. Not AI Gateway-specific — use it for any product's
  brand-new tutorial. Skeleton only; you still write the real prose and test
  it yourself. `feature-docs-from-prd` hands off to this one if what a PRD
  actually calls for is a new tutorial rather than edits to existing
  reference pages.


