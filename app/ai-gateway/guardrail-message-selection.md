---
title: "AI guardrail message selection"
content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

products:
  - ai-gateway

breadcrumbs:
  - /ai-gateway/

tags:
  - ai
  - guardrails

min_version:
  ai-gateway: '2.4'

description: Choose which parts of a conversation an AI guardrail Policy inspects, such as the newest user message, tool results, or tool calls, so you can guard agentic traffic without re-screening everything on every turn.

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI AWS Guardrails Policy
    url: /ai-gateway/policies/ai-aws-guardrails/
  - text: AI Azure Content Safety Policy
    url: /ai-gateway/policies/ai-azure-content-safety/
  - text: AI Custom Guardrail Policy
    url: /ai-gateway/policies/ai-custom-guardrail/
  - text: AI GCP Model Armor Policy
    url: /ai-gateway/policies/ai-gcp-model-armor/
  - text: AI Lakera Guard Policy
    url: /ai-gateway/policies/ai-lakera-guard/
  - text: AI NVIDIA NeMo Guardrail Policy
    url: /ai-gateway/policies/ai-nvidia-nemo-guardrail/
  - text: AI Prompt Guard Policy
    url: /ai-gateway/policies/ai-prompt-guard/
  - text: AI Sanitizer Policy
    url: /ai-gateway/policies/ai-sanitizer/
  - text: AI Semantic Prompt Guard Policy
    url: /ai-gateway/policies/ai-semantic-prompt-guard/
  - text: AI Semantic Response Guard Policy
    url: /ai-gateway/policies/ai-semantic-response-guard/
---

Guardrail [AI Policies](/ai-gateway/entities/ai-policy/) build one block of text from the conversation.
They then send that text to a guardrail service, or match it against their own rules.
The content in that text determines what the guardrail can catch, what it costs, and how much data leaves {{site.ai_gateway}}.

In a simple chat, the last user message is usually enough.
In an agentic conversation, the history also holds tool calls, tool results, and model reasoning, and every turn sends it again.
Inspecting all of it every time means paying to screen the same content repeatedly.
Inspecting only user messages misses the content that agents are most often manipulated through, such as the output of a tool that fetched a web page.

The `message_selection` field lets you choose which parts of the conversation each Policy inspects.
It replaces the `text_source` field, which offered three fixed presets and couldn't target tool calls or tool results.

The following Policies support `message_selection` on requests:

* [AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/)
* [AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/)
* [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/)
* [AI GCP Model Armor](/ai-gateway/policies/ai-gcp-model-armor/)
* [AI Lakera Guard](/ai-gateway/policies/ai-lakera-guard/)
* [AI NVIDIA NeMo Guardrail](/ai-gateway/policies/ai-nvidia-nemo-guardrail/)
* [AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/)
* [AI Sanitizer](/ai-gateway/policies/ai-sanitizer/)
* [AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/)

