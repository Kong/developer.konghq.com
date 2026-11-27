To choose which parts of the {{ include.subject | default: 'conversation' }} the Policy {{ include.action | default: 'sends for evaluation' }}, such as {{ include.example | default: 'only the newest user message or tool results' }}, use [`config.message_selection`](./reference/#schema--config-message-selection). It requires {{site.ai_gateway}} 2.4 or later.

Name each kind of content to inspect. The Policy ignores any key you don't name.

{% if include.subject == 'response' %}
{% table %}
columns:
  - title: Key
    key: key
  - title: What gets sent
    key: sent
rows:
  - key: "`assistant`"
    sent: The answer text, without tool calls or reasoning.
  - key: "`tool_call`"
    sent: Each tool call that the model requested, as `name(arguments)`.
  - key: "`tool_result`"
    sent: Each result of a tool that the provider runs itself.
  - key: "`reasoning`"
    sent: The reasoning of the response.
{% endtable %}

Each key accepts the `message_countback` setting, which reads only the newest N messages of that kind.
A response holds one turn, so `scope` accepts only `history`, which is the default.
The `round` scope isn't available.
{% else %}
{% table %}
columns:
  - title: Key
    key: key
  - title: What gets sent
    key: sent
rows:
  - key: "`user`"
    sent: The text of each user message.
  - key: "`system`"
    sent: The text of each system or developer message.
  - key: "`assistant`"
    sent: The text of each assistant message, without tool calls or reasoning.
  - key: "`tool_call`"
    sent: Each tool call as `name(arguments)`.
  - key: "`tool_result`"
    sent: "Each tool result as `name: output`."
  - key: "`reasoning`"
    sent: The reasoning of each assistant message.
{% endtable %}

Each key accepts two settings:

* `message_countback`: Read only the newest N messages of that kind.
* `scope: round`: Read only the content the model hasn't seen yet, which is everything after the last assistant message.
  The `reasoning` key doesn't accept this scope, because reasoning sits inside an assistant message.
{% endif %}

An empty value, like `tool_result: {}`, reads every message of that kind.
Messages are sent oldest first. If a selection matches nothing, the Policy skips the guardrail call and the request continues.
If the selected content is larger than the Policy {% if include.local %}checks{% else %}sends{% endif %} in one {% if include.local %}pass{% else %}call{% endif %}, see [Text chunking](#text-chunking).

{:.warning}
> Selected content leaves {{site.ai_gateway}} and goes to the guardrail service. Select only what the service needs.

{% unless include.subject == 'response' %}
{:.warning}
> A caller controls the conversation history.
> A caller can add an assistant message after a malicious user message.
> That empties the `round` window, so the Policy sends nothing for the malicious message.
> On a route that untrusted callers reach, do not use `scope: round` for the `user` key.
> Use `message_countback` or leave `scope` unset.

An [AI Prompt Template](/ai-gateway/policies/ai-prompt-template/) Policy on the same request, or an [AI Prompt Decorator](/ai-gateway/policies/ai-prompt-decorator/) Policy that prepends messages, changes this.
The Policy then reads every message of the selected kinds and ignores `message_countback` and `scope`.
A decorator that only appends messages keeps both settings, and the Policy always inspects the appended messages.
{% endunless %}

{% unless include.local or include.subject %}
`message_selection` applies to the request.
When `guarding_mode` is `OUTPUT` or `BOTH`, the Policy also guards responses.
It checks the full text of the answer, whatever you select.
{% endunless %}

### Use cases

{% unless include.subject == 'response' %}
For example, this selection sends the newest user message and every tool result:

```yaml
config:
  message_selection:
    user:
      message_countback: 1
    tool_result: {}
```
{% endunless %}

The following table describes example selections based on use case. An empty value (`{}`) selects every message of that kind.

{% if include.subject == 'response' %}
{% table %}
columns:
  - title: Goal
    key: goal
  - title: "`message_selection`"
    key: selection
rows:
  - goal: Check the answer text only, and keep the response streaming.
    selection: |
      `assistant: {}`
  - goal: Check the tool calls the model requested, such as their arguments. The Policy waits for the full response before it checks.
    selection: |
      `assistant: {}`, `tool_call: {}`
  - goal: Check the output of tools that the model provider runs itself, such as a web search.
    selection: |
      `tool_result: {}`
{% endtable %}
{% else %}
{% table %}
columns:
  - title: Goal
    key: goal
  - title: "`message_selection`"
    key: selection
rows:
  - goal: Screen only what the user just asked, and avoid paying to re-screen earlier turns on every request.
    selection: |
      `user: {message_countback: 1}`
  - goal: Screen the output of tools, which comes from outside your control, such as a web page or an API response, and can carry planted instructions.
    selection: |
      `tool_result: {}`
  - goal: Screen only the latest tool result.
    selection: |
      `tool_result: {message_countback: 1}`
  - goal: In an agent loop, screen each new user message and tool result once, on the turn where the model first sees it, instead of on every later turn.
    selection: |
      `user: {scope: round}`, `tool_result: {scope: round}`
  - goal: Combine the newest user message with every tool result.
    selection: |
      `user: {message_countback: 1}`, `tool_result: {}`
  - goal: Block dangerous tools or arguments by matching the calls the model requests.
    selection: |
      `tool_call: {}`
  - goal: Inspect the answer text without sending tool call arguments or reasoning to a third-party service.
    selection: |
      `assistant: {}`
  - goal: Inspect the system prompt, for example to verify that upstream components haven't altered it. The Policy never sends it unless you name `system`.
    selection: |
      `system: {}`
{% endtable %}
{% endif %}

{% unless include.subject == 'response' %}
### Migrate from legacy fields

The legacy fields keep working until you set `message_selection`. When you set both, `message_selection` wins, so you can roll back by removing it.

{% if include.policy == 'ai-prompt-guard' %}

{% table %}
columns:
  - title: Legacy setting
    key: legacy
  - title: "`message_selection`"
    key: selection
rows:
  - legacy: |
      `allow_all_conversation_history: true`
    selection: |
      `user: {message_countback: 1}`
  - legacy: |
      `match_all_roles: true` and `allow_all_conversation_history: false`
    selection: |
      `user: {}`, `assistant: {}`, `tool_result: {}`, `system: {}`
  - legacy: |
      Both fields `false`
    selection: |
      `user: {}`
{% endtable %}

Both fields default to `false`, so a Policy that sets neither maps to `user: {}`.

The Policy rejects `match_all_roles: true` with `allow_all_conversation_history: true`. That check doesn't apply when you set `message_selection`.

{% elsif include.policy == 'ai-sanitizer' %}

{% table %}
columns:
  - title: Legacy setting
    key: legacy
  - title: "`message_selection`"
    key: selection
rows:
  - legacy: |
      `allow_all_conversation_history: true`
    selection: |
      `user: {}`
  - legacy: |
      `allow_all_conversation_history: false`
    selection: |
      `user: {message_countback: 1}`
{% endtable %}

`allow_all_conversation_history` defaults to `true`, so a Policy that doesn't set it maps to `user: {}`.

{% elsif include.policy == 'ai-semantic-prompt-guard' %}

{% table %}
columns:
  - title: Legacy setting
    key: legacy
  - title: "`message_selection`"
    key: selection
rows:
  - legacy: |
      `rules.match_all_conversation_history: false`
    selection: |
      `user: {message_countback: 1}`
  - legacy: |
      `rules.match_all_conversation_history: true` and `rules.match_all_roles: false`
    selection: |
      `user: {}`
  - legacy: |
      `rules.match_all_conversation_history: true` and `rules.match_all_roles: true`
    selection: |
      `user: {}`, `assistant: {}`, `tool_result: {}`, `system: {}`
{% endtable %}

`rules.match_all_roles` has no effect when `rules.match_all_conversation_history` is `false`.

`rules.match_all_conversation_history` defaults to `false`, so a Policy that doesn't set it maps to `user: {message_countback: 1}`.

{% elsif include.policy == 'ai-nvidia-nemo-guardrail' %}

{% table %}
columns:
  - title: Legacy setting
    key: legacy
  - title: "`message_selection`"
    key: selection
rows:
  - legacy: |
      `text_source: concatenate_all_content`
    selection: |
      `user: {}`, `assistant: {}`, `tool_result: {}`, `system: {}`
  - legacy: |
      `text_source: concatenate_user_content`
    selection: |
      `user: {}`
{% endtable %}

`text_source` defaults to `concatenate_all_content`, so a Policy that doesn't set it maps to the first row.

{% else %}

{% table %}
columns:
  - title: Legacy setting
    key: legacy
  - title: "`message_selection`"
    key: selection
rows:
  - legacy: |
      `text_source: concatenate_all_content`
    selection: |
      `user: {}`, `assistant: {}`, `tool_result: {}`, `system: {}`
  - legacy: |
      `text_source: concatenate_user_content`
    selection: |
      `user: {}`
  - legacy: |
      `text_source: last_message`
    selection: |
      `user: {message_countback: 1}`
{% endtable %}

{% if include.policy == 'ai-custom-guardrail' or include.policy == 'ai-gcp-model-armor' %}`text_source` defaults to `last_message`, so a Policy that doesn't set it maps to the last row.
{% else %}`text_source` defaults to `concatenate_all_content`, so a Policy that doesn't set it maps to the first row.
{% endif %}

{% endif %}

To migrate, translate the Policy with the mapping, set `message_selection`, and then remove the legacy fields.

{:.warning}
> Two {{site.ai_gateway}} 2.4 changes affect existing Policies even if you don't set `message_selection`.
> Concatenated text now goes oldest first, so a pattern anchored at the start of the text now meets the oldest message.
> `text_source: concatenate_all_content` on a native route now includes the system prompt.
> Review any anchored allow or deny patterns.

{% unless include.policy == 'ai-sanitizer' %}
A selection also sends words that the legacy path didn't: each tool result is prefixed with the tool name, and a selection that names `tool_call` adds the calls.
{% endunless %}
{% endunless %}
