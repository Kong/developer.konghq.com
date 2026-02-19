---
title: Guide survey classification behavior using the AI Prompt Decorator plugin
permalink: /how-to/create-a-complex-ai-chat-history/
content_type: how_to
description: Use the AI Prompt Decorator plugin to enforce privacy-aware classification behavior when routing chat requests to Cohere via {{site.ai_gateway}}.
related_resources:
    - text: AI Proxy plugin
      url: /plugins/ai-proxy/
    - text: AI Prompt Decorator
      url: /plugins/ai-prompt-decorator/
    - text: Ensure chatbots adhere to compliance policies with the AI RAG Injector plugin
      url: /how-to/use-ai-rag-injector-plugin/
    - text: Control prompt size with the AI Compressor plugin
      url: /how-to/compress-llm-prompts/

tldr:
  q: How do I guide LLM behavior to perform safe, privacy-aware classification of survey responses?
  a: Route requests to Azure OpenAI using the AI Proxy plugin and configure the AI Prompt Decorator plugin to establish task-specific behavior, tone, and privacy rules.

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
  - ai-prompt-decorator

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - cohere

tools:
  - deck

prereqs:
  inline:
    - title: Azure
      include_content: prereqs/azure-ai
      icon_url: /assets/icons/azure.svg
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

Configure the [AI Proxy](/plugins/ai-proxy/) plugin to forward requests to OpenAI's gpt-4.1 model:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${azure_api_key}
        model:
          provider: azure
          name: gpt-4.1
          options:
            azure_api_version: 2024-12-01-preview
            azure_instance: ${azure_instance_name}
            azure_deployment_id: ${azure_deployment_id}
variables:
  azure_api_key:
    value: $AZURE_OPENAI_API_KEY
  azure_instance_name:
    value: $AZURE_INSTANCE_NAME
  azure_deployment_id:
    value: $AZURE_DEPLOYMENT_ID
{% endentity_examples %}


## Shape classification behavior with the Prompt Decorator plugin

Now we can configure the AI Prompt Decorator plugin. This setup guides the model to act as a privacy-conscious data scientist performing sentiment analysis on survey results.


{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-decorator
      config:
        prompts:
          prepend:
            - role: system
              content: |
                You are a senior data scientist tasked with analyzing anonymized survey responses
                for sentiment. Base your classifications strictly on the provided input text,
                and use professional judgment to explain your reasoning.
            - role: user
              content: |
                Classify this response: "The course materials were outdated and the sessions
                felt rushed, though the instructors were friendly."
            - role: assistant
              content: |
                Sentiment: NEGATIVE. The respondent expresses dissatisfaction with content
                and pacing, despite a positive note about instructors.
          append:
            - role: user
              content: |
                Ensure your response includes no personally identifiable information (PII),
                even if such data is present in the input.
{% endentity_examples %}


{:.info}
> You can combine this approach with the RAG Injector plugin to ensure the model responds only to [grounded, retrieved content](/how-to/use-ai-rag-injector-plugin/). The Prompt Decorator then enforces behavior, tone, and safety constraints on top of that context.

## Validate prompt behavior enforcement

Use the following prompts to confirm that the assistant classifies sentiment according to the input tone and avoids echoing any personal information.

- Test for positive sentiment classification:
{% capture positive %}
<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: |
        Classify this response: "My name is Robin Kowalski and I found the course well-organized, and the instructor was very clear and engaging."
status_code: 200
message: |
  Sentiment POSITIVE. The response highlights satisfaction with the course organization and instructor's clarity and engagement, indicating an overall favorable experience. **Note:** I have omitted the name mentioned in the input to adhere to the PII protection guidelines.
{% endvalidation %}
<!-- vale on -->
{% endcapture %}
{{ positive | indent: 2}}

- Test for neutral sentiment classification:

{% capture negative-mixed %}
<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: |
         Classify this response: "Some parts of the training were useful, others not so much. It was okay overall. The teacher, John Smith, did not seem particularly well equipped to conduct this course."
status_code: 200
message: |
  Sentiment NEGATIVE. Reasoning: "Some parts...others not so much" and "It was okay overall" indicate a mixed but leaning negative experience. "Did not seem particularly well equipped" is a clear criticism of the instructor's ability, contributing to the negative sentiment.
{% endvalidation %}
<!-- vale on -->
{% endcapture %}
{{ negative-mixed | indent: 2}}

- Test for negative sentiment classification:
{% capture sentiment %}
<!-- vale off -->
{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type: application/json'
body:
  messages:
    - role: user
      content: |
       Classify this response: "The platform used during the course was buggy, and I did not find the sessions helpful at all."
status_code: 200
message: |
    Sentiment NEGATIVE. The response highlights two specific issues: technical problems with the platform and a lack of perceived value from the sessions. Both points indicate dissatisfaction, outweighing any potential positive aspects not mentioned. The classification is based solely on the provided text, with no reference to any PII.
{% endvalidation %}
<!-- vale on -->
{% endcapture %}
{{ sentiment | indent: 2}}
