---
title: 'AI Prompt Decorator'
name: 'AI Prompt Decorator'

content_type: plugin

publisher: kong-inc
description: Prepend or append an array of llm/v1/chat messages to a user's chat history


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.6'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-prompt-decorator.png

categories:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model
---

The AI Prompt Decorator plugin adds an array of `llm/v1/chat` messages to either the start or end of an LLM consumer's chat history.
This allows you to pre-engineer complex prompts, or steer (and guard) prompts so that they aren't visible to users. 

You can use this plugin to pre-set a system prompt, set up specific prompt history, add words and phrases, or otherwise have more
control over how an LLM service is used when called via {{site.base_gateway}}.

{:.info}
> This plugin extends the functionality of the [AI Proxy plugin](/plugins/ai-proxy/), and requires AI Proxy to be configured first. To set up AI Proxy quickly, see [Get started with AI Gateway](/how-to/get-started-with-ai-gateway/).