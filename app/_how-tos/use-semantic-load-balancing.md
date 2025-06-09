---
title: Saving LLM usage costs with AI Proxy Advanced semantic load balancing
content_type: how_to
related_resources:
  - text: AI Gateway
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/

description: Configure the AI Proxy Advanced plugin to optimize LLM usage and reduce costs by intelligently routing chat requests across multiple OpenAI models based on semantic similarity.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai

tldr:
  q: How do I use the AI Proxy Advanced plugin with OpenAI to save costs?
  a: Set up the Gateway Service and Route, then enable the AI Proxy Advanced plugin. Configure it with OpenAI API credentials, use semantic routing with embeddings and Redis vector DB, and define multiple target models—specializing on task type—to optimize usage and reduce expenses.


tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Redis stack
      include_content: prereqs/redis
      icon_url: /assets/icons/redis.svg
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

faqs:
  - q: How should I balance temperature across models?
    a: |
      Use low temperature (for example, `0`) for deterministic outputs like code or calculations. Moderate values (for example, `0.3`) are good for IT help or troubleshooting. Use higher values (for example, `1.0`) for creative or open-ended prompts.

  - q: What’s a good default model for CATCHALL requests?
    a: |
      `gpt-4o-mini` is a good choice for general-purpose fallback. It’s fast, cost-effective, and can handle a wide variety of queries with creative flair.

  - q: How do I fine-tune model routing for semantic matching?
    a: |
      Adjust your `threshold` under `vectordb` config. A higher threshold (for example, `0.75`) routes only stronger matches to specific targets, while a lower value (for example, `0.6`) allows looser matches.

  - q: Should I assign different token limits per model?
    a: |
      Yes. Set higher `max_tokens` (for example, `826`) for complex or technical responses. Use smaller values (for example, `256`) for concise or cost-sensitive outputs.

  - q: Can temperature affect which model is selected?
    a: |
      Indirectly. Temperature influences output style and can help distinguish models during embedding training or similarity scoring. Use it to align behavior with intent categories.
---

## Configure AI Proxy Advanced Plugin

This configuration uses the AI Proxy Advanced plugin’s semantic load balancing to intelligently route requests. Queries are matched against model descriptions using vector embeddings, ensuring each request goes to the model best suited for its content. This helps improve response relevance while optimizing resource use and cost.

The table below outlines how different types of queries are semantically routed to specific models, optimizing response quality and cost efficiency.

<!-- vale off -->

{% table %}
columns:
  - title: Route
    key: route
  - title: Routed to model
    key: model
  - title: Description
    key: description
rows:
  - route: Queries about Python or technical coding
    model: gpt-3.5-turbo
    description: |
      Requests semantically matched to the "Expert in python programming" category.
      Handles complex coding or technical questions with deterministic output (temperature 0).
  - route: IT support related questions
    model: gpt-4o
    description: |
      Requests related to IT support topics are routed here.
      Uses moderate creativity (temperature 0.3) and a mid-sized token limit.
  - route: General or catchall queries
    model: gpt-4o-mini
    description: |
      Catchall for all other queries not strongly matched to other categories.
      Prioritizes cost efficiency and creative responses (temperature 1.0).
{% endtable %}


<!-- vale on -->

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        embeddings:
          auth:
            header_name: Authorization
            header_value: Bearer ${openai_api_key}
          model:
            provider: openai
            name: text-embedding-3-small
        vectordb:
          dimensions: 1024
          distance_metric: cosine
          strategy: redis
          threshold: 0.75
          redis:
            host: localhost
            port: 6379
        balancer:
          algorithm: semantic
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-3.5-turbo
              options:
                max_tokens: 826
                temperature: 0
            description: Expert in Python programming.

          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 0.3
            description: All IT support questions.

          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o-mini
              options:
                max_tokens: 256
                temperature: 1.0
            description: CATCHALL
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}


{:.info}
> You can also consider alternative models and temperature settings to better suit your workload needs. For example, specialized code models for coding tasks, full GPT-4 for nuanced IT support, and lighter models with higher temperature for general or creative queries.
> - **Technical coding (precision-focused):**- `code-davinci-002` with **temperature: 0*- — ensures consistent, deterministic code completions.
> - **IT support (balanced creativity):**
  `gpt-4o` with **temperature: 0.3*- — allows helpful, slightly creative answers without being too loose.
> - **Catchall/general queries (more creative):**
  `gpt-3.5-turbo` or `gpt-4o-mini` with **temperature: 0.7–1.0*- — encourages creative, varied responses for open-ended questions.
> Note that higher temperature values (closer to 1) increase randomness and creativity; lower values (closer to 0) make outputs more focused and predictable.

## Test the configuration

{% navtabs "Example prompts by model" %}

{% navtab "`gpt-3.5-turbo` (specialist in Python)" %}

These prompts are focused on Python coding and technical questions, leveraging gpt-3.5-turbo’s strength in programming expertise. The response to all related questions should return `"model": "gpt-3.5-turbo"`.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How do I write a Python function to calculate the factorial of a number?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How to implement a custom iterator class in Python
{% endvalidation %}

{% endnavtab %}

{% navtab "`gpt-4o` (IT support questions)" %}

These examples target common IT support questions where `gpt-4o`’s balanced creativity and token limit suit troubleshooting and configuration help. The response to all related questions should return `"model": "gpt-4o"`.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
  - role: user
    content: How do I reset my corporate email password?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
  - role: user
    content: My VPN keeps disconnecting; help me troubleshoot it?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How do I configure two-factor authentication on my corporate laptop?
{% endvalidation %}

{% endnavtab %}

{% navtab "`gpt-4o-mini` (Catchall model)" %}

These catchall prompts reflect general or casual queries best handled by the lightweight `gpt-4o-mini` model. The response to all related questions should return `"model": "gpt-4o-mini"`.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What is qubit?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How does hail form?
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}

{:.info}
> To optimize model usage and control input quality, combine semantic load balancing with the [AI Prompt Guard](/plugins/ai-prompt-guard/) plugin.
