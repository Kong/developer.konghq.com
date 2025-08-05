---
title: Use Agno with AI Proxy in Kong AI Gateway
content_type: how_to

description: Connect Agno’s research agents to Kong AI Gateway with no code changes, enabling OpenAI-compatible inference through a proxy.

tldr:
  q: How can I use Agno with Kong AI Gateway?
  a: Configure the AI Proxy plugin on a Kong AI Gateway Route to forward OpenAI-compatible requests to OpenAI, and set Agno’s `base_url` to that Route. This lets you use Agno’s research agents with Kong plugins—such as logging, rate limiting, prompt decoration, and access control.

related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: What is Agno?
    url: https://docs.agno.com/introduction
    icon: assets/icons/agno.svg

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

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - ai-gateway

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

automated_tests: false
---
## Configure the AI Proxy plugin

Enable the [AI Proxy](/plugins/ai-proxy/) plugin with your OpenAI API key and model details to route Agno’s OpenAI-compatible requests through Kong AI Gateway. In this example, we'll use the `gpt-4.1` model from OpenAI.

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
          name: gpt-4.1
variables:
  openai_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

{:. warning}
> Make sure that the AI Proxy plugin and the Agno script are configured to use the same OpenAI model.

## Install required packages

{% navtabs "Historical Agent" %}
{% navtab "WSL2, Linux, macOS native" %}

```sh
pip3 install -U agno openai duckduckgo-search newspaper4k lxml_html_clean
```
Install the necessary Python packages for running the Agno's research agent:

{% endnavtab %}
{% navtab "macOS, with Python via Homebrew" %}

```sh
python3 -m venv .venv
source .venv/bin/activate

pip3 install -U agno openai duckduckgo-search newspaper4k lxml_html_clean
```
{% endnavtab %}
{% endnavtabs %}


## Create an Agno script for research agent

Use the following command to create a file named `research-agent.py` containing an Agno Python script:

```sh
cat <<EOF > research-agent.py

import os

from textwrap import dedent

from agno.agent import Agent
from agno.models.openai import OpenAILike
from agno.tools.duckduckgo import DuckDuckGoTools
from agno.tools.newspaper4k import Newspaper4kTools
from agno.models.openai.chat import Message

import os

model = OpenAILike(
    base_url="http://localhost:8000/anything",
    name="gpt-4.1",
    id="gpt-4.1",
    api_key=os.getenv("DECK_OPENAI_API_KEY")
)


research_agent = Agent(
    model=model,
    tools=[DuckDuckGoTools(), Newspaper4kTools()],
    description=dedent("""\
        You are a historical analyst with deep expertise in ancient and medieval history.
        Your expertise includes:

        - Synthesizing academic research and primary sources
        - Analyzing military, economic, and political systems
        - Identifying root causes of societal collapse or transformation
        - Evaluating the role of leadership, ideology, and religion
        - Presenting competing historical perspectives
        - Providing clear, source-backed historical narratives
        - Explaining long-term implications and legacy
    """),
    instructions=dedent("""\
        1. Research Phase 📚
           - Locate academic analyses, historical summaries, and expert commentary
           - Identify internal and external factors contributing to the fall
           - Note military conflicts, economic instability, and political fragmentation

        2. Analysis Phase 🔍
           - Weigh the long-term structural issues versus short-term triggers
           - Consider geopolitical pressures, internal weaknesses, and cultural shifts
           - Highlight contributions of leadership decisions and external actors

        3. Reporting Phase 📝
           - Write a compelling executive summary and clear narrative
           - Structure by thematic causes (military, political, economic, religious)
           - Include quotes or viewpoints from notable historians
           - Present lessons learned or possible historical counterfactuals

        4. Review Phase ✔️
           - Validate all claims against reputable sources
           - Ensure neutrality and historical rigor
           - Provide a bibliography or references list
    """),
    expected_output=dedent("""\
        # The Fall of the Byzantine Empire: A Tapestry of Decline and Siege ⚔️

        ## Executive Summary
        {Short summary}

        ## Introduction
        {Short historical background}

        ## Causes of Decline
        {Two causes}

        ---
        Report by Historical Analysis AI
        Published: {current_date}
        Last Updated: {current_time}
        """),
    markdown=True,
    show_tool_calls=True,
    add_datetime_to_instructions=True,
)


if __name__ == "__main__":
    prompt = "What were the main causes of the fall of the Byzantine Empire?"
    print("The Agent Chronicler is compiling historical manuscripts ...\n")
    research_agent.print_response(
        prompt,
        stream=True,
    )
EOF
```
{: data-deployment-topology="on-prem" }


