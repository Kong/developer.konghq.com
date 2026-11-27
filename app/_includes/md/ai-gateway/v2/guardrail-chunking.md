{% assign window = include.window | default: 10000 %}
{% if include.local %}
Set [`config.chunk_text`](./reference/#schema--config-chunk-text) to `true` to check a large {{ include.subject | default: 'text' }} in smaller parts.
The Policy checks every part, and one blocked part blocks the whole text.
{% elsif include.single_call %}
The {{ include.service | default: 'guardrail service' }} limits the size of each item it inspects.
If an item in {{ include.subject | default: 'a prompt or response' }} is larger, the call fails and nothing is inspected.
Set [`config.chunk_text`](./reference/#schema--config-chunk-text) to `true` to split large text into parts, so that each item fits.
{% else %}
Guardrail services limit the size of one request.
If {{ include.subject | default: 'a prompt or response' }} is larger than the {{ include.service | default: 'guardrail service' }} accepts, the call fails and nothing is inspected.
Set [`config.chunk_text`](./reference/#schema--config-chunk-text) to `true` to split the text into parts and inspect every part.
One blocked part blocks the whole text.
{% endif %}

Chunking is off by default, so upgrading changes nothing until you turn it on.
It requires {{site.ai_gateway}} 2.4 or later.
[{{ include.selection_label | default: 'Message selection' }}](#{{ include.selection_anchor | default: 'message-selection' }}) chooses what the Policy {% if include.local %}checks{% else %}sends{% endif %}.
Chunking splits that content when it is too large to {% if include.local %}check in one pass{% else %}send in one call{% endif %}.

### How chunking works

1. The Policy compares the text with [`config.max_chunk_size`](./reference/#schema--config-max-chunk-size), which defaults to {{ window }} characters on this Policy.
{% unless include.local %}   Set it to your service's limit, counted in characters.
{% endunless %}
1. If the text is larger, the Policy cuts it at the end of a sentence near the end of the window.
   If there isn't one, it cuts at whitespace, and otherwise at a character boundary.
   A cut never lands inside a multi-byte character.
{% if include.single_call %}
1. The Policy sends all parts to the service in one call.
{% else %}
1. The Policy checks the parts one at a time and stops at the first blocked part.
{% endif %}
1. The block details in the logs name the part that blocked and the total number of parts.
{% unless include.local or include.single_call %}
Each part is one call, so a split text costs more calls and time.
A 30,000-character prompt takes about 3 calls at a 10,000-character window and about 21 at a 1,500-character window.
{% endunless %}
{% if include.messages %}
This Policy sends a list of messages.
It splits the conversation into groups of whole messages that fit the window.
A single message larger than the window is split by text.
{% endif %}
{% if include.audit %}
The [audit logs](/ai-gateway/ai-audit-log-reference/) record how many calls the Policy made for each request and response.
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
  - field: "[`chunk_min_text_size`](./reference/#schema--config-chunk-min-text-size)"
    use: Keep short texts in one part, even when they are larger than `max_chunk_size`.
  - field: "[`chunk_overlap`](./reference/#schema--config-chunk-overlap)"
    use: "Share characters between consecutive parts, so a pattern that crosses a boundary gets a second chance. This narrows the gap but doesn't close it, because a span longer than the overlap can still straddle two parts."
  - field: "[`max_parts`](./reference/#schema--config-max-parts)"
    use: "Cap the number of parts. The Policy refuses a text that needs more with an error."
{% endtable %}
{% else %}
{% table %}
columns:
  - title: Field
    key: field
  - title: Use it to
    key: use
rows:
  - field: "[`chunk_min_text_size`](./reference/#schema--config-chunk-min-text-size)"
    use: Keep short texts in one call, even when they are larger than `max_chunk_size`.
  - field: "[`chunk_overlap`](./reference/#schema--config-chunk-overlap)"
    use: "Share characters between consecutive parts, so a pattern that crosses a boundary gets a second chance. This narrows the gap but doesn't close it, because a span longer than the overlap can still straddle two parts."
  - field: "[`max_parts`](./reference/#schema--config-max-parts)"
    use: "Cap the number of parts. The Policy refuses a text that needs more with an error, so raise it together with `chunk_timeout` for very long texts."
  - field: "[`chunk_timeout`](./reference/#schema--config-chunk-timeout)"
    use: Bound the whole check. The `timeout` field bounds a single call.
{% endtable %}
{% endif %}
{% if include.streaming %}

### Chunked streamed responses

For streamed responses, the Policy splits the answer text as it accumulates, so a call never carries more than `max_chunk_size` characters.

* [`response_buffer_size`](./reference/#schema--config-response-buffer-size) counts characters, not bytes.
* `chunk_min_text_size`, `max_parts`, and `chunk_timeout` don't apply to a stream.
* When `chunk_text` is on and a response needs more than eight parts, the Policy logs a warning once and keeps checking, because the text has already reached the client.
{% endif %}
