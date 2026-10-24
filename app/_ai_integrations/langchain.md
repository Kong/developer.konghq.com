---
title: LangChain
description: Use LangChain with {{site.ai_gateway_name}} to centralize model routing, provider credentials, authentication, and AI traffic controls.
url: "/ai-integrations/langchain/"
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
  [LangChain](https://www.langchain.com/) is a framework for building applications on top of LLMs:
  chains, retrieval, tools, and agents. Its OpenAI chat model (`ChatOpenAI`) can call any
  OpenAI-compatible endpoint, so you can point it at a {{site.ai_gateway_name}} Route instead of
  calling a provider directly.

  Your LangChain code keeps using `invoke`, `stream`, LCEL chains, `bind_tools`, and LangGraph agents,
  while the gateway owns the parts you do not want in the client: provider credentials, model selection,
  authentication, observability, guardrails, rate limiting, and semantic caching. You add or change
  those controls at the gateway without touching application code.

  The examples on this page use the Python SDK. LangChain.js works the same way: set `configuration.baseURL`
  on `ChatOpenAI` to your Route.
---

## Quick start

Point LangChain's `ChatOpenAI` model at a {{site.ai_gateway_name}} Route running on Kong Konnect, then
use LangChain exactly as you normally would.

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
pip install -U langchain-openai
```

### Configure the model

Create a shared module that builds `ChatOpenAI` with `base_url` set to your {{site.ai_gateway_name}}
Route instead of the OpenAI API:

```python
# kong_gateway.py
import os
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    # Your Kong Konnect AI Gateway proxy URL plus the Route path, not the OpenAI API.
    base_url=f"{os.environ['KONNECT_AI_GATEWAY_URL']}/langchain",
    model="gpt-4o",
    # The upstream provider key lives in the gateway, so this value is not used.
    api_key="kong",
)
```

Set `KONNECT_AI_GATEWAY_URL` to your Konnect Gateway's proxy URL, the data plane endpoint that serves
your Routes:

```bash
export KONNECT_AI_GATEWAY_URL='https://your-gateway-host'
```

### Invoke the model

```python
from kong_gateway import llm

response = llm.invoke('Write a concise release note for a new AI Gateway model routing policy.')
print(response.content)
```

Kong receives the request, injects the real provider credential, selects the upstream model, and
returns an OpenAI-compatible response. Every other LangChain feature works the same way, because the
model is still speaking OpenAI's chat-completion protocol to Kong.

## Stream responses

Use `stream` to consume tokens as they are generated:

```python
from kong_gateway import llm

for chunk in llm.stream('Stream a short checklist for safely launching an AI feature.'):
    print(chunk.content, end='', flush=True)
```

## Build a chain (LCEL)

LangChain Expression Language pipes a prompt into the model and an output parser. Kong stays on the
request path for every call in the chain:

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from kong_gateway import llm

prompt = ChatPromptTemplate.from_template(
    'Write a concise release note for: {feature}'
)
chain = prompt | llm | StrOutputParser()

print(chain.invoke({'feature': 'a new AI Gateway model routing policy'}))
```

## Use tools

Bind tools to the model with `bind_tools`. Tool calling works through Kong whenever the upstream model
supports it:

```python
from langchain_core.tools import tool
from kong_gateway import llm

@tool
def get_gateway_policy(route_name: str) -> dict:
    """Return the policy status for an AI Gateway route."""
    return {'route_name': route_name, 'auth': 'enabled', 'semantic_cache': 'enabled'}

llm_with_tools = llm.bind_tools([get_gateway_policy])
response = llm_with_tools.invoke('Check the AI Gateway policy for the production chat route.')

print(response.tool_calls)
```

## Build an agent

A LangGraph agent runs the model, calls your tools, and loops until it has an answer. All model and
tool traffic flows through Kong:

```bash
pip install -U langgraph
```

```python
from langgraph.prebuilt import create_react_agent
from kong_gateway import llm

def get_route_metrics(route_name: str) -> str:
    """Return request and error counts for an AI Gateway route."""
    return f'{route_name}: 14820 requests, 0.4% error rate'

agent = create_react_agent(llm, [get_route_metrics])
result = agent.invoke({
    'messages': [{'role': 'user', 'content': 'Is the production chat route healthy?'}],
})

print(result['messages'][-1].content)
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

Then select a model by alias with the same Route:

```python
import os
from langchain_openai import ChatOpenAI

base_url = f"{os.environ['KONNECT_AI_GATEWAY_URL']}/langchain"

