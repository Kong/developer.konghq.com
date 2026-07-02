---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI LLM as Judge Policy enables automated evaluation of prompt-response pairs using a dedicated LLM. The Policy assigns a numerical score to LLM responses from 1 to 100, where:

* `1`: Completely incorrect or irrelevant response
* `100`: Perfect or ideal response

## Features

The AI LLM as Judge Policy offers several configurable features that control how the LLM evaluates prompts and responses:

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
    description: "Leverages the LLM schema for seamless integration."
{% endtable %}

## How it works

1. {{site.ai_gateway}} sends the user prompt and response to the configured LLM as a judge.
2. The LLM evaluates the response and returns a numeric score between `1` (ideal) and `100` (wrong or irrelevant).
3. This score can be used in downstream workflows, such as automated grading, feedback systems, or learning pipelines.

The following sequence diagram illustrates this simplified flow:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    actor Client
    participant AIGW as {{site.ai_gateway}}
    participant LLM as LLM Model (A or B)
    participant Judge as AI LLM as Judge
    participant JudgeLLM as Judge LLM

    Client->>AIGW: Send prompt
    AIGW->>LLM: Forward prompt (balancer selects model)
    LLM-->>AIGW: Response
    AIGW ->>Judge: Prompt + response
    Judge->>JudgeLLM: Evaluate response
    JudgeLLM-->>Judge: Score (1–100)
    Judge-->>AIGW: Evaluation result
    AIGW-->>Client: Response
{% endmermaid %}
<!-- vale on -->
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
  - setting: "[`temperature`](/ai-gateway/policies/ai-llm-as-judge/reference/#schema--config-llm-model-options-temperature)"
    value: "`2`"
    description: "Controls randomness. A lower value leads to a more deterministic output."
  - setting: "[`max_tokens`](/ai-gateway/policies/ai-llm-as-judge/reference/#schema--config-llm-model-options-max-tokens)"
    value: "`5`"
    description: "Maximum tokens for the LLM response."
  - setting: "[`top_p`](/ai-gateway/policies/ai-llm-as-judge/reference/#schema--config-llm-model-options-top-p)"
    value: "`1`"
    description: "Nucleus sampling probability; limits token selection."
{% endtable %}

{:.info}
> These settings produce short, precise numeric scores without extra text or verbosity.