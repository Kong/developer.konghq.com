---
title: Create AI usage tiers with {{site.base_gateway}}
content_type: how_to
related_resources:
  - text: AI Proxy Advanced plugin
    url: /plugins/ai-proxy-advanced/
  - text: AI Rate Limiting Advanced plugin
    url: /plugins/ai-rate-limiting-advanced/
  - text: Consumer Group API documentation
    url: /api/gateway/admin-ee/#/operations/get-consumer_groups

description: Control AI model usage costs across Consumer tiers by applying AI rate limits per group.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

tools:
  - deck

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced
  - ai-rate-limiting-advanced
  - key-auth

entities:
  - consumer
  - consumer-group
  - service
  - route
  - plugin

tags:
  - ai-gateway

tldr:
  q: How do I limit AI model usage by Consumer tier?
  a: |
    You can apply different AI usage limits for Free, Basic, and Premium Consumers using the [AI Rate Limiting Advanced plugin](/plugins/ai-rate-limiting-advanced/).
    This plugin uses model cost data from [AI Proxy Advanced](/plugins/ai-proxy-advanced/) to enforce cost-based usage caps per tier, ensuring fair access and predictable API costs.

faqs:
  - q: Why use cost-based rate limiting instead of token-based limits?
    a: Cost-based limits let you account for variable model pricing or response length. For example, a single GPT-4 completion could be expensive even if it uses few tokens, making cost-based quotas more predictable for multi-tier plans.

prereqs:
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

## Set up Consumer authentication

We'll use the [Key Auth plugin](/plugins/key-auth/) to authenticate Consumers and apply AI rate limiting based on their tier.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Create Consumer Groups for each AI usage tier

We'll create three Consumer Groups — Free, Basic, and Premium — to represent your pricing tiers.

{% entity_examples %}
entities:
  consumer_groups:
    - name: Free
    - name: Basic
    - name: Premium
{% endentity_examples %}

## Create Consumers

Each Consumer belongs to a group and uses a unique API key for authentication:

{% entity_examples %}
entities:
  consumers:
    - username: John
      groups:
        - name: Free
      keyauth_credentials:
        - key: john-key
    - username: Adam
      groups:
        - name: Basic
      keyauth_credentials:
        - key: adam-key
    - username: Eve
      groups:
        - name: Premium
      keyauth_credentials:
        - key: eve-key
{% endentity_examples %}

## Configure the AI Proxy

Next, set up [AI Proxy Advanced](/plugins/ai-proxy-advanced/) to route AI requests to OpenAI's GPT-4o model.
This assigns relative “cost units” for input and output that the rate limiter will track:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
                input_cost: 50
                output_cost: 50
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

{:.info}
> These cost values are relative units. They let you model usage budgets per request or per token batch. Adjust them to reflect your expected GPT-4o pricing ratios or your own credit system.

## Designing cost units for your tiers

The AI Gateway’s cost model is flexible — you can define your own **cost unit system** to match real model pricing or your product’s usage quotas.

Here’s a practical way to design your values:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: What it represents
    key: meaning
  - title: Example value
    key: example
  - title: Based on
    key: based_on
rows:
  - parameter: "`input_cost`"
    meaning: "Cost per 1 000 prompt tokens"
    example: "`0.05`"
    based_on: "GPT-4 input ≈ $0.01 per 1 K tokens"
  - parameter: "`output_cost`"
    meaning: "Cost per 1 000 completion tokens"
    example: "`0.10`"
    based_on: "GPT-4 output ≈ $0.03 per 1 K tokens"
  - parameter: "`limit` (per group)"
    meaning: "Total allowed cost per window"
    example: "50 / 200 / 1000"
    based_on: "Your pricing tier or plan budget"
  - parameter: "`window_size`"
    meaning: "Time window for the limit"
    example: "`60` seconds"
    based_on: "Rate-limit period"
{% endtable %}

Example mapping:
- **Free tier:** 50 cost units ≈ $0.50/min usage
- **Basic tier:** 200 cost units ≈ $2/min usage
- **Premium tier:** 1000 cost units ≈ $10/min usage

You can align these values to:
* Your **subscription plan budgets** (e.g., monthly credit allowances)
* Your **monetization strategy** (e.g., “1 cost unit = $0.01”)
* The **pricing** of the model provider (OpenAI, Anthropic, etc.)


## Apply cost-based AI rate limiting per Consumer Group

Now, enable the [AI Rate Limiting Advanced plugin](/plugins/ai-rate-limiting-advanced/) for each tier, using the `tokens_count_strategy: cost` mode.

{% entity_examples %}
entities:
  plugins:
    - name: ai-rate-limiting-advanced
      consumer_group: Free
      config:
        tokens_count_strategy: cost
        llm_providers:
          - name: openai
            limit: [10]        # Up to 50 cost units per minute
            window_size: [60]

    - name: ai-rate-limiting-advanced
      consumer_group: Basic
      config:
        tokens_count_strategy: cost
        llm_providers:
          - name: openai
            limit: [200]       # Up to 200 cost units per minute
            window_size: [60]

    - name: ai-rate-limiting-advanced
      consumer_group: Premium
      config:
        tokens_count_strategy: cost
        llm_providers:
          - name: openai
            limit: [1000]      # Up to 1000 cost units per minute
            window_size: [60]
{% endentity_examples %}

This setup creates usage tiers as follows:
* **Free:** Light usage, capped at 50 cost units per minute (around 5–10 small GPT-4o prompts).
* **Basic:** Moderate usage, capped at 200 cost units per minute.
* **Premium:** High usage, capped at 1000 cost units per minute.

## Validate AI rate limiting per tier

To test, send multiple chat requests via the AI Proxy endpoint with the corresponding API keys:

**Free tier test:**

{% validation rate-limit-check %}
iterations: 15
url: '/anything'
headers:
  - 'apikey:john-key'
method: POST
body:
  messages:
    - role: user
      content: |
        "Write a detailed philosophical reflection on the nature of consciousness, free will, and artificial intelligence. Discuss how modern neuroscience intersects with classic philosophical debates, and explore the implications of large language models and generative AI on human cognition, creativity, and society. Compare the perspectives of Plato, Aristotle, Descartes, Kant, Nietzsche, and contemporary thinkers like Daniel Dennett, David Chalmers, and Nick Bostrom. Then evaluate whether machines can ever meaningfully possess subjective qualia or experience phenomenal consciousness, or whether they remain fundamentally symbolic and statistical processors of data with no internal awareness.

        Provide multiple real-world examples, historical references, academic citations, and practical consequences of advanced AI development. Address concerns about alignment, agency, moral responsibility, digital personhood, and the role of emergent properties in complex computational systems. Include analogies to biology, evolution, mathematics, and quantum physics. Offer arguments both for and against the possibility of machine consciousness, then conclude with a balanced perspective on future co-evolution between humans and AI, covering governance, ethics, education, and public policy.

        Include a short fictional vignette imagining a future where AI entities petition for civil rights, and humans debate whether to recognize their personhood. Ensure emotional nuance, internal dialogue, and societal realism."
{% endvalidation %}

**Basic tier test:**

{% validation rate-limit-check %}
iterations: 20
url: '/anything'
headers:
  - 'apikey:adam-key'
method: POST
body:
  messages:
    - role: user
      content: "Hello!"
{% endvalidation %}

**Premium tier test:**

{% validation rate-limit-check %}
iterations: 60
url: '/anything'
headers:
  - 'apikey:eve-key'
method: POST
body:
  messages:
    - role: user
      content: "Hello!"
{% endvalidation %}
