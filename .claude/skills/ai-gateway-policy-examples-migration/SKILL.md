---
name: ai-gateway-policy-examples-migration
description: Use when creating AI Gateway 2.x AI Policy examples (app/_ai_gateway_policies/<policy>/examples/*.yml) on developer.konghq.com, either by converting the example files of a Kong Gateway plugin (app/_kong_plugins/<plugin>/examples/*.yaml) or by writing new examples for a policy feature that has no plugin example. Triggers on "migrate the plugin examples to AI policy examples", "policy examples", "convert <plugin> examples", "add examples for the new <feature>", or a policy or plugin name plus examples plus AI Gateway. Not for the policy overview page (use ai-gateway-plugin-to-policy-migration for that).
argument-hint: <plugin-name> [more plugin names] [triage-only] | new <policy-name> <feature or source>
allowed-tools: Read, Grep, Glob, AskUserQuestion
---

# AI Policy examples

Create AI Policy example files in one of two ways: convert plugin example files (migrate), or write new examples for a policy feature that no plugin example covers (new). The work is mostly mechanical and needs no live gateway. The judgment calls (what to rewrite, what to skip) belong to the user, so the skill stops at gates and asks.

`$ARGUMENTS` holds one or more plugin names (migrate), or `new` followed by a policy name and the feature or its source, such as a PRD, ticket or schema diff (new). If none are given, ask for them. Do not default to "all plugins".

Supporting files (read when the step says so):
- `references/field-mapping.md`: how each plugin example field maps to a policy example field, and what the preview showed
- `references/triage.md`: how to decide whether a plugin and each of its examples can be converted
- `references/wording.md`: Gateway-only wording to rewrite, and prose rules for example text
- `references/new-examples.md`: how to find new features and turn each into a use case (new mode only)

## Gates

At each gate, stop, present the listed items, and wait for an answer. Do not continue on silence or on approval given for an earlier gate.

| Gate | When | You present |
|---|---|---|
| 0 | Before anything | Confirmation to run, and the mode |
| 1 | After triage | One outcome per plugin, with the reason |
| 2 | Before writing files | One decision per example (convert, convert with changes, skip), the rewrites you propose, your questions, and a separate grouping approval when groups are supported |
| 3 | After validation | Validator result, files written and skipped, and the preview checklist |

Nothing is committed or pushed unless the user gives an explicit instruction each time.

## Step 0: Confirm before running (Gate 0)

Ask with `AskUserQuestion`, even when the user invoked the skill by name. State the plugin names, that the skill will create files under `app/_ai_gateway_policies/<policy>/examples/`, and that it does not touch any gateway.

Modes:
- **convert** (default): triage, conversion plan, files, validation.
- **new**: for a policy feature with no plugin example. Follow "New mode" below instead of Steps 1 and 2.
- **triage-only**: stop after Gate 1.
- **cancel**.

## New mode

Skip this section in convert mode.

1. Check that the policy is Ready, using the policy checks in `references/triage.md` (scopes entry, not stub, creatable, schema present). Stop if it is not.
2. Read `references/new-examples.md`. Find the features from the user's source and from the schema fields no existing example uses.
3. Gate 2 for new mode: present one proposed example per line with its title, the use case in one sentence, the config fields it sets, and the requirements it needs. Show features you propose to skip, and why. Ask for anything the source does not say. Wait for the user.
4. Then continue at Step 3. In Step 3, write new files instead of copying a plugin example's file name stem, and follow "Names and order" in `references/new-examples.md`.

Every example must be a meaningful use case, not a field demo. Do not write an example whose behavior you cannot state from the source.

## Step 1: Triage (Gate 1)

Read `references/triage.md` and give each requested plugin one outcome:
- **Not an AI Policy:** no entry in `app/_data/policies/ai-gateway/scopes.json`. Skip and say why.
- **Blocked, policy page is a stub:** the policy's `index.md` has frontmatter only. The generator skips examples for such a policy, so the files would not render. Point the user to `ai-gateway-plugin-to-policy-migration`.
- **Not a creatable AI Policy:** the page has `published: false`, says it can't be created or attached by users, or the migration guide lists no 2.x equivalent (see `references/triage.md`). Skip and say why.
- **Blocked, no schema:** no matching file in `app/_schemas/ai-gateway/policies/`. The validator cannot check the examples.
- **Ready.**

Present the outcomes as a short list, one line each, with the number of examples that would be converted. Wait for the user. In triage-only mode, stop here.

## Step 2: Classify each example (Gate 2)

For each example of each Ready plugin, read the file and `references/field-mapping.md`, then decide:
- **Convert:** the example maps field by field with no change in meaning.
- **Convert with changes:** the example mentions Gateway-only wording (see `references/wording.md`), or needs a decision (a scope subset, a version, an `attach` config). Show the exact old and new text.
- **Skip:** the example depends on something that does not exist on AI Gateway: a config field missing from the policy schema, a Service, Route or Consumer target, or a Gateway-only feature. Give the reason, and do not invent a replacement.

Present the plan in plain language, one example per line, with a short reason. Ask the user the questions you cannot answer from the files:
- Which `scopes:` subset, if the example only makes sense on some scopes (the default is all scopes of the policy).
- Whether a non-default `attach:` config is needed. A new file under `app/_data/entity_examples/ai-gateway/` is a shared change, so ask before creating one.
- Whether to keep a `min_version` (see `references/field-mapping.md`).
- Whether to group examples. This is its own approval, see "Grouping approval" below.

### Grouping approval

Read "Example groups" in `references/field-mapping.md`. Never add `group` or `examples_groups` without the user's approval for that policy.
- If `app/_layouts/policies/example.html` has no group support, tell the user grouping is not available and do not ask.
- Otherwise, when a policy has enough examples that groups would help, ask with `AskUserQuestion` whether to add groups. Show the proposed `examples_groups` (slug and heading) and which example goes in each group. Offer "no groups" as an option. Wait for the answer, and write groups only if the user approves.
- Ask once per policy. An approval for one policy does not cover another.

Do not add a `condition` unless the plugin example already shows one.

Also check that each example is meaningful on AI Gateway 2.x, not only that it validates. Read the `config`, `requirements`, `title` and `description` against the policy's 2.x page and schema, and flag:
- Prerequisites that describe Gateway setup (Services, Routes, Consumers, the AI Proxy plugin) instead of the 2.x equivalent, for example "You have created an [AI Model](/ai-gateway/entities/ai-model/)".
- Providers, models, URLs or headers that only made sense for the plugin (a model name, an upstream route, a Gateway-only header).
- Config fields or defaults that behave differently in 2.x (for example a default that makes the title untrue, such as guarding input only when the title promises blocking responses). Set the field explicitly when the title depends on it.
- Variables whose names or descriptions are wrong or misleading (for example a description that names the wrong credential).
Put each finding in the Gate 2 plan as "convert with changes" and show the old and new text.

## Step 3: Write the files

Create `app/_ai_gateway_policies/<policy>/examples/<example-slug>.yml`. For a migrated example, keep the plugin example's file name stem. Never edit the plugin examples, `index.md`, `app/_schemas/` or any generated file.

Rules (details in `references/field-mapping.md`):
- Add `name` (kebab-case, derived from the example), `display_name` and `type` (the policy slug).
- `tools` is `konnect-api`, `terraform`, `kongctl`, in that order. Drop `deck`, `admin-api` and `kic`. Any other value breaks the build.
- Do not set `global`. The page sets it for the selected scope.
- Use a variable (`${name}`) only for string fields. Use a literal value for numbers and booleans, because the Konnect API snippet renders a variable as a quoted string.
- Keep the `variables:` block active and keep the `${name}` references in `config`. Follow "Variables" in `references/field-mapping.md` for the exact shape.
- Apply the wording rules to `title`, `description`, `extended_description` and `requirements`.

## Step 4: Validate (Gate 3)

1. Run the validator from `tools/aigw-policy-examples-validator`: `node index.js` (run `npm ci` first if it fails on missing modules). Fix findings in the example file. Do not change the validator or the schemas to make an example pass.
2. Run `rtk vale` on each new file if `vale` accepts YAML. If it does not, say so.
3. Give the user this preview checklist (the example page is at `/ai-gateway/policies/<policy>/examples/<slug>/`): the intro text, the Prerequisites section, one tab per scope, an "Attach the policy" section on each non-global tab, and the `condition` and `enabled` values in the snippets. In new mode, also list the examples whose behavior the user should test (see `references/new-examples.md`). Tell the user plainly what is not tested: the validator checks the config against the vendored schema only. It does not send anything to the API, attach the policy, or check that the policy behaves as the example's text says. The same validator runs in CI on pull requests that change policy examples.

Present the final result: files written, files skipped with reasons, validator output, and any open questions for engineering. Then stop.

## Checklist

- [ ] Gate 0 answered
- [ ] Every requested plugin has a triage outcome the user has seen (new mode: the policy is Ready)
- [ ] New mode: each example is a use case with an outcome title, one feature, and a source for every behavior it claims
- [ ] Every example has a decision the user has seen; skipped examples have a reason
- [ ] Each file has `name`, `display_name`, `type` and a valid `tools` list, and no `global`
- [ ] No variables on numeric or boolean fields
- [ ] The `variables:` block is active and matches the `${name}` references in `config`
- [ ] Each example was read for 2.x meaning (prerequisites, provider and model, defaults, variable descriptions)
- [ ] No `group` or `examples_groups` unless the policy example layout supports groups and the user approved them for that policy (see `references/field-mapping.md`)
- [ ] Gateway-only wording rewritten; no `/plugins/` links
- [ ] Validator passes
- [ ] The summary says what is not tested (API acceptance, behavior)
- [ ] Plugin examples, `index.md` and generated files untouched
- [ ] Nothing committed or pushed without an explicit instruction
