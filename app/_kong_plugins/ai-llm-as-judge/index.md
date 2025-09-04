---
title: 'AI LLM as Judge'
name: 'AI LLM as Judge'

content_type: plugin

publisher: kong-inc
description: 'Evaluate and optimize your Large Language Models with accuracy'

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: ai-prompt-compressor.png

categories:
  - ai

tags:
  - ai

related_resources:
  - text: Compare LLM models accuracy using the AI LLM as Judge plugin
    url: /how-to/compare-llm-models-accuracy/
---
The **AI LLM as Judge** plugin enables automated evaluation of prompt-response pairs using a dedicated LLM. The plugin assigns a numerical score to LLM responses from 1 to 100, where:

* `1`: Perfect or ideal response
* `100`: Completely incorrect or irrelevant response

This plugin is part of the [**AI plugin suite**](/plugins/?category=ai), making it easy to integrate LLM-based evaluation workflows into your API pipelines.

## Features

The AI LLM as Judge plugin offers several configurable features that control how the LLM evaluates prompts and responses:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Description
    key: description
rows:
  - feature: "Configurable system prompt"
    description: "Instructs the LLM to act as a strict evaluator."
  - feature: "Numerical scoring"
    description: "Assigns a score from 1–100 to assess response quality."
  - feature: "History depth"
    description: "Includes previous chat messages for context when scoring."
  - feature: "Ignore prompts"
    description: "Options to ignore system, assistant, or tool prompts."
  - feature: "Sampling rate"
    description: "Controls probabilistic request volume for judging."
  - feature: "Native LLM schema"
    description: "Leverages Kong’s LLM schema for seamless integration."
{% endtable %}

## How it works

1. The plugin sends the user prompt and response to the configured LLM as a judge.
2. The LLM evaluates the response and returns a numeric score between `1` (ideal) and `100` (wrong or irrelevant).
3. This score can be used in downstream workflows, such as automated grading, feedback systems, or learning pipelines.

The following sequence diagram illustrates this simplified flow:

{% mermaid %}
sequenceDiagram
    actor User as User
    participant Plugin as AI LLM as Judge Plugin
    participant LLM as Configured LLM

    User->>Plugin: Sends prompt and response
    Plugin->>LLM: Forward data for evaluation
    LLM-->>Plugin: Returns numeric score (1 to 100)
    Plugin->>User: Score available for downstream workflows
{% endmermaid %}

## Recommended LLM settings

To ensure concise, consistent scoring, configure the LLM that acts as the judge with these values:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Recommended value
    key: value
  - title: Description
    key: description
rows:
  - setting: "[`temperature`](/plugins/ai-llm-as-judge/reference/#schema--config-llm-model-options-temperature)"
    value: "`2`"
    description: "Controls randomness. A lower value leads to a more deterministic output."
  - setting: "[`max_tokens`](/plugins/ai-llm-as-judge/reference/#schema--config-llm-model-options-max-tokens)"
    value: "`5`"
    description: "Maximum tokens for the LLM response."
  - setting: "[`top_p`](/plugins/ai-llm-as-judge/reference/#schema--config-llm-model-options-top-p)"
    value: "`1`"
    description: "Nucleus sampling probability; limits token selection."
{% endtable %}

{:.info}
> These settings produce short, precise numeric scores without extra text or verbosity.

