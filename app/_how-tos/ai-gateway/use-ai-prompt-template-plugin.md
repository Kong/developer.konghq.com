---
title: Provide AI prompt templates for end users with the AI Prompt Template plugin and Mistral
permalink: /how-to/use-ai-prompt-template-plugin/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: AI Prompt Template
    url: /plugins/ai-prompt-template/

description: |
  Configure the AI Proxy plugin to route requests to a model provider like Mistral, then define reusable templates with the AI Prompt Template plugin to enforce consistent prompt formatting for tasks like summarization, code explanation, and Q&A.

tldr:
  q: How do I use prompt templates with {{site.ai_gateway}}?
  a: Configure the [AI Proxy](/plugins/ai-proxy/) plugin to route traffic, then use the [AI Prompt Template](/plugins/ai-prompt-template/) plugin to define and enforce reusable prompt formats.

products:
  - ai-gateway
  - gateway

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
  - mistral

tools:
  - deck

prereqs:
  inline:
    - title: Mistral
      include_content: prereqs/mistral
      icon_url: /assets/icons/mistral.svg
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

Start by configuring the AI Proxy plugin to route prompts to Mistral AI.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${key}
        model:
          provider: mistral
          name: mistral-tiny
          options:
            mistral_format: openai
            upstream_url: https://api.mistral.ai/v1/chat/completions

variables:
  key:
    value: $MISTRAL_API_KEY
    description: The API key to use to connect to Mistral.
{% endentity_examples %}


## Configure the AI Prompt Template plugin

Now, we can configure the AI Prompt Template plugin with predefined, reusable prompt templates for common tasks. This allows users to fill in the blanks with variable placeholders (`{{variable}}`).

The plugin will automatically [block all untemplated requests](/how-to/use-ai-prompt-template-plugin/#denied-prompts) via `allow_untemplated_requests: false` setting.

This configuration defines five prompt templates:

<!-- vale off -->
{% table %}
columns:
  - title: Template name
    key: name
  - title: Description
    key: description
rows:
  - name: summarizer
    description: Summarizes long text into concise bullet points.
  - name: code-explainer
    description: Explains source code in beginner-friendly terms.
  - name: email-drafter
    description: Drafts professional emails based on topic and recipient.
  - name: product-describer
    description: Generates marketing descriptions from product details and features.
  - name: qna
    description: Answers user questions clearly and factually.
{% endtable %}
<!-- vale on -->

Configure the AI Prompt Template plugin:

{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-template
      config:
        allow_untemplated_requests: false
        templates:
          - name: summarizer
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You summarize long texts into concise bullet points."
                    },
                    {
                      "role": "user",
                      "content": "Summarize the following text: {% raw %}{{text}}{% endraw %}"
                    }
                  ]
              }
          - name: code-explainer
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You are a helpful assistant who explains code to beginners."
                    },
                    {
                      "role": "user",
                      "content": "Explain what the following code does: {% raw %}{{code}}{% endraw %}"
                    }
                  ]
              }
          - name: email-drafter
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You write professional emails based on user input."
                    },
                    {
                      "role": "user",
                      "content": "Draft an email about {% raw %}{{topic}}{% endraw %} to {% raw %}{{recipient}}{% endraw %}."
                    }
                  ]
              }
          - name: product-describer
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You write engaging product descriptions."
                    },
                    {
                      "role": "user",
                      "content": "Describe the product: {% raw %}{{product_name}{% endraw %}, which has the following features: {% raw %}{{features}}{% endraw %}."
                    }
                  ]
              }
          - name: qna
            template: |-
              {
                  "messages": [
                    {
                      "role": "system",
                      "content": "You answer questions clearly and accurately."
                    },
                    {
                      "role": "user",
                      "content": "Answer the following question: {% raw %}{{question}}{% endraw %}"
                    }
                  ]
              }
{% endentity_examples %}


## Validate configuration

Now, you can validate that the AI Prompt Template plugin configuration is correct by sending allowed and denied prompts.
### Allowed prompts

{% navtabs "template-requests-it-tests" %}

{% navtab "Summarizer" %}
This request uses the `summarizer` template:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages: "{template://summarizer}"
  properties:
    text: "Of all human sciences the most useful and most imperfect appears to me to be that of mankind: and I will venture to say, the single inscription on the Temple of Delphi contained a precept more difficult and more important than is to be found in all the huge volumes that moralists have ever written. I consider the subject of the following discourse as one of the most interesting questions philosophy can propose, and unhappily for us, one of the most thorny that philosophers can have to solve. For how shall we know the source of inequality between men, if we do not begin by knowing mankind? And how shall man hope to see himself as nature made him, across all the changes which the succession of place and time must have produced in his original constitution? How can he distinguish what is fundamental in his nature from the changes and additions which his circumstances and the advances he has made have introduced to modify his primitive condition? Like the statue of Glaucus, which was so disfigured by time, seas and tempests, that it looked more like a wild beast than a god, the human soul, altered in society by a thousand causes perpetually recurring, by the acquisition of a multitude of truths and errors, by the changes happening to the constitution of the body, and by the continual jarring of the passions, has, so to speak, changed in appearance, so as to be hardly recognisable. Instead of a being, acting constantly from fixed and invariable principles, instead of that celestial and majestic simplicity, impressed on it by its divine Author, we find in it only the frightful contrast of passion mistaking itself for reason, and of understanding grown delirious."
status_code: 200
{% endvalidation %}
<!-- vale on -->

{% endnavtab %}

{% navtab "Code explainer" %}
This request uses the `code-explainer` template:.

<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages: "{template://code-explainer}"
  properties:
    code: "def add(a, b):\n    return a + b"
status_code: 200
{% endvalidation %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Email drafter" %}

This request uses the `email-drafter` template:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages: "{template://email-drafter}"
  properties:
    topic: "weekly team update"
    recipient: "the engineering team"
status_code: 200
{% endvalidation %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Product describer" %}

This request describes a product using the `product-describer` template:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages: "{template://product-describer}"
  properties:
    product_name: "SuperSonic Vacuum X5"
    features: "cordless design, HEPA filter, 60-minute battery life, lightweight build"
status_code: 200
{% endvalidation %}
<!-- vale on -->
{% endnavtab %}

{% navtab "Q&A" %}
This requests uses the `qna` template:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages: "{template://qna}"
  properties:
    question: "What is life?"
status_code: 200
{% endvalidation %}
<!-- vale on -->
{% endnavtab %}

{% endnavtabs %}

### Denied prompts

All requests that don't use any of the configured templates will be automatically blocked by the plugin. For example:

<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: What is Pythagorean theorem?
status_code: 400
message: this LLM route only supports templated requests
{% endvalidation %}
<!-- vale on -->