```sh
cat <<EOF > research-agent.py

import os

from textwrap import dedent

from agno.agent import Agent
from agno.models.openai import OpenAILike
from agno.tools.duckduckgo import DuckDuckGoTools
from agno.tools.newspaper4k import Newspaper4kTools
from agno.models.openai.chat import Message


model = OpenAILike(
    base_url=os.getenv("KONG_PROXY_URL"),
    name="gpt-4.1",
    id="gpt-4.1",
    api_key=os.getenv("DECK_OPENAI_API_KEY"),
)


research_agent = Agent(
    model=model,
    tools=[DuckDuckGoTools(), Newspaper4kTools()],
    description=dedent("""\
        You are a historical analyst with deep expertise in ancient and medieval history.
        Your expertise includes:

        - Synthesizing academic research and primary sources
        - Analyzing military, economic, and political systems
        - Identifying root causes of societal collapse or transformation
        - Evaluating the role of leadership, ideology, and religion
        - Presenting competing historical perspectives
        - Providing clear, source-backed historical narratives
        - Explaining long-term implications and legacy
    """),
    instructions=dedent("""\
        1. Research Phase 📚
           - Locate academic analyses, historical summaries, and expert commentary
           - Identify internal and external factors contributing to the fall
           - Note military conflicts, economic instability, and political fragmentation

        2. Analysis Phase 🔍
           - Weigh the long-term structural issues versus short-term triggers
           - Consider geopolitical pressures, internal weaknesses, and cultural shifts
           - Highlight contributions of leadership decisions and external actors

        3. Reporting Phase 📝
           - Write a compelling executive summary and clear narrative
           - Structure by thematic causes (military, political, economic, religious)
           - Include quotes or viewpoints from notable historians
           - Present lessons learned or possible historical counterfactuals

        4. Review Phase ✔️
           - Validate all claims against reputable sources
           - Ensure neutrality and historical rigor
           - Provide a bibliography or references list
    """),
    expected_output=dedent("""\
        # The Fall of the Byzantine Empire: A Tapestry of Decline and Siege ⚔️

        ## Executive Summary
        {Short summary}

        ## Introduction
        {Short historical background}

        ## Causes of Decline
        {Two causes}

        ---
        Report by Historical Analysis AI
        Published: {current_date}
        Last Updated: {current_time}
        """),
    markdown=True,
    show_tool_calls=True,
    add_datetime_to_instructions=True,
)


if __name__ == "__main__":
    prompt = "What were the main causes of the fall of the Byzantine Empire?"
    print("The Agent Chronicler is compiling historical manuscripts ...\n")
    research_agent.print_response(
        prompt,
        stream=True,
    )
EOF
```
{: data-deployment-topology="konnect" }

With the `base_url` parameter, we can override the OpenAI base URL that LangChain uses by default with the URL to our {{site.base_gateway}} Route. This way, we can proxy requests and apply {{site.base_gateway}} plugins, while also using Agno integrations and tools.

## Validate

Run your script to validate that Agno agent can access the Route:

```sh
python3 research-agent.py
```

The response should look like this:

<img src="/assets/images/ai-gateway/agno-response.png"/>


