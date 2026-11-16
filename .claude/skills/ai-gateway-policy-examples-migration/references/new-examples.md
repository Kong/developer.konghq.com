# New examples for new features

Use this when a policy gained a feature that no plugin example covers, so there is nothing to migrate. The file format, variables, tools and validation are the same as for migrated examples (`field-mapping.md`). What changes is where the example comes from and what makes it worth publishing.

## Find the features

A feature is a config field, enum value or behavior that exists in the policy schema and that no example shows. Sources, in order:
1. The user's request: a PRD, a ticket, a schema diff or a PR. Use only what these say.
2. The policy schema in `app/_schemas/ai-gateway/policies/`: list the fields, then list the fields used by the policy's existing examples (`app/_ai_gateway_policies/<policy>/examples/*.yml`). The difference is the candidate list.
3. The policy's `index.md` and the release notes, for behavior the schema does not explain.

Do not invent a field, a default or a behavior. If a source does not say what a field does, ask the user.

## Write a use case, not a field demo

Each example answers one question a reader has: "How do I do X with this policy?" A field with no scenario is not an example.

- **Title:** the outcome, as an imperative phrase. "Detect guardrail violations without blocking", "Return the score in a response header", "Block content with blocklists". Not "Use `continue_on_detection`".
- **`description`:** one plain sentence with no backticks, for search results. Say what the example does.
- **`extended_description`:** optional. Add one when the use case needs more than the `description` sentence, following `wording.md`. Start with the `description` sentence, then say what the default would do instead or when to use it ("Use this to test a guardrail against real traffic before you enforce it"). Backticks are fine here.
- **`config`:** the feature field, plus every other field the scenario needs to be true. If the title promises blocking responses, set the guarding field explicitly. Do not leave out a field the feature depends on, and do not add fields the scenario does not need, unless it's a required field in the schema.
- **`requirements`:** list what the scenario needs beyond the entity: an external service, an account, or another policy. A feature that writes to logs needs a logging policy such as [HTTP Log](/ai-gateway/policies/http-log/) in the requirements.
- **One feature per example.** Two features that matter together (a feature and the field that makes it visible) can share one example. Unrelated features get separate examples.
- **No duplicates.** If an existing example already shows the scenario, extend nothing and skip the new one.

Scenarios that work well:
- A safe rollout: observe or log first, enforce later.
- A different failure behavior: mask instead of block, return details instead of a plain rejection.
- A narrower scope of inspection: responses only, streamed responses only, the latest prompt only.
- A different way to authenticate or identify: a managed identity, a header.
- Tuning: a custom TTL, a fixed window, a custom rate limit response.

## Names and order

- File name stem and `name`: kebab-case, derived from the title, unique across the policy's examples. Prefix `name` with a short policy label when the migrated examples do (`aws-guardrails-...`).
- `display_name`: the same as `title`.
- `weight`: lower than the migrated basic examples of the policy, so the foundational examples stay first. Higher `weight` sorts first.

## Prose

Follow `wording.md` for prose rules. New examples have no plugin wording to rewrite, so the rules that matter are the "AI {Name}" entity naming, requirements as noun phrases ending in a period, `description` without backticks, and no em dashes.

## What you cannot confirm

This skill does not run a gateway. The validator checks the config against the schema, not that the feature behaves as the title says. Say so at Gate 3 and list the examples whose behavior is non-obvious (a log-only mode, a streaming mode, a rejection format), so the user can test them. For testing, point to `aigw-doc-testing`.
