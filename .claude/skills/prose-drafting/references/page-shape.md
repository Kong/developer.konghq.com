# Page shape

What a page's content should actually contain, by page type. Sentence and
word-level rules live in `prose-mechanics.md` — this file is about structure
and emphasis: which sections a page needs, what order they go in, and what
job each one does.

There is no separate "concept page" type. A reference page is the concept
page — per `app/contributing/index.md`'s "every page is page one" tenet, a
reference page carries both the conceptual explanation and the configuration
detail, so a reader never has to leave it to understand what something is
before learning how to use it.

## Reference pages

### Open with why, not just what

The first few paragraphs need to answer "what is this and why would I use
it" before any configuration detail. A reader should know why they'd reach
for this entity or feature before hitting a schema or a config table.

### Have an opinion

A reference page needs an interpretive layer: guidance about when to use one
option, mode, or configuration over another. An exhaustive list of
schema fields can help, but isn't sufficient. Without the "why you'd pick
this" layer, the page reads as a schema dump with prose wrapped around it.

The anti-pattern to actively avoid, and to flag when revising: a page that
enumerates every field and every mode without ever telling the reader which
one fits their situation. 
When revising a reference page, this is one of the first things to check for,
before any line-level wordsmithing.

### Common sections

Not every page needs every section; use
the trigger described for each situational one.

