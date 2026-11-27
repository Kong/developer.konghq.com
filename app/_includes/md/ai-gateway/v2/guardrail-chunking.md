{% assign window = include.window | default: 10000 %}
{% assign min_window = window | times: 0.8 | floor %}
{% if include.local %}
Set [`config.chunking.enabled`](./reference/#schema--config-chunking-enabled) to `true` to check a large {{ include.subject | default: 'text' }} in smaller parts.
The Policy checks every part, and one blocked part blocks the whole text.
{% elsif include.single_call %}
The {{ include.service | default: 'guardrail service' }} limits the size of each item it inspects.
If an item in {{ include.subject | default: 'a prompt or response' }} is larger, the call fails and nothing is inspected.
Set [`config.chunking.enabled`](./reference/#schema--config-chunking-enabled) to `true` to split large text into parts, so that each item fits.
{% else %}
Guardrail services limit the size of one request.
If {{ include.subject | default: 'a prompt or response' }} is larger than the {{ include.service | default: 'guardrail service' }} accepts, the call fails and nothing is inspected.
Set [`config.chunking.enabled`](./reference/#schema--config-chunking-enabled) to `true` to split the text into parts and inspect every part.
One blocked part blocks the whole text.
{% endif %}

Chunking is off by default, so upgrading changes nothing until you turn it on.
It requires {{site.ai_gateway}} 2.4 or later.
[{{ include.selection_label | default: 'Message selection' }}](#{{ include.selection_anchor | default: 'message-selection' }}) chooses what the Policy {% if include.local %}checks{% else %}sends{% endif %}.
Chunking splits that content when it is too large to {% if include.local %}check in one pass{% else %}send in one call{% endif %}.

### How chunking works

1. The Policy compares the text with [`config.chunking.max_chunk_size`](./reference/#schema--config-chunking-max-chunk-size), which defaults to {{ window }} characters on this Policy.
{% unless include.local %}   Set it to your service's limit, counted in characters.
{% endunless %}   The value must be between 1,000 and 1,000,000.
1. If the text is larger, the Policy cuts it at the last sentence end that falls between [`config.chunking.min_chunk_size`](./reference/#schema--config-chunking-min-chunk-size) and the window.
   If there isn't one, it cuts at whitespace, and otherwise at a character boundary.
   A cut never lands inside a multi-byte character.
{% if include.single_call %}
1. The Policy sends all parts to the service in one call.
{% else %}
1. The Policy checks the parts one at a time and stops at the first blocked part.
   To check several parts at once, raise [`config.chunking.parallelism`](./reference/#schema--config-chunking-parallelism).
{% endif %}
1. The block details in the logs name the part that blocked and the total number of parts.
{% unless include.local or include.single_call %}
Each part is one call, so a split text costs more calls and time.
With the default overlap, a 30,000-character prompt takes about 4 calls at a 10,000-character window and about 22 at a 1,500-character window.
{% endunless %}

{:.info}
> `min_chunk_size` must be between three quarters of `max_chunk_size` and `max_chunk_size`, and it defaults to {{ min_window }} characters on this Policy.
> When you change `max_chunk_size`, change `min_chunk_size` with it.
> {{site.ai_gateway}} rejects a configuration that sets only `max_chunk_size` when the default minimum falls outside that range.
{% if include.messages %}

This Policy sends a list of messages.
It splits the conversation into groups of whole messages that fit the window.
A single message larger than the window is split by text.
{% endif %}
{% if include.audit %}

The [audit logs](/ai-gateway/ai-audit-log-reference/) record how many calls the Policy made for each request and response.
In `verbose` rejection mode, the response also reports the blocked part in `detail.chunk`: `index` is the number of the part, starting at 1, and `count` is the total number of parts.
{% endif %}

### Tune the split

{% if include.single_call %}
{% table %}
columns:
  - title: Field
    key: field
  - title: Use it to
    key: use
rows:
  - field: "[`strategy`](./reference/#schema--config-chunking-strategy)"
    use: "Choose how the Policy cuts. `fixed_size` cuts inside a fixed window at a sentence end. `recursive` cuts at the coarsest separator in `recursive_separators` that fits the window, by default a paragraph break, then a line break, a sentence end, and a space."
  - field: "[`min_chunk_size`](./reference/#schema--config-chunking-min-chunk-size)"
    use: Set the shortest part the Policy cuts, so a short early sentence end doesn't produce a part much smaller than the window.
  - field: "[`overlap`](./reference/#schema--config-chunking-overlap)"
    use: "Set how many characters on each side of a cut the Policy sends again in a second call, so a value that a cut splits is still masked. This narrows the gap but doesn't close it, because a value longer than the overlap can still straddle two parts."
  - field: "[`timeout`](./reference/#schema--config-chunking-timeout)"
    use: Bound the whole check, both calls together. The `config.timeout` field bounds a single call.
{% endtable %}
{% else %}
{% table %}
columns:
  - title: Field
    key: field
  - title: Use it to
    key: use
rows:
  - field: "[`strategy`](./reference/#schema--config-chunking-strategy)"
    use: "Choose how the Policy cuts. `fixed_size` cuts inside a fixed window at a sentence end. `recursive` cuts at the coarsest separator in `recursive_separators` that fits the window, by default a paragraph break, then a line break, a sentence end, and a space."
  - field: "[`min_chunk_size`](./reference/#schema--config-chunking-min-chunk-size)"
    use: Set the shortest part the Policy cuts, so a short early sentence end doesn't produce a part much smaller than the window.
  - field: "[`overlap`](./reference/#schema--config-chunking-overlap)"
    use: "Share up to 1,000 characters between consecutive parts, so a pattern that crosses a boundary gets a second chance. This narrows the gap but doesn't close it, because a span longer than the overlap can still straddle two parts. The default is 100."
  - field: "[`parallelism`](./reference/#schema--config-chunking-parallelism)"
    use: "Send up to 32 calls at the same time. The default of `1` sends the parts one at a time. The Policy lowers the number of calls in flight when the service answers slowly. A very long text needs many calls, so raise this value, or `timeout`, when a check reaches the timeout."
  - field: "[`timeout`](./reference/#schema--config-chunking-timeout)"
    use: "Bound the whole check, all calls together, in milliseconds. The default is 30,000. When the check reaches it, the Policy stops. If `stop_on_error` is `true`, the request fails with an error. If it is `false`, the Policy doesn't inspect the rest of the text. The `config.timeout` field bounds a single call."
{% endtable %}
{% endif %}
{% if include.streaming %}

### Chunked streamed responses

For streamed responses, the Policy splits the answer text as it accumulates, so a call never carries more than `max_chunk_size` characters.

* [`response_buffer_size`](./reference/#schema--config-response-buffer-size) is the amount of answer text, counted in characters, that the Policy accumulates before it makes a call.
* `parallelism` doesn't apply to a stream.
* By default, the client reads the answer as the model writes it. A block that lands later reaches the client as a final event with `finish_reason: blocked_by_guard`, after the text that was already sent.
  To hold the answer back until the check clears it, set [`config.streaming.withhold_response`](./reference/#schema--config-streaming-withhold-response) to `true`. The answer then arrives one call behind, and a block replaces the blocked text.
{% endif %}
