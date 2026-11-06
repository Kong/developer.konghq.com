# Plugin example to policy example: field mapping

Source: `app/_kong_plugins/<plugin>/examples/*.yaml`. Target: `app/_ai_gateway_policies/<policy>/examples/*.yml`.
Behavior marked "rendered" was checked on a preview of the dummy `ai-sanitizer/examples/sanitize-pii.yml` from PR 7866.

| Plugin example field | Policy example | Notes |
|---|---|---|
| `title`, `description`, `weight` | Keep | Rewrite Gateway wording. `weight` orders the examples (higher first). |
| `extended_description` | Keep | Rendered. Replaces `description` as the intro on the page. |
| `requirements` | Keep | Rendered as "Prerequisites". Rewrite items that name the AI Proxy plugin or link to `/plugins/...`. |
| `variables` | Keep | Rendered as the "Environment variables" list and used by the API and Terraform snippets. Strings only, see below. |
| `config` | Keep | Must validate against the policy schema. A field missing from the policy schema means skip or ask. |
| `tools` | `konnect-api`, `terraform`, `kongctl` | Drop `deck`, `admin-api`, `kic`. Other values raise an error. |
| (none) | `name`, `display_name`, `type` | Required. `type` must equal the policy folder slug. `name` is kebab-case, unique per example. |
| (none) | `enabled`, `condition` | Optional. Rendered in the snippets. Add `condition` only if the plugin example had one. |
| (none) | `scopes` | Optional subset of the policy's scopes. Default is all scopes in `scopes.json`. An unsupported scope raises an error. |
| (none) | `attach` | Optional map of scope to config name under `app/_data/entity_examples/ai-gateway/<scope>/<name>.yml`. Default is `basic`. |
| `min_version` (`gateway: '3.x'`) | Drop by default | Plugin Gateway versions do not map to AI Gateway versions. If the feature is newer than AI Gateway 2.0, ask the user and use `ai-gateway: '<version>'`. The preview showed no visible output for it. |
| `group` | Do not carry over | Grouping needs `examples_groups` in the policy's `index.md` and platform support. AI Gateway policy example pages have neither yet. See "Example groups" below. |
| `global` | Never set | The page sets `global` for the selected scope. Setting it raises an error. |
| `targets`, `expressions`, `consumer_credential`, `search_aliases` | Drop | Plugin-only. Seen on a few plugin examples. If dropping one changes what the example shows, mark it "convert with changes" and ask. |

## Example groups

A group puts examples under a heading in the example navigation, next to "Basic use cases".

What a group needs:
1. The policy's `index.md` frontmatter defines it: `examples_groups:` with `- slug: <slug>` and `text: <heading>`.
2. Each grouped example sets `group: <slug>`. A slug missing from `examples_groups` fails the build with a nil error.
3. The page layout renders groups. On plugin pages `_layouts/plugins/example.html` does, from `examples_by_group` in `app/_plugins/generators/plugins/plugin.rb`.

State on the branch this skill was written on: `app/_layouts/policies/example.html` (used by AI Gateway policy pages) lists every example under "Basic use cases" and has no group support. `Policy#examples` in `app/_plugins/generators/ai_gateway_policy/policy.rb` has no `examples_by_group`. So a `group` key on a policy example is read and then ignored.

What to do:
- Before grouping, check that `app/_layouts/policies/example.html` references `examples_by_group`. If it does not, do not add `group` or `examples_groups`. Tell the user the platform does not support it.
- Never edit `index.md` or the layout from this skill. Both are out of scope.
- If support exists and a policy has many examples (`ai-rate-limiting-advanced` has 15), ask for approval at Gate 2 (see "Grouping approval" in `SKILL.md`) with the slugs, the headings, and which example goes where. Do not group by default. Basic examples stay ungrouped.

## Variables

Keep the `variables:` block active and keep the `${name}` references in `config`. Without it the API and Terraform snippets lose their copy-paste variables.

The Konnect API snippet renders a variable inside the JSON as a quoted string: `"port": "'$SANITIZER_SERVICE_PORT'"`. For a string field that works. For an integer or boolean field the copied request carries a string and the API rejects it. The validator does not catch this, because it replaces `${...}` with a valid placeholder.

Write the block like this:

```yaml
variables:
  header_value:
    value: $OPENAI_API_KEY
    description: Your OpenAI API key
  redis_host:
    value: $REDIS_HOST
    description: The host where your Redis instance runs
```

- The key is the name used in `config` as `${name}`. Every `${name}` in `config` has a matching key, and every key is used.
- `value` is the environment variable the snippets export, written as `$UPPER_SNAKE_CASE` and named for what it holds (`$OPENAI_API_KEY`, not `$KEY`).
- `description` is a short noun phrase that says what the reader supplies, with no trailing period when it is a fragment, for example `Your OpenAI API key` or `The host where your Redis instance runs`. Name the exact credential or service, and match the provider used in `config`.
- Copy the variables from the plugin example. Change a name or description only when it is wrong for the policy.
- A secret goes through a variable. Do not paste a real or sample key into `config`.

Field rules:

- String field: keep the variable.
- Number or boolean field: use a literal value (the PR's own example uses `port: 8080`).
- If the plugin example used a variable for a number, tell the user which field and what literal you chose.

## Generated sections

- The "Attach the policy" section appears on every tab except Global. It tells the reader to add the policy `name` to the entity's `policies` array and shows the updated entity.
- Attach bodies come from `app/_data/entity_examples/ai-gateway/<scope>/<config>.yml`. A missing config fails the build with the file path in the message.
- Scope tabs use the labels from `app/_data/entity_examples/config.yml` (`ai_gateway_scopes`).
