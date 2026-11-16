# Wording for example text

Applies to `title`, `description`, `extended_description` and each `requirements` item.

## Rewrite Gateway-only wording

| Plugin wording | Policy wording |
|---|---|
| "plugin" | "policy" (the policy is an [AI Policy](/ai-gateway/entities/ai-policy/)) |
| "You have enabled the AI Proxy or AI Proxy Advanced plugin" | "An existing [AI Model](/ai-gateway/entities/ai-model/)" (or AI Agent, matching the example) |
| Links to `/plugins/<name>/...` | The matching `/ai-gateway/policies/<policy>/` page or entity page. Remove the link if no equivalent exists. |
| "Gateway Service", "Route", "Consumer" (as targets) | The AI entity that applies, or skip the example |
| `{{site.base_gateway}}` | `{{site.ai_gateway}}` |

Only rewrite what the example says. Do not add claims the plugin example did not make, and do not add behavior you have not verified. When you are unsure that a rewrite keeps the meaning, show the old and new text at Gate 2.

## Prose rules

- Use "AI {Name}" for entities, and link each on first mention in the item.
- No em dashes. No "once" (use "when"). Positive phrasing.
- One sentence per line in `extended_description`.
- Contractions are fine ("doesn't", "haven't"). Use second person ("you haven't listed"). No Oxford comma.
- Each `requirements` item is a short noun phrase such as "An existing [AI Model](/ai-gateway/entities/ai-model/)." Do not write "You have created ...". Match the other items in the list, and end each with a period.
- Use a full sentence only when the item states a condition, for example "Port `6379`, or your custom Redis port, is open and reachable from {{site.ai_gateway}}." Backticks and `{{site.ai_gateway}}` are fine in `requirements`. Quote the YAML string when it starts with a backtick or contains `{{`.

## `description` and `extended_description`

The example page shows `extended_description` as the intro when it exists, and falls back to `description` when it does not. `description` is also used for search results and cards, and it does not render backticks. `extended_description` is optional.

`description`:
- One sentence that stands on its own.
- Plain text. No backticks and no other code formatting. Write "enforce mode" or "observation mode", not "`enforce` mode".

`extended_description`: write one only when the example needs more than the `description` sentence. That means one of these is true:
- the title depends on a fallback, a default, a limit or a side effect that the `description` does not state
- the config has a value that is easier to read with backticks ("in `enforce` mode")
- there is a use case or a trap worth one more sentence

If the `description` already says what the example does and nothing else needs saying, leave `extended_description` out.

When you write one:
1. It stands alone, so the first sentence repeats the `description` sentence. Put backticks on config values: "Configure the AI Routing Provider policy in `enforce` mode."
2. Then one sentence per line for what the config does that the title does not say:
   - the fallback behavior ("falls back to `default_target`")
   - a default that changes the outcome ("the default `timeout_ms` of `300` would send most requests to `default_target`")
   - a limit ("keep it at or below `60000`")
   - a side effect (headers that are hidden, headers that stay)
   - what a flag does ("Azure rejects the request when any blocklist term matches")
3. Optionally end with one use-case sentence ("Use this to check decisions on real traffic before you let them route requests").
4. Take every fact from the policy schema, the policy page or the plugin example. At Gate 2, show where each added fact comes from.

Plugin examples often have a `description` with backticks. Keep the sentence plain in `description`, and move the backticked version to `extended_description`. When a plugin example has no `extended_description` and one of the conditions above applies, propose one at Gate 2 for the user to approve. Do not add one otherwise.
