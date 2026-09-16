# Prose mechanics

Sentence and word-level rules for developer.konghq.com. This file exists to
cover what isn't written down anywhere else — it's not a substitute for
`app/contributing/style-guide.md` or `docs/ui-steps-standards.md`.

**Read those two files first.** Voice and tone (active voice, present tense,
contractions, American English, bias-free language), grammar and punctuation,
heading capitalization, placeholder and code-block formatting, and UI element
naming are all governed there. Nothing in this file repeats those rules —
if something feels like it should be a style-guide rule and isn't listed
here, check there before assuming it's undocumented.

## Sentence and paragraph shape

- **Default to shorter.** There's no hard clause-count limit, but a sentence
  stacking multiple "and"s is a signal to split it into two.
- **Each sentence should be on a new line**. This makes it easier for reviewers to leave suggestions.
- **List vs. prose**: Split three or more items into a list instead of one sentence.
- **List vs. YAML table** (never a markdown table — this repo renders tables
  through the `{% table %}` Liquid block): this is a judgment call, not a
  hard rule. A list with a bolded lead-in phrase per item (`**Feature X**:
  does Y`) suits an overview or feature-summary framing, where the point is
  to give a reader a quick sense of what's available. A table suits content
  that's fundamentally comparison-shaped, or something a reader will scan for
  their specific use case, parameter, or configuration option rather than
  read start to finish.
- **Split a paragraph when the thought shifts.** Split into a new section
  when the shift is big enough that the paragraph split alone doesn't make
  the change clear. 

## Terms and linking

- **Link a term on first mention in body prose** (not in frontmatter) to the
  concept/reference page that covers it. Prefer linking to the actual page
  over the glossary — the glossary exists mainly so odd phrases surface in
  search, not as the primary link target for a term that already has a
  home.
- **Terminology authority**: when describing a literal UI or API action, the
  UI/API's own name wins, even if it differs from the docs' in-house term.
  For example, if the UI's actual button doesn't say "Gateway Service" even
  though that's the docs' standing term for the entity, a literal instruction
  ("click **Add service**") follows the UI's label, not the docs' term.
  Outside of a literal UI/API instruction, prose uses docs' in-house terms or can lean on more common or
  familiar terms, or on `search_aliases` frontmatter, to connect a feature to
  concepts a reader already knows and to aid discovery.

## Language to strip or avoid

- **Hedging language**: remove "simply," "just," "easily," "obviously," and
  similar words entirely. No exceptions.
- **AI-tells** — edit these out on sight, whether drafting or revising:
  - Anthropomorphism: for example, "fires (a request)," "lands," "wins." Use the literal
    mechanism instead: "sends," "is assigned to," "takes precedence."
  - "By hand" → "manually."
  - "Genuinely" as a filler intensifier.
  - Semicolon overuse — prefer two sentences, or a comma/colon where it
    actually fits.
  - Never use em dashes.
  - "is a real", never use "real" as a qualifier
- **Negation and conditional clauses**: avoid an awkward negative like
  "requires no X" — prefer the direct negative, "doesn't require X." Avoid a
  fragment or adjective-led conditional opener like "With X enabled," or
  "Disabled, it does Y" — write the full clause: "When X is enabled, ..." /
  "When it's disabled, ...".
- **Verb precision**: prefer the plain, accurate verb over a wordier or vaguer
  one.
  - "Makes use of" → "uses."
  - "Obtain the software" → "install the software" (say the actual action,
    not a vague stand-in for it).
  - A doubled infinitive like "Port number to use to communicate with the
    controller" → "Port number used to communicate with the controller."
- **A "not X, Y" construction** (stating what something *isn't* before saying
  what it is) — rephrase as a direct positive statement instead.
- **Negative phrasing**: use positive phrasing in most cases. 

## Examples and lead-ins

- **An example lead-in should say what the example shows**, not just
  announce that an example follows. "The following example is a request without a bearer
  token:" tells the reader what to look for in the block below; a bare "For
  example:" doesn't.
- **A command/API-call lead-in names the specific resource and the reason**,
  not just "run the following": "Create an auth server using the
  [`/v1/auth-servers` endpoint](...):" rather than "Run this command:". See
  `page-shape.md`'s how-to section for more on this pattern.

## Opening conventions

- A how-to or reference page's intro leads with what the thing is and how it
  relates to a use case or concept — never "In this guide..." as the literal
  first sentence (that framing can appear later in the intro, just not as the
  opener).
- A landing page opens with broader framing — the underlying concept, even
  outside Kong's own products — before narrowing to Kong-specific
  capabilities and use cases. See `app/_landing_pages/ai-gateway/mcp.yaml` as
  the worked example: it opens on what MCP is and why it matters
  industry-wide, then narrows into what {{site.ai_gateway}} does with it.
  Reference and how-to pages don't need that industry-level preamble — the
  reader already arrived with intent.

## TLDR (how-to frontmatter)

A how-to's `tldr.a` is shorthand for an experienced reader to skip the guide
entirely, not an overview of the guide. It answers "how do I do this" tersely
enough to act on without reading further — never "In this guide, you'll..."
framing. This is a mistake worth actively watching for: it's a common way to
get a TLDR wrong.

## FAQs

An FAQ answer must stand on its own if it were pulled out of the page
entirely — for example, into a search result or a RAG retrieval. Restate the
subject by name rather than relying on "this feature" or "it" to mean
"whatever this page happened to be about."
