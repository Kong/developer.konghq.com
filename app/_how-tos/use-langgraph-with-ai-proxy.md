---
title: Use LangGraph with AI Proxy in Kong AI Gateway
content_type: how_to
related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: Use LangChain with AI Proxy
    url: /how-to/langchain-ai-proxy/

description: Connect your LangGraph workflows with Kong AI Gateway.
permalink: /how-to/use-langgraph-with-ai-proxy
products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy
  - key-auth

entities:
  - service
  - route
  - plugin

tags:
    - ai
    - openai

tldr:
    q: How can I use my LangGraph workflows with AI Gateway?
    a: Configure LangGraph to use your AI Gateway Route by replacing the `base_url` parameter in the LangChain model instantiation with your proxy URL. LangGraph uses LangChain models for LLM calls.

tools:
    - deck

prereqs:
  inline:
  - title: OpenAI
    include_content: prereqs/openai
    icon_url: /assets/icons/openai.svg
  - title: Python
    include_content: prereqs/python
    icon_url: /assets/icons/python.svg
  - title: LangGraph
    content: |
      Install LangGraph and the LangChain OpenAI integration:
      ```sh
      pip3 install -U langgraph langchain-openai
      ```
    icon_url: /assets/icons/python.svg
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the AI Proxy plugin

Enable the [AI Proxy](/plugins/ai-proxy/) plugin with your OpenAI API key and the model details. In this example, we'll use the GPT-4o model. The AI Proxy plugin authenticates with OpenAI using your API key and proxies client requests to the specified model endpoint.

{% entity_examples %}
entities:
    plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_key}
        model:
          provider: openai
          name: gpt-4o
variables:
  openai_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Add authentication

To secure the access to your Route, let's create a Consumer and set up a [Key Auth](/plugins/key-auth/) plugin.

{:.info}
> LangChain's OpenAI client expects authentication in the `Authorization` header with the format `Bearer <token>`.
You can use plugins like [OAuth 2.0 Authentication](/plugins/oauth2/) or [OpenID Connect](/plugins/openid-connect/) to generate Bearer tokens.
In this example, for testing purposes, we'll recreate this pattern using the [Key Authentication](/plugins/key-auth/) plugin.

{% entity_examples %}
entities:
    plugins:
    - name: key-auth
      route: example-route
      config:
        key_names:
        - Authorization
    consumers:
    - username: ai-user
      keyauth_credentials:
      - key: Bearer my-api-key
{% endentity_examples %}

## Create a LangGraph script

Use the following command to create a file named `app.py` containing a LangGraph Python script:
```bash
cat <<EOF > app.py
from typing import TypedDict
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph

kong_url = "http://127.0.0.1:8000"
kong_route = "anything"

llm = ChatOpenAI(
    base_url=f"{kong_url}/{kong_route}",
    model="gpt-4o",
    api_key="my-api-key"
)

class State(TypedDict):
    messages: list
    summary: str

def gather_info(state: State) -> State:
    response = llm.invoke("What are three benefits of using an AI gateway?")
    state["messages"].append(response.content)
    return state

def summarize(state: State) -> State:
    response = llm.invoke(f"Summarize this in one sentence: {state['messages']}")
    state["summary"] = response.content
    return state

builder = StateGraph(State)
builder.add_node("gather", gather_info)
builder.add_node("summarize", summarize)
builder.add_edge("gather", "summarize")
builder.set_entry_point("gather")
builder.set_finish_point("summarize")
graph = builder.compile()

result = graph.invoke({"messages": [], "summary": ""})
print(f"Summary: {result['summary']}")
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }
```bash
cat <<EOF > app.py
from typing import TypedDict
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph
import os

kong_url = os.environ['KONNECT_PROXY_URL']
kong_route = "anything"

llm = ChatOpenAI(
    base_url=f"{kong_url}/{kong_route}",
    model="gpt-4o",
    api_key="my-api-key"
)

class State(TypedDict):
    messages: list
    summary: str

def gather_info(state: State) -> State:
    response = llm.invoke("What are three benefits of using an AI gateway?")
    state["messages"].append(response.content)
    return state

def summarize(state: State) -> State:
    response = llm.invoke(f"Summarize this in one sentence: {state['messages']}")
    state["summary"] = response.content
    return state

builder = StateGraph(State)
builder.add_node("gather", gather_info)
builder.add_node("summarize", summarize)
builder.add_edge("gather", "summarize")
builder.set_entry_point("gather")
builder.set_finish_point("summarize")
graph = builder.compile()

result = graph.invoke({"messages": [], "summary": ""})
print(f"Summary: {result['summary']}")
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

This script defines a two-node state graph. The first node (`gather`) queries the LLM and appends the response to the messages list. The second node (`summarize`) generates a summary from those messages. LangGraph maintains the `State` object across node transitions and executes nodes in the order defined by the graph edges.

The `base_url` parameter replaces the default OpenAI API endpoint (`https://api.openai.com/v1`) with your {{site.base_gateway}} Route URL. Requests from the LangChain client now route through {{site.base_gateway}}, where configured plugins (AI Proxy, Key Auth) process them before forwarding to OpenAI.

## Validate

Run your script to validate that LangGraph can access the Route:

{% validation custom-command %}
command: python3 ./app.py
expected:
  return_code: 0
render_output: false
{% endvalidation %}

The response should look like this:
```sh
============================================================
SUMMARY:
============================================================
An AI gateway acts as an intermediary, streamlining integration, scalability, and security for AI model access and interaction, benefiting developers by simplifying integration, managing high demand efficiently, and enforcing robust security protocols.
```
{:.no-copy-code}