**Present on nearly every reference page:**
- An unheaded intro paragraph right after frontmatter (the "why" framing
  above) — though a handful of narrow-topic pages skip even this (see "Flat,
  no-heading pages" below).
- A concept-definition opener — a "What is X?" H2 on an entity page, or
  direct topical H2s on a platform-config or mechanism page that doesn't
  center on one named entity.
- A `related_resources` frontmatter block. This renders as sidebar links,
  separate from anything in the page body — it doesn't replace an inline
  link a reader would actually click while reading.

**Two different reference-page shapes, with two different endings:**

Reference pages split into two shapes, and only one of them ends in a
generated parameter dump. Knowing which shape a page is tells you what its
ending should look like — don't push a page toward a schema-like ending it
doesn't need.

- **Entity/parameter pages**: the page's whole subject is a formally
  defined, complete parameter set, and it ends there. This is broader than
  just `{% entity_schema %}` (Gateway/AI Gateway/Event Gateway entity pages):
  `event-gateway/configuration.md` ends in `{% event_gateway_conf %}` (a
  generated config-file parameter dump), `gateway/kong-manager/configuration.md`
  and `gateway/cp-dp-communication.md` end in `{% kong_config_table %}`
  blocks, and KIC's and Operator's `reference/custom-resources.md` are
  auto-generated CRD docs ending in massive generated field tables with no
  shortcode involved at all. The real trigger is **"this page's subject has
  a complete, mechanically-generated parameter set,"** not "this is an
  entity page."
- **Conceptual/mechanism pages**: the majority of reference pages
  (expressions, upgrade guides, health checks, load balancing, clustering,
  admin API security, DB-less mode, mTLS, SSO, CMEK, streaming, semantic
  similarity, and more). These have no fixed ending — they end wherever the
  explanation naturally concludes: a limitations list, a
  troubleshooting/conflict table, a vendor-specific example (for example,
  `gateway/cp-outage.md` ending on a MinIO storage example), a CLI/API
  pointer, or a short caveat paragraph. Don't add a `## Schema` or
  config-table section to a page like this just to give it a "proper"
  ending — it doesn't need one.

**Situational, each with a trigger:**

- **A green `{:.success}` "want to get started?" banner**, linking to
  tutorials. Include this only when the feature is backed by multiple
  standalone how-to tutorials worth surfacing inline (real examples:
  `dedicated-cloud-gateways/managed-cache.md`, `catalog/apis.md`). It can sit
  immediately after the intro paragraph, before the first `##` — always
  first when present. Or, it can sit under any heading in the doc.
  Skip it for entity pages that don't have several
  dedicated how-tos; `related_resources` alone covers that case.
- **A generic "Configure X" section with tool tabs** (UI/API/Terraform).
  Include this when the page needs to be the catch-all answer to "how do I
  configure this with X" beyond what any single how-to covers — the
  `managed-cache.md` pattern. A simpler entity page instead gets a short
  "Set up a Route/Service"-style pointer, or folds configuration into its
  topical sections. When present, this sits after the concept/reference
  sections and before any health/lifecycle section.
- **FAQs.** Implemented through the `faqs:` frontmatter list, never an inline
  `## FAQ` heading — the page layout always renders them at the very bottom
  regardless of where the block sits in frontmatter. Adding an FAQ is a writer's
  judgment call, not a default section every page needs. On some
  architecture/procedural pages (`gateway/control-plane-groups.md`,
  `gateway/cp-outage.md`, `event-gateway/upgrade.md`), the FAQ carries
  substantial explanatory weight alongside a short H2 body — don't read
  a short body as automatically thin if the FAQ is doing the work.
- **Limitations or scope-of-support.** This can be a single inline caveat
  sentence near the top (for example, managed cache's "Only AWS and Azure
  are currently supported") or a dedicated heading. A dedicated
  `## Limitations` (or `## Unsupported features`) section is one of the
  normal ways a conceptual/mechanism page ends when it has no schema to
  render (`gateway/db-less-mode.md`, `event-gateway/known-limitations.md`,
  `kic/sticky-sessions-reference.md`,
  `kong-identity/principals-and-directories.md`,
  `ai-gateway/semantic-similarity.md`) — not a special case, and readers do
  appreciate these, since gotchas are historically under-documented.
- **A "how it works" or flow section** — prose plus an ordered list, and/or a
  Mermaid diagram, walking through real sequential mechanics. Include this
  when a feature has enough of a sequence to be worth walking through (for
  example, `route.md`'s `## How routing works`). Writer's discretion — many
  features aren't complex enough to need one, and forcing a diagram onto a
  simple feature adds noise, not clarity.
- **An examples section**, similar in spirit to a plugin's example configs —
  a quick copy/paste area for common configurations that don't differ enough
  to warrant their own how-tos (`metering-and-billing/metering.md` is an
  example: several `{% konnect_api_request %}` pairs, one per common use
  case, each with a one-sentence setup rationale before it).

**Other legitimate structural variants:**

- **Numbered-procedure headings.** Some reference pages use literal step
  headings ("1. Upgrade data planes") instead of thematic section names
  (`event-gateway/upgrade.md`, `gateway/upgrade/in-place.md`) — a valid
  variant for a linear, multi-phase procedure that's still a reference page,
  not a how-to. Reference pages like this are common for migrations and upgrades where a user would be taking their production or already configured set up and doing something with it. 
- **Expressions/conditional-language pages form a consistent sub-genre.**
  `gateway/routing/expressions.md` and `event-gateway/expressions.md` are
  near-identical in structure across products (operators → fields →
  examples). If drafting or revising an expressions-language page for
  another product, these two are the precedent to follow.

### Liquid blocks are this skill's job, not just prose around them

When a reference page interweaves Liquid blocks — `entity_examples`,
`table`, `feature_table`, config examples, generic configuration steps —
with prose, draft both the block and its surrounding prose together. Nothing
else scaffolds a reference page's content the way `how-to-starter` scaffolds
a how-to, so leaving the blocks to "someone else" leaves them undrafted.
`app/contributing/index.md` is the syntax reference for these tags — read it
for exact block syntax, but don't defer authoring the block itself elsewhere.

## How-to pages

### Section and step cadence

An H2 is one discrete configuration phase — setting up a Vault server,
creating an entity, running validation. An H3 groups one coherent sub-task
within that phase. The goal is to avoid two failure modes: cramming an entire
multi-phase setup into one giant step-list, and fragmenting a single
coherent task into too many H2s so the page feels longer than it is.

There's a structural exception: AI Gateway 2.0 configuration (a Model,
an Auth Strategy, a Provider) has to live in one step when using `kongctl`,
because `kongctl` can't chain resource creation — unlike the API, Terraform, or decK,
which can chain resource creation across steps. Don't assume every product
allows the same step-splitting freedom; check whether the tool in use
actually supports referencing an entity created in a prior step before
splitting a multi-entity setup into multiple H2s.

**When the same steps repeat across how-tos, pull them into a shared
include** rather than restating them. The newer HashiCorp Vault how-tos
(`configure-hashicorp-vault-with-azure-managed-identity.md`,
`-gcp-workload-identity.md`) are the model for this: the repeated "create
policy files" and "start/unseal/login to Vault" steps live in
`{% include /gateway/hashicorp-vault-create-policies.md %}` and
`{% include /gateway/hashicorp-vault-basic-setup.md %}`, leaving only the
auth-method-specific steps visible in each how-to's body. Before writing out
a setup sequence that feels generic, check whether a shared include already
covers it.

### How-tos don't branch

A how-to is opinionated and linear. It essentially never offers optional
paths inside the steps — a rare alternative configuration gets a note or an
FAQ at most, never a fork in the numbered steps. If there's a genuine need
to show several ways to configure something, that belongs on the reference
page's generic "Configure X" section (see above), not inside a how-to.

### Series

A `series: {id: ..., position: N}` how-to is for a task that's naturally
extended with stopping points — a reader who stops after page 1 has
something working; continuing gets them a fuller, more end-to-end setup.
This is different from splitting one how-to because it "got long" — length
alone isn't the trigger, a genuine natural stopping point is. Real examples:
`mesh-get-started-universal-*`, `operator-get-started-*`. Each series
typically opens with pre-H2 prose describing the whole arc (sometimes with a
diagram), and each page's H2s cover one deployable milestone. Series aren't
common — check for an existing one covering similar ground before proposing
a new split, and when unsure whether a task warrants a series, ask
rather than guessing.

### Get-started vs. regular how-to intros

A "Get started" guide explains more, inline, than a regular how-to does. It
defines concepts as they come up — for example, explaining inline what a
Gateway Service is, while still linking out to the reference page for
depth — and keeps its per-section prose conceptual and generic, since the
reader is likely new to the product.

A regular how-to just links out to the reference term instead of defining it
inline, but it still explains *why* a given configuration choice matters for
that specific scenario — often with real interaction detail, not just a
restatement of what the entity does. For example: "Because of plugin
execution order, the Service Protection plugin runs before Rate Limiting, so
Consumers together can't exceed the Service Protection limit even if each
Consumer's individual Rate Limiting allowance is higher." That's the kind of
sentence a regular how-to needs and a generic definition doesn't provide.

A regular how-to may or may not need intro prose before the first H2 — this
should never repeat the TLDR (see `prose-mechanics.md`). A Get-started guide
more often does need that intro, since it's setting expectations for a
reader who hasn't done this before.

### Command and API-call lead-ins

The sentence right before a Terraform, API, or CLI block names the specific
resource being created and, briefly, why — not a generic "run the
following." Real patterns:
- "Create an auth server using the [`/v1/auth-servers` endpoint](...):"
- "Create an [AI Model Provider](...) entity to define your connection and
  store your authentication credentials:"

The lead-in should let a reader understand what the block accomplishes
without needing to parse the block itself first.

## Landing pages

A landing page is a signpost, not a content destination. It opens with
broader framing (see `prose-mechanics.md`'s opening-conventions section) and
its job is to route the reader to the right reference or how-to page, not to
contain the deep content itself. Resist the pull to explain a feature fully
on a landing page — that content belongs on the reference page it should
link to.

## Out of scope: AI cookbooks

`app/_cookbooks/` pages have a distinctly different, more narrative
structure than how-tos or reference pages — sections like "The problem" and
"The solution" explaining tradeoffs before any configuration, a rationale
paragraph per component, "Variations and next steps," and "Cleanup." This
skill doesn't cover cookbook prose. If asked to draft or revise a cookbook,
say so plainly rather than forcing how-to/reference conventions onto a
structure they don't fit.