# Fast, low-cost model for routine work.
quick = ChatOpenAI(base_url=base_url, model='fast', api_key='kong')

# Higher-capability model for complex work. Only the alias changes.
detailed = ChatOpenAI(base_url=base_url, model='smart', api_key='kong')
```

{:.info}
> Model aliases require {{site.ai_gateway_name}} 3.14 or later. On earlier versions, send the upstream
> model name directly, for example `model='gpt-4o'`.

## Generate embeddings

To embed text, point `OpenAIEmbeddings` at a Route configured with the `llm/v1/embeddings` route type:

```python
import os
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(
    base_url=f"{os.environ['KONNECT_AI_GATEWAY_URL']}/langchain-embeddings",
    model='text-embedding-3-small',
    api_key='kong',
)

vector = embeddings.embed_query('Kong AI Gateway centralizes routing, auth, and observability.')
print(len(vector))
```

## Set up the Kong AI Gateway Route

If you do not already have a Route for LangChain traffic, configure one with
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
- name: langchain
  # Placeholder upstream; AI Proxy Advanced overrides this and calls the provider.
  url: https://api.openai.com
  routes:
  - name: langchain
    paths:
    - /langchain
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
  --konnect-control-plane-name langchain
```

This syncs into the `langchain` Gateway control plane on Konnect. Change `--konnect-control-plane-name`
to target an existing control plane, and use `eu.api.konghq.com` or `au.api.konghq.com` if your Konnect
org is in the EU or AU region.

The model's `base_url` is your gateway proxy URL plus this Route path, for example
`https://your-gateway-host/langchain`. LangChain appends `/chat/completions` to that base URL, which
matches the `llm/v1/chat` Route. To support [embeddings](#generate-embeddings), add a Route with the
`llm/v1/embeddings` route type.

## Add gateway controls without changing app code

Once the app points at Kong, platform teams can attach controls to the same Route without rewriting any
LangChain code:

- [Key Authentication](/plugins/key-auth/) to identify the calling application.
- [Rate Limiting](/plugins/rate-limiting/) to enforce per-app request budgets.
- [AI Prompt Guard](/plugins/ai-prompt-guard/) or [AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/) to block unsafe prompts before they reach the provider.
- [AI Semantic Cache](/plugins/ai-semantic-cache/) to serve repeated prompts without another upstream call.
- [OpenTelemetry](/plugins/opentelemetry/) and logging Plugins to capture AI traffic data.

LangChain sends its `api_key` as an `Authorization: Bearer` header. To use [Key Authentication](/plugins/key-auth/),
configure the plugin to read that header and store the Consumer credential with the `Bearer ` prefix:

{%- raw %}
```yaml
plugins:
- name: key-auth
  config:
    key_names:
    - Authorization
consumers:
- username: langchain-app
  keyauth_credentials:
  - key: Bearer my-api-key
```
{% endraw -%}

Then pass the key (without the prefix, which LangChain adds) from the client:

```python
import os
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    base_url=f"{os.environ['KONNECT_AI_GATEWAY_URL']}/langchain",
    model='gpt-4o',
    api_key=os.environ['KONNECT_AI_GATEWAY_KEY'],  # 'my-api-key'
)
```

For a full walkthrough, see [Use LangChain with AI Proxy](/how-to/use-langchain-with-ai-proxy/).

## Troubleshooting

**The request returns 401 from Kong.** If the Route uses Key Authentication, confirm that LangChain's
`api_key` matches the Consumer credential and that `key_names` includes `Authorization`.

**The upstream provider returns 401.** Confirm that `DECK_OPENAI_API_KEY` holds a valid provider key and
that the AI Proxy Advanced target injects it as the `Authorization` header with the `Bearer ` prefix.

**The request does not match a target.** Confirm that the model in `ChatOpenAI`, such as `model='fast'`,
matches a `model.model_alias` (or `model.name`) in the AI Proxy Advanced configuration.

**Streaming buffers instead of returning tokens progressively.** Confirm that the Plugin uses
`response_streaming: allow` and that any infrastructure in front of Kong supports streaming responses.

## Next steps

- Follow the [Use LangChain with AI Proxy](/how-to/use-langchain-with-ai-proxy/) how-to for an end-to-end setup.
- Use the [Basic LLM Routing cookbook](/cookbooks/basic-llm-routing/) for a deeper walkthrough of model aliases.
- Add [AI Semantic Cache](/plugins/ai-semantic-cache/) to reduce repeated LLM calls.
- Review the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/) for providers, route types, and load-balancing options.
