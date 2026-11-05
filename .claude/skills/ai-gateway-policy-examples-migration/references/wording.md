# Wording for example text

Applies to `title`, `description`, `extended_description` and each `requirements` item.

## Rewrite Gateway-only wording

| Plugin wording | Policy wording |
|---|---|
| "plugin" | "policy" (the policy is an [AI Policy](/ai-gateway/entities/ai-policy/)) |
| "You have enabled the AI Proxy or AI Proxy Advanced plugin" | "You have created an [AI Model](/ai-gateway/entities/ai-model/)" (or AI Agent, AI MCP Server, matching the example) |
| Links to `/plugins/<name>/...` | The matching `/ai-gateway/policies/<policy>/` page or entity page. Remove the link if no equivalent exists. |
| "Gateway Service", "Route", "Consumer" (as targets) | The AI entity that applies, or skip the example |
| `{{site.base_gateway}}` | `{{site.ai_gateway}}` |
| Any AI MCP Server, tool name or upstream URL in the example | The Petstore server and tools from `field-mapping.md` |

Only rewrite what the example says. Do not add claims the plugin example did not make, and do not add behavior you have not verified. When you are unsure that a rewrite keeps the meaning, show the old and new text at Gate 2.

## Prose rules

- Use "AI {Name}" for entities, and link each on first mention in the item.
- No em dashes. No "once" (use "when"). Positive phrasing.
- One sentence per line in `extended_description`.
- Each `requirements` item is a short imperative or "You have ..." statement, matching the other items in the list.
- `description` is one sentence that stands on its own, written for search results.
