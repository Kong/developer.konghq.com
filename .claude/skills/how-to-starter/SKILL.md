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
   plugin to route requests to the upstream."). For entity/plugin config steps, use
   `{% entity_examples %}` — it renders the correct deck or kongctl block itself from the
   page's `tools`, so don't hand-write a separate fenced command for it. Reserve
   `{% entity_example %}` (singular) for what `entity_examples` can't cover — an
   entity/format it doesn't support, or a deliberate multi-tool-tab reference — not as the
   how-to default. For non-entity steps (applying a whole file, `kongctl diff`, etc.), use
   the terse kongctl/deck snippet style from the reference doc. Wrap any tag block Vale
   will flag in `<!--vale off-->` / `<!--vale on-->`.
6. Always end with `## Validate` — never skip it. Pick the `{% validation %}` id that
   actually fits what the how-to did (see the id table in the reference doc; `request-check`
   is common but not the default), filled with real values where the source material has
   them, `<!-- TODO -->` otherwise. Confirm the page's `products` satisfy the validation
   tag's gate; if not, flag it instead of guessing a workaround.
7. Tell the writer what's filled in, what's still `<!-- TODO -->`, and that they own the
   prose and manual testing from here.
