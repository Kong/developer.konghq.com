---
title: LlamaIndex
description: Use LlamaIndex (Python) with {{site.ai_gateway_name}} to centralize model routing, provider credentials, authentication, and AI traffic controls.
url: "/ai-integrations/llamaindex/"
content_type: ai_integration
layout: ai_integration
products:
  - ai-gateway
tools:
  - deck
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
categories:
  - libraries
  - frameworks
featured: true

overview: |
  [LlamaIndex](https://www.llamaindex.ai/) is a Python framework for building LLM applications over your
  data: indexing, retrieval, query engines, and agents. Its OpenAI LLM can call any OpenAI-compatible
  endpoint, so you can point it at a {{site.ai_gateway_name}} Route instead of calling a provider directly.

  Your LlamaIndex code keeps using `complete`, `chat`, query engines, and agents, while the gateway owns
  the parts you do not want in the client: provider credentials, model selection, authentication,
  observability, guardrails, rate limiting, and semantic caching. You add or change those controls at
  the gateway without touching application code.
---

## Quick start

Point LlamaIndex's OpenAI LLM at a {{site.ai_gateway_name}} Route running on Kong Konnect, then use
LlamaIndex exactly as you normally would.

### Prerequisites

- Python 3.9+.
- A [Kong Konnect](https://konnect.konghq.com) account with a Gateway control plane and a running data
  plane. New to AI Gateway? Start with [Get started with AI Gateway](/ai-gateway/get-started/).
- A Route on that control plane with the [AI Proxy](/plugins/ai-proxy/) or
  [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin, plus an upstream provider key held by the
  Plugin. If you do not have one yet, see [Set up the Kong AI Gateway Route](#set-up-the-kong-ai-gateway-route).
- A Kong Konnect Personal Access Token (`kpat_...`) to configure the gateway with decK.

### Install

```bash
pip install -U llama-index-llms-openai
```

### Configure the LLM

Create a shared module that builds the OpenAI LLM with `api_base` set to your {{site.ai_gateway_name}}
Route instead of the OpenAI API:

```python
# kong_gateway.py
import os
from llama_index.llms.openai import OpenAI

llm = OpenAI(
    model="gpt-4o",
    # Your Kong Konnect AI Gateway proxy URL plus the Route path, not the OpenAI API.
    api_base=f"{os.environ['KONNECT_AI_GATEWAY_URL']}/llamaindex",
    # The upstream provider key lives in the gateway, so this value is not used.
    api_key="kong",
)
```

Set `KONNECT_AI_GATEWAY_URL` to your Konnect Gateway's proxy URL, the data plane endpoint that serves
your Routes:

```bash
export KONNECT_AI_GATEWAY_URL='https://your-gateway-host'
```

### Call the LLM

```python
from kong_gateway import llm

response = llm.complete('Write a concise release note for a new AI Gateway model routing policy.')
print(response.text)
```

Kong receives the request, injects the real provider credential, selects the upstream model, and
returns an OpenAI-compatible response. Every other LlamaIndex feature works the same way, because the
LLM is still speaking OpenAI's chat-completion protocol to Kong.

## Chat with messages

```python
from llama_index.core.llms import ChatMessage
from kong_gateway import llm

messages = [
    ChatMessage(role='system', content='You are an AI Gateway operations assistant.'),
    ChatMessage(role='user', content="Summarize today's model routing changes in two lines."),
]

print(llm.chat(messages).message.content)
```

## Stream responses

Use `stream_complete` to consume tokens as they are generated:

```python
from kong_gateway import llm

for chunk in llm.stream_complete('Stream a short checklist for safely launching an AI feature.'):
    print(chunk.delta, end='', flush=True)
```

## Query over your documents (RAG)

A query engine retrieves from an index and asks the model. Both the chat and embedding calls go through
Kong, each to a Route with the matching route type:

```bash
pip install -U llama-index llama-index-embeddings-openai
```

```python
import os
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
from llama_index.llms.openai import OpenAI
from llama_index.embeddings.openai import OpenAIEmbedding

gateway = os.environ['KONNECT_AI_GATEWAY_URL']

# Chat model on the llm/v1/chat Route; embeddings on the llm/v1/embeddings Route.
Settings.llm = OpenAI(model='gpt-4o', api_base=f'{gateway}/llamaindex', api_key='kong')
Settings.embed_model = OpenAIEmbedding(
    model='text-embedding-3-small',
    api_base=f'{gateway}/llamaindex-embeddings',
    api_key='kong',
)

documents = SimpleDirectoryReader('docs').load_data()
index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine()

print(query_engine.query('What controls does the gateway apply to LLM traffic?'))
```

## Build an agent

A `FunctionAgent` runs the model, calls your tools, and loops until it has an answer. All model and tool
traffic flows through Kong:

```bash
pip install -U llama-index
```

```python
import asyncio
from llama_index.core.agent.workflow import FunctionAgent
from kong_gateway import llm

def get_route_metrics(route_name: str) -> str:
    """Return request and error counts for an AI Gateway route."""
    return f'{route_name}: 14820 requests, 0.4% error rate'

agent = FunctionAgent(
    tools=[get_route_metrics],
    llm=llm,
    system_prompt='You are an AI Gateway operations assistant.',
)

async def main():
    response = await agent.run('Is the production chat route healthy?')
    print(response)

asyncio.run(main())
```

## Route to multiple models

Instead of hard-coding provider model names in your app, configure client-facing model aliases with
[AI Proxy Advanced](/plugins/ai-proxy-advanced/). The application sends an alias such as `fast` or
`smart`, and Kong maps it to a real upstream model. You can change the upstream model, swap providers,
or add load balancing at the gateway without redeploying the app.

Add a target per alias in your Kong configuration:

{%- raw %}
```yaml
plugins:
- name: ai-proxy-advanced
  config:
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: 'Bearer ${{ env "DECK_OPENAI_API_KEY" }}'
      model:
        provider: openai
        name: gpt-4o-mini
        model_alias: fast
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: 'Bearer ${{ env "DECK_OPENAI_API_KEY" }}'
      model:
        provider: openai
        name: gpt-4o
        model_alias: smart
```
{% endraw -%}

LlamaIndex's `OpenAI` class validates model names against known OpenAI models, so use `OpenAILike` to
send a gateway alias:

```bash
pip install -U llama-index-llms-openai-like
```

```python
import os
from llama_index.llms.openai_like import OpenAILike

base = f"{os.environ['KONNECT_AI_GATEWAY_URL']}/llamaindex"

# Fast, low-cost model for routine work.
quick = OpenAILike(model='fast', api_base=base, api_key='kong', is_chat_model=True)

# Higher-capability model for complex work. Only the alias changes.
detailed = OpenAILike(model='smart', api_base=base, api_key='kong', is_chat_model=True)
```

{:.info}
> Model aliases require {{site.ai_gateway_name}} 3.14 or later. On earlier versions, send the upstream
> model name directly, for example `OpenAI(model='gpt-4o', ...)`.

## Set up the Kong AI Gateway Route

If you do not already have a Route for LlamaIndex traffic, configure one with
[AI Proxy Advanced](/plugins/ai-proxy-advanced/) on your Kong Konnect Gateway control plane. The Plugin
owns the upstream provider credential, so the key never reaches the client.

Export the provider key for decK to inject:

```bash
export DECK_OPENAI_API_KEY='sk-YOUR-OPENAI-KEY'
```

Define a minimal chat-completions configuration in `kong.yaml`:

{%- raw %}
```yaml
_format_version: "3.0"

services:
- name: llamaindex
  # Placeholder upstream; AI Proxy Advanced overrides this and calls the provider.
  url: https://api.openai.com
  routes:
  - name: llamaindex
    paths:
    - /llamaindex
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    config:
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: 'Bearer ${{ env "DECK_OPENAI_API_KEY" }}'
        model:
          provider: openai
          name: gpt-4o
```
{% endraw -%}

Sync it to your Konnect control plane:

```bash
deck gateway sync kong.yaml \
  --konnect-addr https://us.api.konghq.com \
  --konnect-token 'kpat_YOUR-KONNECT-PAT' \
  --konnect-control-plane-name llamaindex
```

This syncs into the `llamaindex` Gateway control plane on Konnect. Change `--konnect-control-plane-name`
to target an existing control plane, and use `eu.api.konghq.com` or `au.api.konghq.com` if your Konnect
org is in the EU or AU region.

The LLM's `api_base` is your gateway proxy URL plus this Route path, for example
`https://your-gateway-host/llamaindex`. LlamaIndex appends `/chat/completions` to that base URL, which
matches the `llm/v1/chat` Route. For [RAG](#query-over-your-documents-rag), add a Route with the
`llm/v1/embeddings` route type and point `OpenAIEmbedding` at it.

## Add gateway controls without changing app code

Once the app points at Kong, platform teams can attach controls to the same Route without rewriting any
LlamaIndex code:

- [Key Authentication](/plugins/key-auth/) to identify the calling application.
- [Rate Limiting](/plugins/rate-limiting/) to enforce per-app request budgets.
- [AI Prompt Guard](/plugins/ai-prompt-guard/) or [AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/) to block unsafe prompts before they reach the provider.
- [AI Semantic Cache](/plugins/ai-semantic-cache/) to serve repeated prompts without another upstream call.
- [OpenTelemetry](/plugins/opentelemetry/) and logging Plugins to capture AI traffic data.

LlamaIndex sends its `api_key` as an `Authorization: Bearer` header. To use [Key Authentication](/plugins/key-auth/),
configure the plugin to read that header and store the Consumer credential with the `Bearer ` prefix:

{%- raw %}
```yaml
plugins:
- name: key-auth
  config:
    key_names:
    - Authorization
consumers:
- username: llamaindex-app
  keyauth_credentials:
  - key: Bearer my-api-key
```
{% endraw -%}

Then pass the key (without the prefix, which LlamaIndex adds) from the client:

```python
import os
from llama_index.llms.openai import OpenAI

llm = OpenAI(
    model='gpt-4o',
    api_base=f"{os.environ['KONNECT_AI_GATEWAY_URL']}/llamaindex",
    api_key=os.environ['KONNECT_AI_GATEWAY_KEY'],  # 'my-api-key'
)
```

## Troubleshooting

**The request returns 401 from Kong.** If the Route uses Key Authentication, confirm that LlamaIndex's
`api_key` matches the Consumer credential and that `key_names` includes `Authorization`.

**The upstream provider returns 401.** Confirm that `DECK_OPENAI_API_KEY` holds a valid provider key and
that the AI Proxy Advanced target injects it as the `Authorization` header with the `Bearer ` prefix.

**LlamaIndex raises an "unknown model" error for an alias.** The `OpenAI` class only accepts known
OpenAI model names. Use `OpenAILike` for gateway aliases such as `fast` or `smart`.

**Streaming buffers instead of returning tokens progressively.** Confirm that the Plugin uses
`response_streaming: allow` and that any infrastructure in front of Kong supports streaming responses.

## Next steps

- Use the [Basic LLM Routing cookbook](/cookbooks/basic-llm-routing/) for a deeper walkthrough of model aliases.
- Add [AI Semantic Cache](/plugins/ai-semantic-cache/) to reduce repeated LLM calls.
- Add [AI Prompt Guard](/plugins/ai-prompt-guard/) to enforce prompt policies.
- Review the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/) for providers, route types, and load-balancing options.
