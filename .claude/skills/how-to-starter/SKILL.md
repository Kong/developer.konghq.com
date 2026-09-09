---
name: how-to-starter
description: >
  Scaffold a brand-new how-to guide for developer.konghq.com from a use case description
  plus whatever source material a writer has (PRD, API/OpenAPI spec, Aha ticket, raw
  config, curl). Use whenever someone asks to start, scaffold, bootstrap, or generate the
  skeleton of a new how-to page. Produces structure only, not finished prose: real
  frontmatter filled in where known and `<!-- TODO -->` where not, terse one-line
  placeholder steps, the right tool choice (kongctl/deck/admin-api), and the right
  platform tags (`{% entity_examples %}`, `{% validation %}`), always ending in a
  Validate step. The writer adds the real words and tests the doc themselves. If the use
  case is Kong Identity, DCGW Terraform, or a third-party plugin, prefer
  kong-identity-how-to, dcgw-terraform-how-to, or third-party-plugin instead — those
  write full prose for their domains. Not for revising an existing how-to.
---

Read `references/scaffold-patterns.md` before doing anything else — it has the frontmatter
template, tag syntax, and placeholder conventions.

1. Ask what the how-to should accomplish, and for any source material available. Read
   whatever's provided.
2. Derive `products`, `works_on`, `tools`, and `entities` from that material rather than
   asking — prefer `kongctl`/`deck` over `admin-api` when either would work. Only ask for
   what you truly can't infer, like the permalink slug or `min_version`.
3. Check 2-3 sibling files in the target `app/_how-tos/<product>/` directory to match that
   product's real permalink and frontmatter conventions before writing anything.
4. Write the file. Fill every frontmatter field you know; drop an inline
   `<!-- TODO: ... -->` for anything unknown — never guess a value.
5. Draft body H2s as one terse placeholder sentence each (for example, "Configure the
   plugin to route requests to the upstream."). When a later step needs an ID a previous
   step generates, favor a chain of separate `{% konnect_api_request %}` (or
   `{% validation request-check %}`) calls — one per H2, each `capture`-ing its own ID for
   `$VARIABLE` interpolation in the next step; `app/_how-tos/event-gateway/
   kong-identity-oauth.md` is the model for this and the default whenever the product has a
   real per-entity API. Use `{% entity_examples %}` for kongctl/deck-declarative entity
   config instead — it renders the right deck/kongctl block itself from the page's `tools`.
   Reserve `{% entity_example %}` (singular) for what `entity_examples` can't cover, not as
   the how-to default. Wrap any tag block Vale will flag in `<!--vale off-->` /
   `<!--vale on-->`.
6. Add `capture:` (`jq` or `command`) to any step whose response produces a value needed
   later — never write a manual "copy this value" instruction; pair with `extract_body:`
   when the source material names the response field. If you used
   `entity_examples`/`entity_example` instead, remember two things: `!ref name#field` only
   resolves within the same block (never split a referenced entity into its own step), and
   it has no response to capture at all — a later raw API call needing its ID needs its own
   GET-and-`capture` step first.
7. Always end with `## Validate` — never skip it. Pick the `{% validation %}` id that
   actually fits what the how-to did (see the id table in the reference doc; `request-check`
   is common but not the default), filled with real values where the source material has
   them, `<!-- TODO -->` otherwise. Confirm the page's `products` satisfy the validation
   tag's gate; if not, flag it instead of guessing a workaround.
8. Tell the writer what's filled in, what's still `<!-- TODO -->`, and that they own the
   prose and manual testing from here.
