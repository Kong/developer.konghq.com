---
title: Saving LLM usage costs with AI Proxy Advanced load balancing
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
      content: |
          To complete this tutorial, you must have a [Redis stack](https://redis.io/docs/latest/) configured in your environment.
          Set your Redis host as an environment variable:
          ```sh
          export DECK_REDIS_HOST='YOUR-REDIS-HOST'
          ```
      icon_url: /assets/icons/redis.svg
    - title: PgVector (optional)
      content: |
        Test
      icon_url: /assets/icons/database.svg
    - title: Langchain splitters
      content: |
        To complete this tutorial, you'll need **Python (version 3.7 or later)*- and `pip` installed on your machine. You can verify it by running:

        ```bash
        python3
        python3 -m pip --version
         ```

        Once that's set up, install the required packages by running the following command in your terminal:
        ```
        python3 -m pip install langchain langchain_text_splitters requests
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
      Requests semantically matched to the "Specialist in python" category.
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
          threshold: 0.7
          redis:
            host: host.docker.internal
            port: 16379
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
            description: Specialist in python
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
            description: Requests related to IT support
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
> - **Technical coding (precision-focused):*- `code-davinci-002` with **temperature: 0*- — ensures consistent, deterministic code completions.
> - **IT support (balanced creativity):**
  `gpt-4o` with **temperature: 0.3*- — allows helpful, slightly creative answers without being too loose.
> - **Catchall/general queries (more creative):**
  `gpt-3.5-turbo` or `gpt-4o-mini` with **temperature: 0.7–1.0*- — encourages creative, varied responses for open-ended questions.
> Higher temperature values (closer to 1) increase randomness and creativity; lower values (closer to 0) make outputs more focused and predictable.

## Test the configuration


{% navtabs "Example prompts by model" %}

{% navtab "`gpt-3.5-turbo` (specialist in Python)" %}

These prompts are focused on Python coding and technical questions, leveraging gpt-3.5-turbo’s strength in programming expertise.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: How do I write a Python function?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Optimize this Python code snippet for speed
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

These examples target common IT support questions where gpt-4o’s balanced creativity and token limit suit troubleshooting and configuration help.

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
      content: How do I configure two-factor authentication on Windows 10 for our company network?
{% endvalidation %}

{% endnavtab %}

{% navtab "gpt-4o-mini (catchall)" %}

These catchall prompts reflect general or casual queries best handled by the lightweight gpt-4o-mini model.

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What’s the weather like today?
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Write a short poem about the beauty of autumn.
{% endvalidation %}

{% validation request-check %}
url: /anything
headers:
- 'Content-Type: application/json'
- 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Can you suggest some tips for improving creativity?
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}