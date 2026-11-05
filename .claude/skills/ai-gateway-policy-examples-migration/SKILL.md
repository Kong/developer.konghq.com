---
name: ai-gateway-policy-examples-migration
description: Use when converting the example files of a Kong Gateway plugin (app/_kong_plugins/<plugin>/examples/*.yaml) into AI Gateway 2.x AI Policy examples (app/_ai_gateway_policies/<policy>/examples/*.yml) on developer.konghq.com. Triggers on "migrate the plugin examples to AI policy examples", "policy examples", "convert <plugin> examples", or a plugin name plus examples plus AI Gateway. Not for the policy overview page (use ai-gateway-plugin-to-policy-migration for that).
argument-hint: <plugin-name> [more plugin names] [triage-only]
allowed-tools: Read, Grep, Glob, AskUserQuestion
---

# Plugin examples to AI Policy examples

Convert plugin example files into AI Policy example files. The work is mostly mechanical and needs no live gateway. The judgment calls (what to rewrite, what to skip) belong to the user, so the skill stops at gates and asks.

`$ARGUMENTS` holds one or more plugin names. If none are given, ask for them. Do not default to "all plugins".

Supporting files (read when the step says so):
- `references/field-mapping.md`: how each plugin example field maps to a policy example field, and what the preview showed
- `references/triage.md`: how to decide whether a plugin and each of its examples can be converted
- `references/wording.md`: Gateway-only wording to rewrite, and prose rules for example text

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
- **triage-only**: stop after Gate 1.
- **cancel**.

## Step 1: Check prerequisites

The example rendering and validator come from PR 7866 (open when this skill was written). Check that these exist on the current branch:
- `app/_includes/ai_gateway_policies/example.md`
- `app/_plugins/drops/policy_config_example/ai_gateway.rb`
- `tools/aigw-policy-examples-validator/index.js`
- `app/_data/entity_examples/ai-gateway/ai-model/basic.yml` (the default attach config)

If any is missing, stop and tell the user the branch does not have the policy example support yet. Do not write example files that cannot render or be validated.

## Step 2: Triage (Gate 1)

Read `references/triage.md` and give each requested plugin one outcome:
- **Not an AI Policy:** no entry in `app/_data/policies/ai-gateway/scopes.json`. Skip and say why.
- **Blocked, policy page is a stub:** the policy's `index.md` has frontmatter only. The generator skips examples for such a policy, so the files would not render. Point the user to `ai-gateway-plugin-to-policy-migration`.
- **Not a creatable AI Policy:** the page has `published: false`, says it can't be created or attached by users, or the migration guide lists no 2.x equivalent (see `references/triage.md`). Skip and say why.
- **Blocked, no schema:** no matching file in `app/_schemas/ai-gateway/policies/`. The validator cannot check the examples.
- **Ready.**

Present the outcomes as a short list, one line each, with the number of examples that would be converted. Wait for the user. In triage-only mode, stop here.

## Step 3: Classify each example (Gate 2)

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

Every AI MCP Server in an example is the Petstore server from the 2.x MCP how-tos (`references/field-mapping.md`). Ask before using any tool or API beyond it.

Do not add a `condition` unless the plugin example already shows one.

Also check that each example is meaningful on AI Gateway 2.x, not only that it validates. Read the `config`, `requirements`, `title` and `description` against the policy's 2.x page and schema, and flag:
- Prerequisites that describe Gateway setup (Services, Routes, Consumers, the AI Proxy plugin) instead of the 2.x equivalent, for example "You have created an [AI Model](/ai-gateway/entities/ai-model/)".
- Providers, models, URLs or headers that only made sense for the plugin (a model name, an upstream route, a Gateway-only header).
- Config fields or defaults that behave differently in 2.x (for example a default that makes the title untrue, such as guarding input only when the title promises blocking responses). Set the field explicitly when the title depends on it.
- Variables whose names or descriptions are wrong or misleading (for example a description that names the wrong credential).
Put each finding in the Gate 2 plan as "convert with changes" and show the old and new text.

## Step 4: Write the files

Create `app/_ai_gateway_policies/<policy>/examples/<example-slug>.yml`. Keep the plugin example's file name stem. Never edit the plugin examples, `index.md`, `app/_schemas/` or any generated file.

Rules (details in `references/field-mapping.md`):
- Add `name` (kebab-case, derived from the example), `display_name` and `type` (the policy slug).
- `tools` is `konnect-api`, `terraform`, `kongctl`, in that order. Drop `deck`, `admin-api` and `kic`. Any other value breaks the build.
- Do not set `global`. The page sets it for the selected scope.
- Use a variable (`${name}`) only for string fields. Use a literal value for numbers and booleans, because the Konnect API snippet renders a variable as a quoted string.
- Write the `variables:` block commented out, every line prefixed with `# `, and keep the `${name}` references in `config`. Policy example pages currently hide the "Environment variables" list, and the variable handling is under review, so do not leave an active `variables:` block. Never delete the block, because the user will decide later what to do with it.
- Apply the wording rules to `title`, `description`, `extended_description` and `requirements`.

## Step 5: Validate (Gate 3)

1. Run the validator from `tools/aigw-policy-examples-validator`: `node index.js` (run `npm ci` first if it fails on missing modules). Fix findings in the example file. Do not change the validator or the schemas to make an example pass.
2. Run `rtk vale` on each new file if `vale` accepts YAML. If it does not, say so.
3. Give the user this preview checklist (the example page is at `/ai-gateway/policies/<policy>/examples/<slug>/`): the intro text, the Prerequisites section, one tab per scope, an "Attach the policy" section on each non-global tab, and the `condition` and `enabled` values in the snippets. Tell the user plainly what is not tested: the validator checks the config against the vendored schema only. It does not send anything to the API, attach the policy, or check that the policy behaves as the example's text says. The same validator runs in CI on pull requests that change policy examples.

4. List the files whose `variables:` block is commented out, with the variable names and descriptions, so the user can decide what to do with them.

Present the final result: files written, files skipped with reasons, validator output, and any open questions for engineering. Then stop.

## Checklist

- [ ] Gate 0 answered; prerequisites exist on the branch
- [ ] Every requested plugin has a triage outcome the user has seen
- [ ] Every example has a decision the user has seen; skipped examples have a reason
- [ ] Each file has `name`, `display_name`, `type` and a valid `tools` list, and no `global`
- [ ] No variables on numeric or boolean fields
- [ ] The `variables:` block is commented out, not removed, and listed for the user
- [ ] Each example was read for 2.x meaning (prerequisites, provider and model, defaults, variable descriptions)
- [ ] No `group` or `examples_groups` unless the policy example layout supports groups and the user approved them for that policy (see `references/field-mapping.md`)
- [ ] Gateway-only wording rewritten; no `/plugins/` links
- [ ] Validator passes
- [ ] The summary says what is not tested (API acceptance, behavior)
- [ ] Plugin examples, `index.md` and generated files untouched
- [ ] Nothing committed or pushed without an explicit instruction