[AI Semantic Response Guard](/ai-gateway/policies/ai-semantic-response-guard/) supports it on responses.
See [Model responses](#model-responses).

{:.warning}
> The content you select leaves {{site.ai_gateway}} and is sent to the guardrail service. Select only what that service needs to evaluate.

## How a selection works

`message_selection` is a map.
Each key names one kind of content to inspect, and the key's value narrows how much of that content to read.
The Policy inspects only the keys you name.

```yaml
config:
  message_selection:
    user:
      message_countback: 1
    tool_result: {}
```

This selection sends the newest user message plus every tool result in the conversation.
An empty value, like `tool_result: {}`, reads all items of that kind.

Each key accepts two settings: `message_countback` reads the newest N items, and `scope: round` reads only the items the model hasn't seen yet.
For types and limits, see the `message_selection` entry in each Policy's schema reference.

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
    sent: The text of each assistant message, without its tool calls or reasoning.
  - key: "`tool_call`"
    sent: Each tool call as `name(arguments)`, including tools that the model provider runs itself.
  - key: "`tool_result`"
    sent: "The output of each tool result as `name: output`, including provider-run tools."
  - key: "`reasoning`"
    sent: The reasoning summary and reasoning content of each assistant message.
{% endtable %}

Messages keep conversation order, oldest first, separated by a blank line.
Different kinds of content from the same message, such as its answer text, tool calls, and reasoning, are joined with a space.
Bedrock and Gemini tool results keep their JSON shape, for example `get_weather: {"temp":"16.1"}`.
[AI NVIDIA NeMo Guardrail](/ai-gateway/policies/ai-nvidia-nemo-guardrail/) and [AI Lakera Guard](/ai-gateway/policies/ai-lakera-guard/) receive a `messages` array with roles instead of one block of text, and the selection works the same way.
The text omits role names, identifiers, call status, signatures, and encrypted reasoning, because a guardrail can't evaluate them as words.

## Use cases

### Newest user message

Screening only the newest user message keeps the guardrail focused on what the user just asked, and avoids paying to re-screen earlier turns on every request.
It is the narrowest selection for chat traffic.

```yaml
config:
  message_selection:
    user:
      message_countback: 1
```

`message_countback` counts only messages that carry content of that key's kind.
`user` with `message_countback: 1` is therefore the newest user message, even when the conversation ends with tool messages.

<!-- TODO: Confirm with engineering how this behaves on native Anthropic and Bedrock bodies, where a tool result sits inside a user-role message. In PR 24277 message_feeds always feeds `user` for a user-role message, so the budget could be spent on a message that holds only tool results. No spec covers it. -->

### Tool output

Tool results come from outside your control, such as a web page, a file, or an API response.
An attacker can plant instructions in that content, and the model reads it as if it were trustworthy.
Selecting `tool_result` sends that output to the guardrail.

To inspect only the latest tool result:

```yaml
config:
  message_selection:
    tool_result:
      message_countback: 1
```

To inspect every tool result in the conversation, use `tool_result: {}`.

Each result is sent as `tool_name: output`, so the guardrail knows which tool produced it.
A result that the provider marks as failed is sent as `tool_name: error: output`.
The text of each result is sent, and media inside a result that also holds text stays in {{site.ai_gateway}}.

<!-- TODO: Confirm with engineering what native bodies send for a tool result whose content has no text entries, such as an image-only Anthropic result. In PR 24277, block_text falls back to JSON-encoding the value, which could include base64 data. No spec covers it. -->

### Agent loops

In an agent loop, each turn sends the whole history again.
A selection like `tool_result: {}` therefore sends every earlier tool result again on every call.
Setting `scope: round` screens each tool result once, on the turn where the model first sees it.

```yaml
config:
  message_selection:
    user:
      scope: round
    tool_result:
      scope: round
```

A round is everything after the last assistant message, which is the content the model hasn't seen yet.
If the conversation doesn't contain an assistant message yet, the round starts at the first message.

{% table %}
columns:
  - title: Conversation
    key: conversation
  - title: Round
    key: round
rows:
  - conversation: |
      `[user A]`
    round: |
      `[user A]`
  - conversation: |
      `[user A, assistant (tool call), tool result r1]`
    round: |
      `[r1]`
  - conversation: |
      `[user A, assistant (tool call 1), r1, assistant (tool call 2), r2]`
    round: |
      `[r2]`
  - conversation: |
      `[..., assistant (answer), user B]`
    round: |
      `[user B]`
{% endtable %}

### Tool calls

Selecting `tool_call` inspects the actions the model requested, instead of the data that came back.
Each call is sent as `tool_name(arguments)`, so a deny rule can match a specific tool or dangerous arguments.

```yaml
config:
  message_selection:
    tool_call: {}
```

This also covers tools that the model provider runs on its own side, such as a web search or a code interpreter.
To inspect a call together with what it returned, name both keys:

```yaml
config:
  message_selection:
    tool_call:
      message_countback: 1
    tool_result:
      message_countback: 1
```

### System prompt

The Policy sends the system prompt only when you name `system`.
A selection that names `user` and `tool_result` never sends it, so your own instructions don't reach the guardrail service or trigger its rules.

To inspect the system prompt, for example to verify that upstream components haven't altered it, name it:

```yaml
config:
  message_selection:
    system: {}
```

This works for chat-style bodies, where the system prompt is a message.
It also works for native Anthropic, Bedrock, and Gemini bodies, where the system prompt sits outside the messages array.

### Answer text

An assistant message can hold the answer text, tool calls, and reasoning.
Each one is a separate key, so you can inspect the answer without sending tool call arguments or reasoning to a third-party service.

```yaml
config:
  message_selection:
    assistant:
      message_countback: 1
```

Select `reasoning` to inspect the reasoning on its own.

{:.info}
> On a request, `reasoning` with `scope: round` selects nothing. Reasoning lives inside assistant messages, and a round starts after the last assistant message.

### Masking

[AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/) and [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) can mask content instead of blocking it.
Their guardrail services return one masked text for the whole request, so the Policy needs exactly one message to write that text back into.

<!-- TODO: Confirm with engineering that AI Custom Guardrail masks. In PR 24277 only the AI AWS Guardrails handler has masked write-back code, and a comment in the ai-custom-guardrail schema says its response template carries only block and block_message. The save-time check applies to both Policies. -->

When you set `allow_masking`, select one message:

```yaml
config:
  allow_masking: true
  message_selection:
    user:
      message_countback: 1
```

You can mask `user`, `system`, or `tool_result`, each with `message_countback: 1`.
`assistant`, `tool_call`, and `reasoning` can't be masked, because they don't have a single text field to write into.
{{site.ai_gateway}} rejects a configuration that selects more than one key or more than one message when you save it.

To mask across several messages, keep using the legacy fields.

{:.info}
> A masked Policy doesn't read a native system prompt, because it isn't a message. On a native body, a Policy that sets `allow_masking` and names only `system` has an empty selection, so the guardrail doesn't run.

### Model responses

[AI Semantic Response Guard](/ai-gateway/policies/ai-semantic-response-guard/) inspects what the model returns.
It accepts a narrower set of keys, because a response holds one turn from the model:

* It accepts `assistant`, `tool_call`, `tool_result`, and `reasoning`, and rejects `user` and `system`.
* It accepts only `scope: history`, because a response doesn't have a round.
* `tool_result` selects the output of tools that the provider runs on its own side. Tools that you run yourself answer in the next request, so they never appear in a response.
* It doesn't support masking, so you can't combine `allow_masking` with a selection.
* It doesn't support `message_selection` on routes that use passthrough mode.

To check the answer text and leave tool calls out:

```yaml
config:
  message_selection:
    assistant: {}
```

#### Streamed responses

<!-- TODO: The buffering switch is implemented in Kong/kong-ee PR 24277 (can_streaming = false and enable_buffering in the response guard handler, guard-buffering filter). Chunk cutting of streamed responses depends on Kong/kong-ee PR 24360, which hasn't been reviewed, and this section doesn't describe it. Confirm with engineering that both ship in 2.4. -->

A selection that names only `assistant` keeps streaming, and the Policy inspects the answer text as it arrives.

A selection that names `tool_call`, `reasoning`, or `tool_result` turns buffering on, because that content isn't available in the stream.
The Policy then guards the whole response once it is complete.
Choose `assistant` alone if you need the response to keep streaming.

{:.warning}
> Selecting `tool_call`, `reasoning`, or `tool_result` turns off streaming for the response, so clients receive it only after it is complete.

## Empty selections

When a selection matches nothing, the Policy skips the guardrail service call and the request continues.
For example, `tool_result` with `scope: round` on a request without a tool result passes without a guard call.

Most guardrail Policies skip a selection that matches nothing only when `message_selection` is set.
AI Azure Content Safety, AI NVIDIA NeMo Guardrail, and AI Sanitizer skip a blank prompt in every configuration.

Most guardrail Policies still fail the request when {{site.ai_gateway}} can't read the request body at all.
AI Azure Content Safety skips the check instead.

{:.warning}
> A selection that matches nothing isn't inspected. Check that your selection covers the content you need to guard. For example, `tool_result` with `scope: round` doesn't inspect user messages.

## Migrate from legacy fields

{:.warning}
> Two changes in {{site.ai_gateway}} 2.4 affect existing guardrail Policies even if you don't set `message_selection`.
> Concatenated text now goes oldest first, and `concatenate_all_content` on a native route now includes the system prompt.
> Review any anchored allow or deny patterns. See [Behavior changes](#behavior-changes).

The legacy fields keep working and keep their meaning.
Nothing changes for a Policy until you set `message_selection`.
When you set both, `message_selection` wins, so you can roll back by removing it.

The legacy fields are deprecated and will be removed in 3.0.0.
The Admin API warns when you use them.

### Mapping

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
  - legacy: |
      AI Prompt Guard: `allow_all_conversation_history: true`
    selection: |
      `user: {message_countback: 1}`
  - legacy: |
      AI Prompt Guard: `match_all_roles: true` and `allow_all_conversation_history: false`
    selection: |
      `user: {}`, `assistant: {}`, `tool_result: {}`, `system: {}`
  - legacy: |
      AI Prompt Guard: both fields `false`
    selection: |
      `user: {}`
  - legacy: |
      AI Sanitizer: `allow_all_conversation_history: true`
    selection: |
      `user: {}`
  - legacy: |
      AI Sanitizer: `allow_all_conversation_history: false`
    selection: |
      `user: {message_countback: 1}`
  - legacy: |
      AI Semantic Prompt Guard: `rules.match_all_conversation_history: false`
    selection: |
      `user: {message_countback: 1}`
  - legacy: |
      AI Semantic Prompt Guard: `rules.match_all_conversation_history: true` and `rules.match_all_roles: false`
    selection: |
      `user: {}`
  - legacy: |
      AI Semantic Prompt Guard: `rules.match_all_conversation_history: true` and `rules.match_all_roles: true`
    selection: |
      `user: {}`, `assistant: {}`, `tool_result: {}`, `system: {}`
{% endtable %}

`rules.match_all_roles` has no effect in AI Semantic Prompt Guard when `rules.match_all_conversation_history` is `false`.

AI Prompt Guard rejects `match_all_roles: true` combined with `allow_all_conversation_history: true`. When you set `message_selection`, that check doesn't apply.

{:.info}
> `allow_all_conversation_history` has opposite meanings in AI Prompt Guard and AI Sanitizer. In AI Prompt Guard, `true` ignores the history. In AI Sanitizer, `true` keeps it. The mapping accounts for this, and `message_selection` has one meaning in every Policy.

### Steps

1. Translate the Policy using the mapping.
1. Set `message_selection` and leave the legacy fields in place for one release.
1. Review your allow and deny patterns, as described in [Behavior changes](#behavior-changes).
1. Remove the legacy fields before 3.0.0.

### Behavior changes

Some behavior changes whether or not you set `message_selection`:

* A Policy that concatenates messages now sends them oldest first. They were previously sent newest first, so a pattern anchored at the start of the text now meets the oldest message.
* A `text_source: concatenate_all_content` Policy on a native route now includes the system prompt, which that value always promised.

A Policy that moves to `message_selection` also gains words that the legacy path never sent:

* Each tool result is prefixed with the tool name, and failed results carry an `error:` mark.
* A selection that names `tool_call` adds the calls.

<!-- TODO: Confirm with engineering whether the tool name prefix and error mark also apply to legacy Policies on native Anthropic, Bedrock, and Gemini bodies. In PR 24277 the native walkers call render_tool_output without checking decorate_results, and no spec covers it. -->

Patterns without an anchor don't need changes.

### Limits

* `message_selection` requires {{site.ai_gateway}} 2.4 or later. Konnect doesn't send the field to an older data plane, so a Policy that sets it can't run there.
* Masking supports one message only. See [Masking](#masking).
