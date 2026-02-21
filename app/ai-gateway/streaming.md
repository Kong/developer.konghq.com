---
title: "Streaming with {{site.ai_gateway}}"
content_type: reference
layout: reference

works_on:
 - on-prem
 - konnect

products:
  - ai-gateway
  - gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai
  - streaming
  - ai-proxy

plugins:
  - ai-proxy
  - ai-proxy-advanced

min_version:
  gateway: '3.7'

description: This guide walks you through setting up the AI Proxy and AI Proxy Advanced plugin with streaming.
---

## What is request streaming?

In an LLM (Large Language Model) inference request, {{site.base_gateway}} uses the upstream provider's REST API to generate the next chat message from the caller.
Normally, this request is processed and completely buffered by the LLM before being sent back to {{site.base_gateway}} and then to the caller in a single large JSON block. This process can be time-consuming, depending on the `max_tokens`, other request parameters, and the complexity of the request sent to the LLM model.

To avoid making the user wait for their chat response with a loading animation, most models can stream each word (or sets of words and tokens) back to the client. This allows the chat response to be rendered in real time.

For example, a client could set up their streaming request using the OpenAI Python SDK like this:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://127.0.0.1:8000/12/openai",
    api_key="none"
)

stream = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Tell me the history of Kong Inc."}],
    stream=True,
)

for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

The client won't have to wait for the entire response. Instead, tokens will appear as they come in.

## How AI Proxy streaming works

In streaming mode, a client can set `"stream": true` in their request, and the LLM server will stream each part of the response text (usually token-by-token) as a server-sent event.
{{site.base_gateway}} captures each batch of events and translates them into the {{site.base_gateway}} inference format. This ensures that all providers are compatible with the same framework including OpenAI-compatible SDKs or similar.

In a standard LLM transaction, requests proxied directly to the LLM look like this:

{% mermaid %}
sequenceDiagram
  actor Client
  participant {{site.base_gateway}}
  Note right of {{site.base_gateway}}: AI Proxy Advanced plugin
  Client->>+{{site.base_gateway}}:
  destroy {{site.base_gateway}}
  {{site.base_gateway}}->>+Cloud LLM: Sends proxy request information
  Cloud LLM->>+Client: Sends chunk to client
{% endmermaid %}

When streaming is requested, requests proxied directly to the LLM look like this:

{% mermaid %}
flowchart LR
  A(client)
  B({{site.base_gateway}} Gateway with
  AI Proxy Advanced plugin)
  C(Cloud LLM)
  D[[transform frame]]
  E[[read frame]]

subgraph main
direction LR
  subgraph 1
  A
  end
  subgraph 3
  C
  end
  subgraph 2
  D
  E
  end
  A --> B --request--> C
  C --response--> B
  B --> D-->E
  E --> B
  B --> A
end

  linkStyle 2,3,4,5,6 stroke:#b6d7a8,color:#b6d7a8
  style 1 color:#fff,stroke:#fff
  style 2 color:#fff,stroke:#fff
  style 3 color:#fff,stroke:#fff
  style main color:#fff,stroke:#fff
{% endmermaid %}

The streaming framework captures each event, sends the chunk back to the client, and then exits early.

It also estimates tokens for LLM services that decided to not stream back the token use counts when the message is completed.

## Streaming limitations

Keep the following limitations in mind when you configure streaming for the {{site.ai_gateway}} plugin:

* Multiple AI features shouldn’t be expected to be applied and work simultaneously.
* You can't use the [Response Transformer plugin](/plugins/response-transformer/) or any other response phase plugin when streaming is configured.
* The [AI Request Transformer plugin](/plugins/ai-request-transformer/) plugin **will** work, but the [AI Response Transformer plugin](/plugins/ai-response-transformer/) **will not**. This is because {{site.base_gateway}} can't check every single response token against a separate system.
* Streaming currently doesn't work with the HTTP/2 protocol. You must disable this in your [`proxy_listen`](/gateway/configuration/#proxy-listen) configuration.

## Configuration

The AI Proxy and AI Proxy Advanced plugins already support request streaming; all you have to do is request {{site.base_gateway}} to stream the response tokens back to you.

The following is an example `llm/v1/completions` route streaming request:

```json
{
  "prompt": "What is the theory of relativity?",
  "stream": true
}
```

You should receive each batch of tokens as HTTP chunks, each containing one or many server-sent events.

### Token usage in streaming responses {% new_in 3.13 %}

You can receive token usage statistics in an SSE streaming response. Set the following parameter in the request JSON:

```json
{
  "stream_options": {
    "include_usage": true
  }
}
```

When you set this parameter, the `usage` object appears in the final SSE frame, before the `[DONE]` terminator. This object contains token count statistics for the request.


The following example shows how to request and process token usage statistics in a streaming response:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://127.0.0.1:8000/openai",
    api_key="none"
)

stream = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Tell me the history of Kong Inc."}],
    stream=True,
    stream_options={"include_usage": True}
)

for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
    if chunk.usage:
        print("\nDONE. Usage stats:\n")
        print(chunk.usage)
```

{:.info}
> This feature works with any provider and model when `llm_format` is set to `openai` mode.
>
> See the [OpenAI API Documentation](https://platform.openai.com/docs/api-reference/chat/create#chat_create-stream_options) for more information on stream options.

### Response streaming configuration parameters

In the AI Proxy and AI Proxy Advanced plugin configuration, you can set an optional field `config.response_streaming` to one of three values:

{% table %}
columns:
  - title: Value
    key: value
  - title: Effect
    key: effect
rows:
  - value: "`allow`"
    effect: |
      Allows the caller to optionally specify a streaming response in their request (default is not-stream).
  - value: "`deny`"
    effect: |
      Prevents the caller from setting `stream=true` in their request.
  - value: "`always`"
    effect: |
      Always returns streaming responses, even if the caller hasn't specified it in their request.
{% endtable %}
